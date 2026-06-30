import 'package:flutter/services.dart';
import 'package:grabbit_core/grabbit_core.dart';

import 'clipboard_database.dart';

/// GRABBIT Persistent Clipboard Service.
///
/// Three input methods (user chooses what's installed):
///
/// 1. TASKER / MACRODROID (recommended for most users):
///    Automation app detects "Clipboard Changed" → sends Intent
///    → GRABBIT BroadcastReceiver catches it → persisted in DB.
///    Zero special permissions needed on GRABBIT side.
///    Setup: Event "Clipboard Changed" → Action "Send Intent"
///           → com.grabbit.CLIPBOARD_RECEIVED, Extra: clip=%CLIP
///
/// 2. SHIZUKU (fully autonomous, no external app):
///    Registers IClipboard.addPrimaryClipChangedListener at system level.
///    Survives backgrounding, screen off, Android 12+ restrictions.
///    Requires: Shizuku daemon running + authorization granted.
///
/// Both feed into the same pipeline:
/// content → dedup check → type detection → SQLite + FTS5 → persistent forever.
///
/// Output: Re-paste any entry. For >512KB content: Shizuku bypasses
/// Android's clipboard size limit. Without Shizuku: chunked paste.
class ClipboardService {
  ClipboardService._();
  static final ClipboardService instance = ClipboardService._();

  static const _methodChannel = MethodChannel('com.grabbit/clipboard');
  static const _eventChannel = EventChannel('com.grabbit/clipboard_events');

  final ClipboardDatabase _db = ClipboardDatabase.instance;

  bool _isListening = false;
  bool _shizukuAvailable = false;

  /// Initialize the clipboard service.
  /// Checks Shizuku availability and starts listening.
  Future<void> initialize() async {
    _shizukuAvailable = await _checkShizuku();
    if (_shizukuAvailable) {
      await _startShizukuListener();
    } else {
      _startFallbackListener();
    }
  }

  /// Check if Shizuku is available and authorized.
  Future<bool> _checkShizuku() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isShizukuAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Start privileged clipboard listener via Shizuku.
  /// This registers IClipboard.addPrimaryClipChangedListener at system level.
  Future<void> _startShizukuListener() async {
    try {
      await _methodChannel.invokeMethod('startClipboardListener');
      _isListening = true;

      // Listen for clipboard events from the Kotlin side
      _eventChannel.receiveBroadcastStream().listen((event) {
        if (event is Map) {
          _onClipboardChanged(event.cast<String, dynamic>());
        }
      });
    } catch (e) {
      // Shizuku failed — fall back
      _startFallbackListener();
    }
  }

  /// Fallback: monitor clipboard when app is in foreground.
  void _startFallbackListener() {
    _isListening = true;
    // Flutter's clipboard doesn't have a listener, but we can poll
    // or rely on the Android-side foreground service approach.
    // The platform channel will send events when available.
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        _onClipboardChanged(event.cast<String, dynamic>());
      }
    });
  }

  /// Handle a clipboard change event from the platform side.
  Future<void> _onClipboardChanged(Map<String, dynamic> event) async {
    final content = event['content'] as String?;
    if (content == null || content.isEmpty) return;

    // Skip duplicates (rapid re-copies)
    if (await _db.isDuplicate(content)) return;

    final type = ClipType.detect(content);
    final sourceApp = event['source_app'] as String?;
    final sourceLabel = event['source_label'] as String?;

    final entry = ClipboardEntry(
      id: 0, // auto-assigned by DB
      content: content,
      type: type,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sourceApp: sourceApp,
      sourceLabel: sourceLabel,
      sizeBytes: content.length * 2, // UTF-16 size approximation
      preview: content.length > 200 ? content.substring(0, 200) : content,
    );

    await _db.insert(entry);
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Manually capture current clipboard content (for foreground use).
  Future<ClipboardEntry?> captureCurrentClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return null;

    final content = data.text!;
    if (await _db.isDuplicate(content)) return null;

    final type = ClipType.detect(content);
    final entry = ClipboardEntry(
      id: 0,
      content: content,
      type: type,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sizeBytes: content.length * 2,
      preview: content.length > 200 ? content.substring(0, 200) : content,
    );

    final id = await _db.insert(entry);
    return ClipboardEntry(
      id: id,
      content: content,
      type: type,
      timestamp: entry.timestamp,
      sizeBytes: entry.sizeBytes,
      preview: entry.preview,
    );
  }

  /// Paste an entry back to the system clipboard.
  /// For entries >512KB: uses Shizuku to bypass Android's clipboard size limit.
  Future<PasteResult> pasteToClipboard(ClipboardEntry entry) async {
    if (entry.exceedsAndroidLimit && _shizukuAvailable) {
      // Use Shizuku to set clipboard without size restriction
      try {
        final result = await _methodChannel.invokeMethod<bool>(
          'setClipboardShizuku',
          {'content': entry.content},
        );
        if (result == true) return PasteResult.fullPaste;
        return PasteResult.failed;
      } catch (_) {
        return PasteResult.failed;
      }
    }

    if (entry.exceedsAndroidLimit) {
      // No Shizuku: paste first 512KB and warn user
      final truncated = entry.content.substring(
          0, (512 * 1024 ~/ 2).clamp(0, entry.content.length));
      await Clipboard.setData(ClipboardData(text: truncated));
      return PasteResult.truncatedPaste;
    }

    // Normal paste — within Android's limit
    await Clipboard.setData(ClipboardData(text: entry.content));
    return PasteResult.fullPaste;
  }

  /// Paste a specific range (start/end character positions) of an entry.
  Future<PasteResult> pasteRange(
      ClipboardEntry entry, int start, int end) async {
    final text = entry.content.substring(
      start.clamp(0, entry.content.length),
      end.clamp(0, entry.content.length),
    );
    if (text.length > 512 * 1024 ~/ 2 && _shizukuAvailable) {
      try {
        final result = await _methodChannel.invokeMethod<bool>(
          'setClipboardShizuku',
          {'content': text},
        );
        if (result == true) return PasteResult.fullPaste;
      } catch (_) {}
    }
    await Clipboard.setData(ClipboardData(text: text));
    return PasteResult.fullPaste;
  }

  /// Status info.
  bool get isListening => _isListening;
  bool get shizukuAvailable => _shizukuAvailable;
}

/// Result of a paste-to-clipboard operation.
enum PasteResult {
  /// Full content pasted successfully.
  fullPaste,

  /// Content was too large — truncated to Android's 512KB limit.
  truncatedPaste,

  /// Paste failed entirely.
  failed,
}
