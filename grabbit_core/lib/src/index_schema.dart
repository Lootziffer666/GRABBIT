/// SQL schema for the GRABBIT file index.
/// Used by the Flutter layer (sqflite/drift) to create and migrate the DB.
///
/// Design: "Everything"-principle — one DB, FTS5 for instant search,
/// incremental updates via ContentObserver/FileObserver.
abstract final class IndexSchema {
  static const String dbName = 'grabbit_index.db';
  static const int version = 1;

  /// Main files table.
  static const String createFiles = '''
    CREATE TABLE IF NOT EXISTS files (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      ext TEXT,
      size INTEGER NOT NULL DEFAULT 0,
      modified INTEGER NOT NULL,
      created INTEGER NOT NULL,
      parent TEXT NOT NULL,
      source TEXT,
      mime TEXT,
      thumbnail_key TEXT,
      content_indexed INTEGER NOT NULL DEFAULT 0,
      content_text TEXT
    )
  ''';

  /// Indexes for fast queries.
  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_files_modified ON files(modified DESC)',
    'CREATE INDEX IF NOT EXISTS idx_files_parent ON files(parent)',
    'CREATE INDEX IF NOT EXISTS idx_files_ext ON files(ext)',
    'CREATE INDEX IF NOT EXISTS idx_files_size ON files(size)',
    'CREATE INDEX IF NOT EXISTS idx_files_source ON files(source)',
    'CREATE INDEX IF NOT EXISTS idx_files_name ON files(name)',
  ];

  /// FTS5 virtual table for instant full-text search.
  static const String createFts = '''
    CREATE VIRTUAL TABLE IF NOT EXISTS files_fts USING fts5(
      name,
      path,
      content_text,
      content=files,
      content_rowid=id,
      tokenize='unicode61 remove_diacritics 2'
    )
  ''';

  /// Triggers to keep FTS in sync with files table.
  static const List<String> createFtsTriggers = [
    '''CREATE TRIGGER IF NOT EXISTS files_ai AFTER INSERT ON files BEGIN
      INSERT INTO files_fts(rowid, name, path, content_text)
      VALUES (new.id, new.name, new.path, new.content_text);
    END''',
    '''CREATE TRIGGER IF NOT EXISTS files_ad AFTER DELETE ON files BEGIN
      INSERT INTO files_fts(files_fts, rowid, name, path, content_text)
      VALUES ('delete', old.id, old.name, old.path, old.content_text);
    END''',
    '''CREATE TRIGGER IF NOT EXISTS files_au AFTER UPDATE ON files BEGIN
      INSERT INTO files_fts(files_fts, rowid, name, path, content_text)
      VALUES ('delete', old.id, old.name, old.path, old.content_text);
      INSERT INTO files_fts(rowid, name, path, content_text)
      VALUES (new.id, new.name, new.path, new.content_text);
    END''',
  ];

  /// Scan state table — tracks last full/incremental scan timestamps.
  static const String createScanState = '''
    CREATE TABLE IF NOT EXISTS scan_state (
      id INTEGER PRIMARY KEY DEFAULT 1,
      last_full_scan INTEGER,
      last_incremental INTEGER,
      total_files INTEGER DEFAULT 0
    )
  ''';

  /// Apps table — for the App Manager feature.
  static const String createApps = '''
    CREATE TABLE IF NOT EXISTS apps (
      package TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      installed INTEGER NOT NULL,
      last_used INTEGER,
      size_bytes INTEGER,
      is_system INTEGER NOT NULL DEFAULT 0,
      never_opened INTEGER NOT NULL DEFAULT 0
    )
  ''';

  /// All creation statements in order.
  static List<String> get allStatements => [
        createFiles,
        ...createIndexes,
        createFts,
        ...createFtsTriggers,
        createScanState,
        createApps,
      ];
}
