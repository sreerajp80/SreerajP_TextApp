import 'package:sqflite/sqflite.dart';

/// Opens and owns the app's local SQLite database.
///
/// Holds recents, bookmarks, favorites, and a drafts index. Rows are keyed by
/// the file content fingerprint where it makes sense (architecture.md §11).
///
/// A [version] and [onUpgrade] migration path are in place from v1 so later
/// schema changes never drop user data.
class AppDatabase {
  static const int version = 3;
  static const String defaultFileName = 'text_data.db';

  final Database db;

  /// Whether this database's SQLite build has the FTS5 extension.
  ///
  /// Android 8.0+ normally ships it, but a device build may not. When it is
  /// missing the workspace search index falls back to a plain body table
  /// searched with `LIKE`, so the feature still works (just slower).
  final bool ftsAvailable;

  AppDatabase._(this.db, this.ftsAvailable);

  /// Opens (or creates) the database.
  ///
  /// Pass [path] `inMemoryDatabasePath` in tests. In the app, pass a file path
  /// under the app's private directory. A custom [factory] lets tests inject the
  /// FFI factory so the DB runs on the host with no device.
  static Future<AppDatabase> open({
    required String path,
    DatabaseFactory? factory,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final database = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(database, await _probeFts5(database));
  }

  /// Asks SQLite whether it can build an FTS5 table. The probe table is dropped
  /// straight away, so it leaves nothing behind.
  static Future<bool> _probeFts5(Database db) async {
    try {
      await db.execute(
        'CREATE VIRTUAL TABLE IF NOT EXISTS fts5_probe USING fts5(x)',
      );
      await db.execute('DROP TABLE IF EXISTS fts5_probe');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _onConfigure(Database db) async {
    // Enforce foreign keys and keep integrity checks on.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createSchemaV1(db);
    await createSearchIndexSchema(db);
    await createAuditLogSchema(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migrations run in order and are additive only — no existing table is ever
    // dropped, so user data survives every upgrade.
    if (oldVersion < 2) {
      await createSearchIndexSchema(db);
    }
    if (oldVersion < 3) {
      await createAuditLogSchema(db);
    }
  }

  static Future<void> _createSchemaV1(Database db) async {
    await db.execute('''
      CREATE TABLE recents (
        fingerprint     TEXT PRIMARY KEY,
        uri             TEXT NOT NULL,
        display_name    TEXT NOT NULL,
        mime_type       TEXT,
        size            INTEGER,
        last_opened_at  INTEGER NOT NULL,
        scroll_position INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_recents_last_opened ON recents(last_opened_at DESC)',
    );

    await db.execute('''
      CREATE TABLE bookmarks (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        fingerprint TEXT NOT NULL,
        label       TEXT NOT NULL,
        position    INTEGER NOT NULL,
        created_at  INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_bookmarks_fingerprint ON bookmarks(fingerprint)',
    );

    await db.execute('''
      CREATE TABLE favorites (
        fingerprint  TEXT PRIMARY KEY,
        uri          TEXT NOT NULL,
        display_name TEXT NOT NULL,
        added_at     INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE drafts_index (
        fingerprint TEXT PRIMARY KEY,
        draft_path  TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');
  }

  /// Creates the workspace search index tables (schema v2, Feature 11).
  ///
  /// `search_docs` holds one metadata row per indexed file. The document body
  /// lives in `search_fts`, an FTS5 table whose `rowid` is the `search_docs.id`,
  /// so a hit maps straight back to its file. A delete trigger keeps the two in
  /// step: dropping a file from the index always drops its body.
  ///
  /// If the SQLite build has no FTS5, a plain `search_body` table takes its
  /// place and the repository searches it with `LIKE` instead.
  static Future<void> createSearchIndexSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_docs (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        fingerprint  TEXT NOT NULL UNIQUE,
        uri          TEXT NOT NULL,
        display_name TEXT NOT NULL,
        format       TEXT NOT NULL,
        size         INTEGER,
        indexed_at   INTEGER NOT NULL,
        truncated    INTEGER NOT NULL DEFAULT 0,
        pinned       INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_search_docs_uri '
      'ON search_docs(uri)',
    );

    if (await _probeFts5(db)) {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS search_fts USING fts5(
          body,
          tokenize='unicode61 remove_diacritics 2'
        )
      ''');
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS search_docs_after_delete
        AFTER DELETE ON search_docs BEGIN
          DELETE FROM search_fts WHERE rowid = old.id;
        END
      ''');
    } else {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS search_body (
          doc_id INTEGER PRIMARY KEY,
          body   TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS search_docs_after_delete
        AFTER DELETE ON search_docs BEGIN
          DELETE FROM search_body WHERE doc_id = old.id;
        END
      ''');
    }
  }

  /// Creates the audit log table (schema v3, Feature 8).
  ///
  /// Each row carries a SHA-256 hash chained from its predecessor, so
  /// tampering with any entry is detectable by recomputing the chain.
  static Future<void> createAuditLogSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type       TEXT    NOT NULL,
        timestamp        INTEGER NOT NULL,
        file_name        TEXT,
        file_fingerprint TEXT,
        before_hash      TEXT,
        after_hash       TEXT,
        detail           TEXT,
        entry_hash       TEXT    NOT NULL,
        previous_hash    TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp '
      'ON audit_log(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_log_fingerprint '
      'ON audit_log(file_fingerprint)',
    );
  }

  Future<void> close() => db.close();
}
