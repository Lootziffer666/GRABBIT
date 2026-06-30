/// A clipboard entry persisted in GRABBIT's local database.
/// Never expires. Never gets truncated. Never disappears.
class ClipboardEntry {
  final int id;
  final String content;
  final ClipType type;
  final int timestamp; // epoch ms — when it was copied
  final String? sourceApp; // package name of the app that copied
  final String? sourceLabel; // human-readable label
  final int sizeBytes; // original size in bytes
  final bool pinned; // user pinned this entry (survives cleanup)
  final bool favorite; // user marked as frequently used
  final String? tags; // user-defined tags, comma-separated
  final String? preview; // first 200 chars for quick display

  const ClipboardEntry({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.sourceApp,
    this.sourceLabel,
    required this.sizeBytes,
    this.pinned = false,
    this.favorite = false,
    this.tags,
    this.preview,
  });

  /// Is this entry "large" (>100KB)?
  bool get isLarge => sizeBytes > 100 * 1024;

  /// Is this entry "huge" (>512KB — Android's normal clipboard limit)?
  bool get exceedsAndroidLimit => sizeBytes > 512 * 1024;

  /// Human-readable size.
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Time ago string.
  String get timeAgo {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    final minutes = diff ~/ 60000;
    if (minutes < 1) return 'gerade eben';
    if (minutes < 60) return 'vor $minutes min';
    final hours = minutes ~/ 60;
    if (hours < 24) return 'vor $hours Std';
    final days = hours ~/ 24;
    if (days == 1) return 'gestern';
    if (days < 7) return 'vor $days Tagen';
    return 'vor ${days ~/ 30} Monaten';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'type': type.name,
        'timestamp': timestamp,
        'source_app': sourceApp,
        'source_label': sourceLabel,
        'size_bytes': sizeBytes,
        'pinned': pinned ? 1 : 0,
        'favorite': favorite ? 1 : 0,
        'tags': tags,
        'preview': preview,
      };

  factory ClipboardEntry.fromMap(Map<String, dynamic> m) => ClipboardEntry(
        id: m['id'] as int,
        content: m['content'] as String,
        type: ClipType.values.firstWhere(
          (t) => t.name == (m['type'] as String),
          orElse: () => ClipType.text,
        ),
        timestamp: m['timestamp'] as int,
        sourceApp: m['source_app'] as String?,
        sourceLabel: m['source_label'] as String?,
        sizeBytes: m['size_bytes'] as int,
        pinned: (m['pinned'] as int?) == 1,
        favorite: (m['favorite'] as int?) == 1,
        tags: m['tags'] as String?,
        preview: m['preview'] as String?,
      );

  ClipboardEntry copyWith({
    bool? pinned,
    bool? favorite,
    String? tags,
  }) =>
      ClipboardEntry(
        id: id,
        content: content,
        type: type,
        timestamp: timestamp,
        sourceApp: sourceApp,
        sourceLabel: sourceLabel,
        sizeBytes: sizeBytes,
        pinned: pinned ?? this.pinned,
        favorite: favorite ?? this.favorite,
        tags: tags ?? this.tags,
        preview: preview,
      );
}

/// Clipboard content type.
enum ClipType {
  text, // plain text
  url, // detected URL
  code, // detected code (has syntax markers)
  json, // valid JSON
  path, // file path
  number, // phone number, ID, etc.
  email, // email address
  multiline, // large multi-line text (prompt, article, log)
  html; // HTML content

  String get label => switch (this) {
        text => 'Text',
        url => 'URL',
        code => 'Code',
        json => 'JSON',
        path => 'Pfad',
        number => 'Nummer',
        email => 'E-Mail',
        multiline => 'Mehrzeilig',
        html => 'HTML',
      };

  /// Auto-detect type from content.
  static ClipType detect(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return url;
    }
    if (trimmed.contains('@') &&
        trimmed.contains('.') &&
        !trimmed.contains(' ') &&
        trimmed.length < 100) {
      return email;
    }
    if (trimmed.startsWith('/') && !trimmed.contains('\n') && trimmed.length < 500) {
      return path;
    }
    if (trimmed.startsWith('{') && trimmed.endsWith('}') ||
        trimmed.startsWith('[') && trimmed.endsWith(']')) {
      return json;
    }
    if (RegExp(r'^[\d\s\-\+\(\)]{6,20}$').hasMatch(trimmed)) {
      return number;
    }
    if (trimmed.contains('import ') ||
        trimmed.contains('function ') ||
        trimmed.contains('class ') ||
        trimmed.contains('def ') ||
        trimmed.contains('fn ') ||
        trimmed.contains('=>') ||
        trimmed.contains('const ')) {
      return code;
    }
    if (trimmed.contains('<') && trimmed.contains('>') && trimmed.contains('</')) {
      return html;
    }
    if (trimmed.contains('\n') && trimmed.length > 200) {
      return multiline;
    }
    return text;
  }
}
