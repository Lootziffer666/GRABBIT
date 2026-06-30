import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:grabbit_core/grabbit_core.dart';

/// Persistent clipboard database — NEVER expires, NEVER truncates.
/// Stores every clipboard entry with full content, source, type, and metadata.
/// FTS5 for instant search across all clipboard history.
class ClipboardDatabase {
  ClipboardDatabase._();
  static final ClipboardDatabase instance = ClipboardDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'grabbit_clipboard.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS clipboard (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'text',
            timestamp INTEGER NOT NULL,
            source_app TEXT,
            source_label TEXT,
            size_bytes INTEGER NOT NULL,
            pinned INTEGER NOT NULL DEFAULT 0,
            favorite INTEGER NOT NULL DEFAULT 0,
            tags TEXT,
            preview TEXT
          )
        ''');

        // FTS5 for instant search across clipboard content
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS clipboard_fts USING fts5(
            content,
            preview,
            tags,
            content=clipboard,
            content_rowid=id,
            tokenize='unicode61 remove_diacritics 2'
          )
        ''');

        // Sync triggers
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS clip_ai AFTER INSERT ON clipboard BEGIN
            INSERT INTO clipboard_fts(rowid, content, preview, tags)
            VALUES (new.id, new.content, new.preview, new.tags);
          END
        ''');
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS clip_ad AFTER DELETE ON clipboard BEGIN
            INSERT INTO clipboard_fts(clipboard_fts, rowid, content, preview, tags)
            VALUES ('delete', old.id, old.content, old.preview, old.tags);
          END
        ''');
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS clip_au AFTER UPDATE ON clipboard BEGIN
            INSERT INTO clipboard_fts(clipboard_fts, rowid, content, preview, tags)
            VALUES ('delete', old.id, old.content, old.preview, old.tags);
            INSERT INTO clipboard_fts(rowid, content, preview, tags)
            VALUES (new.id, new.content, new.preview, new.tags);
          END
        ''');

        // Indexes
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_clip_ts ON clipboard(timestamp DESC)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_clip_pinned ON clipboard(pinned)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_clip_type ON clipboard(type)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_clip_source ON clipboard(source_app)');
      },
    );
  }

  // ── INSERT ──────────────────────────────────────────────────────────────

  /// Store a new clipboard entry. No size limit. No expiry.
  Future<int> insert(ClipboardEntry entry) async {
    final db = await database;
    final map = entry.toMap();
    map.remove('id'); // auto-increment
    return db.insert('clipboard', map);
  }

  /// Check if duplicate of last entry (avoid spam from repeated copies).
  Future<bool> isDuplicate(String content) async {
    final db = await database;
    final r = await db.query(
      'clipboard',
      where: 'content = ?',
      whereArgs: [content],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (r.isEmpty) return false;
    // Consider duplicate if same content within last 5 seconds
    final lastTs = r.first['timestamp'] as int;
    return DateTime.now().millisecondsSinceEpoch - lastTs < 5000;
  }

  // ── QUERY ───────────────────────────────────────────────────────────────

  /// Get recent clipboard entries (newest first).
  Future<List<ClipboardEntry>> getRecent({int limit = 50, int offset = 0}) async {
    final db = await database;
    final r = await db.query(
      'clipboard',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return r.map(ClipboardEntry.fromMap).toList();
  }

  /// Get pinned entries (always accessible).
  Future<List<ClipboardEntry>> getPinned() async {
    final db = await database;
    final r = await db.query(
      'clipboard',
      where: 'pinned = 1',
      orderBy: 'timestamp DESC',
    );
    return r.map(ClipboardEntry.fromMap).toList();
  }

  /// Get favorites.
  Future<List<ClipboardEntry>> getFavorites() async {
    final db = await database;
    final r = await db.query(
      'clipboard',
      where: 'favorite = 1',
      orderBy: 'timestamp DESC',
    );
    return r.map(ClipboardEntry.fromMap).toList();
  }

  /// Search clipboard history (FTS5 — instant).
  Future<List<ClipboardEntry>> search(String query, {int limit = 30}) async {
    final db = await database;
    final fts = '$query*'; // prefix match
    final r = await db.rawQuery('''
      SELECT c.* FROM clipboard c
      JOIN clipboard_fts ON clipboard_fts.rowid = c.id
      WHERE clipboard_fts MATCH ?
      ORDER BY c.timestamp DESC
      LIMIT ?
    ''', [fts, limit]);
    return r.map(ClipboardEntry.fromMap).toList();
  }

  /// Filter by type.
  Future<List<ClipboardEntry>> getByType(ClipType type, {int limit = 50}) async {
    final db = await database;
    final r = await db.query(
      'clipboard',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return r.map(ClipboardEntry.fromMap).toList();
  }

  /// Filter by source app.
  Future<List<ClipboardEntry>> getBySource(String packageName, {int limit = 50}) async {
    final db = await database;
    final r = await db.query(
      'clipboard',
      where: 'source_app = ?',
      whereArgs: [packageName],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return r.map(ClipboardEntry.fromMap).toList();
  }

  /// Get total entry count.
  Future<int> getCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM clipboard');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Get total stored size in bytes.
  Future<int> getTotalSize() async {
    final db = await database;
    final r = await db.rawQuery('SELECT SUM(size_bytes) as s FROM clipboard');
    return (r.first['s'] as int?) ?? 0;
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────

  /// Toggle pin status.
  Future<void> togglePin(int id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE clipboard SET pinned = CASE WHEN pinned = 1 THEN 0 ELSE 1 END WHERE id = ?',
        [id]);
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(int id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE clipboard SET favorite = CASE WHEN favorite = 1 THEN 0 ELSE 1 END WHERE id = ?',
        [id]);
  }

  /// Update tags for an entry.
  Future<void> updateTags(int id, String tags) async {
    final db = await database;
    await db.update('clipboard', {'tags': tags}, where: 'id = ?', whereArgs: [id]);
  }

  // ── DELETE ──────────────────────────────────────────────────────────────

  /// Delete a single entry.
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('clipboard', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all non-pinned entries older than [days] days.
  Future<int> cleanup({required int days}) async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return db.delete(
      'clipboard',
      where: 'pinned = 0 AND favorite = 0 AND timestamp < ?',
      whereArgs: [cutoff],
    );
  }

  /// Delete all entries (nuclear option).
  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('clipboard');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
