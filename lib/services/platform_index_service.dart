import 'package:flutter/services.dart';
import 'package:grabbit_core/grabbit_core.dart';

/// Bridge to the Kotlin Platform Channel for Android-specific file operations.
///
/// The Kotlin side handles:
/// - MediaStore queries (initial scan + incremental)
/// - ContentObserver registration (real-time file change events)
/// - SAF operations (move, delete on scoped storage)
/// - PackageManager queries (installed apps)
///
/// The Dart side handles:
/// - SQLite/FTS5 index management
/// - All UI logic
/// - Query execution against the index
class PlatformIndexService {
  PlatformIndexService._();
  static final instance = PlatformIndexService._();

  static const _methodChannel = MethodChannel('com.grabbit/index');
  static const _eventChannel = EventChannel('com.grabbit/file_events');

  /// Perform a full scan via MediaStore. Returns all file metadata.
  /// Called once on first launch, or when user requests a rebuild.
  Future<List<IndexedFile>> scanAll() async {
    final result = await _methodChannel.invokeListMethod<Map>('scanAll');
    if (result == null) return [];

    return result.map((map) {
      final m = map.cast<String, dynamic>();
      return IndexedFile(
        id: 0, // will be assigned by SQLite
        path: m['path'] as String,
        name: m['name'] as String,
        ext: m['ext'] as String?,
        size: (m['size'] as num).toInt(),
        modified: (m['modified'] as num).toInt(),
        created: (m['created'] as num).toInt(),
        parent: m['parent'] as String,
        source: m['source'] as String?,
        mime: m['mime'] as String?,
      );
    }).toList();
  }

  /// Incremental scan: get files modified since [sinceMs] (epoch milliseconds).
  Future<List<IndexedFile>> scanIncremental(int sinceMs) async {
    final result = await _methodChannel
        .invokeListMethod<Map>('scanIncremental', {'since': sinceMs});
    if (result == null) return [];

    return result.map((map) {
      final m = map.cast<String, dynamic>();
      return IndexedFile(
        id: 0,
        path: m['path'] as String,
        name: m['name'] as String,
        ext: m['ext'] as String?,
        size: (m['size'] as num).toInt(),
        modified: (m['modified'] as num).toInt(),
        created: (m['created'] as num).toInt(),
        parent: m['parent'] as String,
        source: m['source'] as String?,
        mime: m['mime'] as String?,
      );
    }).toList();
  }

  /// Get installed apps from PackageManager.
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    final result =
        await _methodChannel.invokeListMethod<Map>('getInstalledApps');
    if (result == null) return [];
    return result.map((m) => m.cast<String, dynamic>()).toList();
  }

  Future<bool> openApp(String packageName) async =>
      await _methodChannel.invokeMethod<bool>('openApp', {'package': packageName}) ?? false;

  Future<bool> openAppDetails(String packageName) async =>
      await _methodChannel.invokeMethod<bool>('openAppDetails', {'package': packageName}) ?? false;

  Future<bool> uninstallApp(String packageName) async =>
      await _methodChannel.invokeMethod<bool>('uninstallApp', {'package': packageName}) ?? false;

  /// Delete a file (SAF-aware).
  Future<bool> deleteFile(String path) async {
    final result =
        await _methodChannel.invokeMethod<bool>('deleteFile', {'path': path});
    return result ?? false;
  }

  /// Move a file (SAF-aware).
  Future<bool> moveFile(String from, String to) async {
    final result = await _methodChannel
        .invokeMethod<bool>('moveFile', {'from': from, 'to': to});
    return result ?? false;
  }

  /// Copy a file.
  Future<bool> copyFile(String from, String to) async {
    final result = await _methodChannel
        .invokeMethod<bool>('copyFile', {'from': from, 'to': to});
    return result ?? false;
  }

  /// Rename a file.
  Future<bool> renameFile(String path, String newName) async {
    final result = await _methodChannel
        .invokeMethod<bool>('renameFile', {'path': path, 'newName': newName});
    return result ?? false;
  }

  /// Stream of real-time file change events from ContentObserver.
  /// Each event is a map: {type: "added"|"modified"|"deleted", path: "..."}
  Stream<Map<String, dynamic>> get fileEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) return event.cast<String, dynamic>();
      return <String, dynamic>{};
    });
  }
}
