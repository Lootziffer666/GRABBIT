import 'indexed_file.dart';

/// Query descriptors for the GRABBIT index.
/// These are pure data — the actual SQL execution happens in the Flutter layer
/// via sqflite/drift. This keeps grabbit_core framework-free.

/// Sort order for file queries.
enum FileSortOrder { newestFirst, oldestFirst, largestFirst, smallestFirst, nameAsc, nameDesc }

/// A query against the file index.
class FileQuery {
  /// Free-text search (matches name AND content via FTS5).
  final String? search;

  /// Filter by parent directory (exact match for folder navigation).
  final String? parentPath;

  /// Filter by file category.
  final Set<FileCategory>? categories;

  /// Filter by extension(s).
  final Set<String>? extensions;

  /// Filter by source.
  final String? source;

  /// Minimum file size in bytes.
  final int? minSize;

  /// Maximum file size in bytes.
  final int? maxSize;

  /// Modified after this timestamp (epoch ms).
  final int? modifiedAfter;

  /// Modified before this timestamp (epoch ms).
  final int? modifiedBefore;

  /// Sort order (default: newest first — the GRABBIT principle).
  final FileSortOrder sortOrder;

  /// Maximum results to return.
  final int limit;

  /// Offset for pagination.
  final int offset;

  const FileQuery({
    this.search,
    this.parentPath,
    this.categories,
    this.extensions,
    this.source,
    this.minSize,
    this.maxSize,
    this.modifiedAfter,
    this.modifiedBefore,
    this.sortOrder = FileSortOrder.newestFirst,
    this.limit = 50,
    this.offset = 0,
  });

  /// Convenience: "Recent files" — newest 50.
  const FileQuery.recent({int count = 50})
      : search = null,
        parentPath = null,
        categories = null,
        extensions = null,
        source = null,
        minSize = null,
        maxSize = null,
        modifiedAfter = null,
        modifiedBefore = null,
        sortOrder = FileSortOrder.newestFirst,
        limit = count,
        offset = 0;

  /// Convenience: "Today's files".
  factory FileQuery.today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return FileQuery(modifiedAfter: startOfDay);
  }

  /// Convenience: "Large files" (>100 MB).
  const FileQuery.largeFiles({int threshold = 100 * 1024 * 1024})
      : search = null,
        parentPath = null,
        categories = null,
        extensions = null,
        source = null,
        minSize = threshold,
        maxSize = null,
        modifiedAfter = null,
        modifiedBefore = null,
        sortOrder = FileSortOrder.largestFirst,
        limit = 50,
        offset = 0;

  /// Convenience: folder navigation.
  factory FileQuery.folder(String path) => FileQuery(parentPath: path);
}
