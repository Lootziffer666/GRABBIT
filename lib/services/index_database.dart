import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:grabbit_core/grabbit_core.dart';

/// The GRABBIT index database — Everything-principle.
/// Build once, update incrementally, search instantly.
///
/// Uses SQLite + FTS5 for full-text search over filenames AND content.
/// All queries return in <5ms regardless of file count.
class IndexDatabase {
  IndexDatabase._();
  static final IndexDatabase instance = IndexDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, IndexSchema.dbName);

    return openDatabase(
      dbPath,
      version: IndexSchema.version,
      onCreate: (db, version) async {
        for (final stmt in IndexSchema.allStatements) {
          await db.execute(stmt);
        }
        // Initialize scan state row
        await db.insert('scan_state', {'id': 1, 'total_files': 0});
      },
    );
  }

  // ── INSERT / UPDATE ─────────────────────────────────────────────────────

  /// Upsert a single file into the index.
  Future<int> upsertFile(IndexedFile file) async {
    final db = await database;
    final map = file.toMap();
    map.remove('id'); // let SQLite auto-increment on insert

    return db.insert(
      'files',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Bulk insert files (for initial scan). Uses batch for performance.
  Future<void> bulkInsert(List<IndexedFile> files) async {
    final db = await database;
    final batch = db.batch();
    for (final file in files) {
      final map = file.toMap();
      map.remove('id');
      batch.insert('files', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Update content text for a file (after OCR / PDF extraction).
  Future<void> updateContentText(int fileId, String text) async {
    final db = await database;
    await db.update(
      'files',
      {'content_text': text, 'content_indexed': 1},
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  /// Remove a file from the index by path.
  Future<void> removeByPath(String path) async {
    final db = await database;
    await db.delete('files', where: 'path = ?', whereArgs: [path]);
  }

  /// Remove files no longer on disk (delta cleanup).
  Future<void> removeByPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final path in paths) {
      batch.delete('files', where: 'path = ?', whereArgs: [path]);
    }
    await batch.commit(noResult: true);
  }

  // ── QUERIES ─────────────────────────────────────────────────────────────

  /// Execute a FileQuery and return matching files.
  Future<List<IndexedFile>> query(FileQuery q) async {
    final db = await database;

    // FTS5 search path (full-text over name + path + content_text)
    if (q.search != null && q.search!.isNotEmpty) {
      return _ftsQuery(db, q);
    }

    // Standard SQL query path
    return _sqlQuery(db, q);
  }

  Future<List<IndexedFile>> _ftsQuery(Database db, FileQuery q) async {
    // FTS5 match query — searches name, path, and content_text
    final ftsQuery = '${q.search!}*'; // prefix matching for instant-as-you-type

    String sql = '''
      SELECT f.* FROM files f
      JOIN files_fts ON files_fts.rowid = f.id
      WHERE files_fts MATCH ?
    ''';
    final args = <dynamic>[ftsQuery];

    // Additional filters
    if (q.categories != null && q.categories!.isNotEmpty) {
      final exts = _extensionsForCategories(q.categories!);
      sql += ' AND f.ext IN (${exts.map((_) => '?').join(',')})';
      args.addAll(exts);
    }
    if (q.source != null) {
      sql += ' AND f.source = ?';
      args.add(q.source);
    }
    if (q.minSize != null) {
      sql += ' AND f.size >= ?';
      args.add(q.minSize);
    }
    if (q.maxSize != null) {
      sql += ' AND f.size <= ?';
      args.add(q.maxSize);
    }
    if (q.modifiedAfter != null) {
      sql += ' AND f.modified >= ?';
      args.add(q.modifiedAfter);
    }
    if (q.modifiedBefore != null) {
      sql += ' AND f.modified <= ?';
      args.add(q.modifiedBefore);
    }

    // Sort + limit
    sql += ' ORDER BY ${_orderClause(q.sortOrder)}';
    sql += ' LIMIT ? OFFSET ?';
    args.addAll([q.limit, q.offset]);

    final results = await db.rawQuery(sql, args);
    return results.map(IndexedFile.fromMap).toList();
  }

  Future<List<IndexedFile>> _sqlQuery(Database db, FileQuery q) async {
    final where = <String>[];
    final args = <dynamic>[];

    if (q.parentPath != null) {
      where.add('parent = ?');
      args.add(q.parentPath);
    }
    if (q.categories != null && q.categories!.isNotEmpty) {
      final exts = _extensionsForCategories(q.categories!);
      where.add('ext IN (${exts.map((_) => '?').join(',')})');
      args.addAll(exts);
    }
    if (q.extensions != null && q.extensions!.isNotEmpty) {
      where.add('ext IN (${q.extensions!.map((_) => '?').join(',')})');
      args.addAll(q.extensions!);
    }
    if (q.source != null) {
      where.add('source = ?');
      args.add(q.source);
    }
    if (q.minSize != null) {
      where.add('size >= ?');
      args.add(q.minSize);
    }
    if (q.maxSize != null) {
      where.add('size <= ?');
      args.add(q.maxSize);
    }
    if (q.modifiedAfter != null) {
      where.add('modified >= ?');
      args.add(q.modifiedAfter);
    }
    if (q.modifiedBefore != null) {
      where.add('modified <= ?');
      args.add(q.modifiedBefore);
    }

    final results = await db.query(
      'files',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: _orderClause(q.sortOrder),
      limit: q.limit,
      offset: q.offset,
    );

    return results.map(IndexedFile.fromMap).toList();
  }

  // ── SCAN STATE ──────────────────────────────────────────────────────────

  /// Get the timestamp of last full scan (null = never scanned).
  Future<int?> getLastFullScan() async {
    final db = await database;
    final r = await db.query('scan_state', where: 'id = 1');
    if (r.isEmpty) return null;
    return r.first['last_full_scan'] as int?;
  }

  /// Get the timestamp of last incremental update.
  Future<int?> getLastIncremental() async {
    final db = await database;
    final r = await db.query('scan_state', where: 'id = 1');
    if (r.isEmpty) return null;
    return r.first['last_incremental'] as int?;
  }

  /// Update scan state after a full or incremental scan.
  Future<void> updateScanState({int? fullScan, int? incremental, int? totalFiles}) async {
    final db = await database;
    final values = <String, dynamic>{};
    if (fullScan != null) values['last_full_scan'] = fullScan;
    if (incremental != null) values['last_incremental'] = incremental;
    if (totalFiles != null) values['total_files'] = totalFiles;
    if (values.isNotEmpty) {
      await db.update('scan_state', values, where: 'id = 1');
    }
  }

  /// Get total indexed file count.
  Future<int> getTotalFileCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM files');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ── APPS TABLE ──────────────────────────────────────────────────────────

  /// Upsert an installed app into the index.
  Future<void> upsertApp(Map<String, dynamic> app) async {
    final db = await database;
    await db.insert('apps', app, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all indexed apps, sorted by install date descending.
  Future<List<Map<String, dynamic>>> getAllApps({String? orderBy}) async {
    final db = await database;
    return db.query('apps', orderBy: orderBy ?? 'installed DESC');
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────

  String _orderClause(FileSortOrder order) => switch (order) {
        FileSortOrder.newestFirst => 'modified DESC',
        FileSortOrder.oldestFirst => 'modified ASC',
        FileSortOrder.largestFirst => 'size DESC',
        FileSortOrder.smallestFirst => 'size ASC',
        FileSortOrder.nameAsc => 'name ASC',
        FileSortOrder.nameDesc => 'name DESC',
      };

  /// Map FileCategory set to extension list for SQL IN clause.
  List<String> _extensionsForCategories(Set<FileCategory> cats) {
    final exts = <String>[];
    for (final cat in cats) {
      exts.addAll(switch (cat) {
        FileCategory.image => ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'heic', 'heif'],
        FileCategory.video => ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', '3gp'],
        FileCategory.audio => ['mp3', 'flac', 'wav', 'ogg', 'aac', 'm4a', 'opus'],
        FileCategory.document => ['pdf', 'doc', 'docx', 'txt', 'md', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'],
        FileCategory.archive => ['zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'zst'],
        FileCategory.code => ['dart', 'kt', 'java', 'py', 'js', 'ts', 'json', 'xml', 'yaml', 'yml', 'html', 'css', 'sh'],
        FileCategory.app => ['apk', 'xapk'],
        FileCategory.other => [],
      });
    }
    return exts;
  }

  /// Close the database.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
