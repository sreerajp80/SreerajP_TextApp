import 'package:sqflite/sqflite.dart';

/// Opens and owns the app's local SQLite database.
///
/// Holds recents, bookmarks, favorites, and a drafts index. Rows are keyed by
/// the file content fingerprint where it makes sense (architecture.md §11).
///
/// A [version] and [onUpgrade] migration path are in place from v1 so later
/// schema changes never drop user data.
class AppDatabase {
  static const int version = 1;
  static const String defaultFileName = 'text_data.db';

  final Database db;

  AppDatabase._(this.db);

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
    return AppDatabase._(database);
  }

  static Future<void> _onConfigure(Database db) async {
    // Enforce foreign keys and keep integrity checks on.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createSchemaV1(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migrations run in order. v1 is the baseline; add `if (oldVersion < 2)`
    // blocks here as the schema grows, never dropping existing tables.
    // (No migrations yet — v1 is current.)
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

  Future<void> close() => db.close();
}
