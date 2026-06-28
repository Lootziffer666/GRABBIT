/// A file as stored in the GRABBIT index.
/// This is the universal record — every file on the device becomes one of these.
class IndexedFile {
  final int id;
  final String path;
  final String name;
  final String? ext;
  final int size; // bytes
  final int modified; // epoch ms
  final int created; // epoch ms
  final String parent; // parent directory path
  final String? source; // browser, camera, screenshot, whatsapp, chatgpt...
  final String? mime;
  final String? thumbnailKey;
  final int contentIndexed; // 0=no, 1=text extracted, 2=ocr
  final String? contentText; // extracted full text (for FTS)

  const IndexedFile({
    required this.id,
    required this.path,
    required this.name,
    this.ext,
    required this.size,
    required this.modified,
    required this.created,
    required this.parent,
    this.source,
    this.mime,
    this.thumbnailKey,
    this.contentIndexed = 0,
    this.contentText,
  });

  /// File extension derived from name if not explicitly set.
  String get extension => ext ?? (name.contains('.') ? name.split('.').last.toLowerCase() : '');

  /// Coarse file category for grouping/coloring.
  FileCategory get category {
    final e = extension;
    if (_imageExts.contains(e)) return FileCategory.image;
    if (_videoExts.contains(e)) return FileCategory.video;
    if (_audioExts.contains(e)) return FileCategory.audio;
    if (_documentExts.contains(e)) return FileCategory.document;
    if (_archiveExts.contains(e)) return FileCategory.archive;
    if (_codeExts.contains(e)) return FileCategory.code;
    if (e == 'apk' || e == 'xapk') return FileCategory.app;
    return FileCategory.other;
  }

  /// Human-readable size.
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'path': path,
        'name': name,
        'ext': ext,
        'size': size,
        'modified': modified,
        'created': created,
        'parent': parent,
        'source': source,
        'mime': mime,
        'thumbnail_key': thumbnailKey,
        'content_indexed': contentIndexed,
        'content_text': contentText,
      };

  factory IndexedFile.fromMap(Map<String, dynamic> m) => IndexedFile(
        id: m['id'] as int,
        path: m['path'] as String,
        name: m['name'] as String,
        ext: m['ext'] as String?,
        size: m['size'] as int,
        modified: m['modified'] as int,
        created: m['created'] as int,
        parent: m['parent'] as String,
        source: m['source'] as String?,
        mime: m['mime'] as String?,
        thumbnailKey: m['thumbnail_key'] as String?,
        contentIndexed: (m['content_indexed'] as int?) ?? 0,
        contentText: m['content_text'] as String?,
      );
}

enum FileCategory { image, video, audio, document, archive, code, app, other }

const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'heic', 'heif'};
const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', '3gp'};
const _audioExts = {'mp3', 'flac', 'wav', 'ogg', 'aac', 'm4a', 'opus'};
const _documentExts = {'pdf', 'doc', 'docx', 'txt', 'md', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'};
const _archiveExts = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'zst'};
const _codeExts = {'dart', 'kt', 'java', 'py', 'js', 'ts', 'json', 'xml', 'yaml', 'yml', 'html', 'css', 'sh'};
