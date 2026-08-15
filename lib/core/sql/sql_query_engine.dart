import 'package:sqflite/sqflite.dart';

import 'package:text_data/core/sql/sql_dataset.dart';
import 'package:text_data/core/sql/sql_guard.dart';
import 'package:text_data/core/sql/sql_result.dart';

/// Runs read-only SQL over open documents (Feature 4).
///
/// The open CSV table or JSON array is copied into a **throwaway in-memory
/// SQLite database**, which lives only as long as the query screen and is closed
/// on dispose. The app's own `text_data.db` is never touched, and no file is
/// written.
///
/// This uses the `sqflite` package the app already depends on — on Android
/// `inMemoryDatabasePath` gives a real SQLite engine, so the feature adds **no
/// new package** (CLAUDE.md §11). The roadmap's suggested `sqflite_common_ffi`
/// is a desktop/test-host factory; tests pass it in through [factory], which is
/// how this class is exercised on the host with no device.
///
/// Every statement goes through [SqlGuard] first. Nothing here logs the query
/// text or any row (CLAUDE.md §8).
class SqlQueryEngine {
  /// How many result rows are read back at most. The grid stays responsive and
  /// a runaway `JOIN` cannot fill memory; the result reports when it bites.
  static const int maxResultRows = 5000;

  final DatabaseFactory _factory;

  Database? _db;
  List<SqlDataset> _datasets = const [];

  /// Pass [factory] to run on a host (tests use `databaseFactoryFfi`). The app
  /// leaves it null and gets the Android engine.
  SqlQueryEngine({DatabaseFactory? factory})
    : _factory = factory ?? databaseFactory;

  /// The tables currently loaded, in the order they were given.
  List<SqlDataset> get datasets => List.unmodifiable(_datasets);

  bool get isLoaded => _db != null;

  /// Copies [datasets] into a fresh in-memory database, replacing anything
  /// loaded before.
  ///
  /// Two datasets that sanitise to the same table name are separated with a
  /// numeric suffix, so adding a second `sales.csv` never silently replaces the
  /// first.
  Future<void> load(List<SqlDataset> datasets) async {
    await close();

    // `singleInstance: false` matters: without it a second open of
    // `:memory:` would hand back the database this screen just closed.
    final db = await _factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );

    final named = _withUniqueTableNames(datasets);
    try {
      for (final dataset in named) {
        await db.execute(dataset.createTableSql());
        if (dataset.rowCount == 0) continue;
        await db.transaction((txn) async {
          final batch = txn.batch();
          final insert = dataset.insertSql();
          for (var r = 0; r < dataset.rowCount; r++) {
            batch.rawInsert(insert, dataset.valuesOf(r));
          }
          await batch.commit(noResult: true);
        });
      }
    } catch (e) {
      await db.close();
      throw SqlQueryException(_clean(e));
    }

    _db = db;
    _datasets = named;
  }

  /// Runs [sql] and returns its rows.
  ///
  /// Throws [SqlQueryException] when the guard refuses the statement, when
  /// nothing is loaded, or when SQLite rejects the query — never a raw database
  /// error, and never a crash (CLAUDE.md §3.4).
  Future<SqlQueryResult> run(String sql, {int? maxRows}) async {
    final db = _db;
    if (db == null) {
      throw const SqlQueryException('No data is loaded.');
    }
    final guard = SqlGuard.check(sql);
    if (!guard.ok) {
      // The screen turns a guard failure into a localized message; this text is
      // only a fallback for a non-UI caller.
      throw SqlQueryException('This query is not allowed: ${guard.failure}');
    }

    final limit = maxRows ?? maxResultRows;
    final watch = Stopwatch()..start();
    List<Map<String, Object?>> raw;
    try {
      // Wrapping caps the rows SQLite hands back even when the user wrote no
      // LIMIT. One extra row is asked for, purely to detect truncation.
      raw = await db.rawQuery(
        'SELECT * FROM (${guard.statement}) LIMIT ${limit + 1}',
      );
    } catch (e) {
      throw SqlQueryException(_clean(e));
    }
    watch.stop();

    final truncated = raw.length > limit;
    if (truncated) raw = raw.sublist(0, limit);

    final columns = raw.isEmpty ? <String>[] : raw.first.keys.toList();
    final rows = <List<String>>[
      for (final row in raw)
        [for (final column in columns) SqlQueryResult.display(row[column])],
    ];

    return SqlQueryResult(
      columns: columns,
      rows: rows,
      truncated: truncated,
      elapsedMs: watch.elapsedMilliseconds,
    );
  }

  /// Closes the in-memory database. Safe to call more than once.
  Future<void> close() async {
    final db = _db;
    _db = null;
    _datasets = const [];
    if (db != null) {
      try {
        await db.close();
      } catch (_) {
        // A database that is already gone is not an error worth surfacing.
      }
    }
  }

  static List<SqlDataset> _withUniqueTableNames(List<SqlDataset> datasets) {
    final used = <String>{};
    final out = <SqlDataset>[];
    for (final dataset in datasets) {
      var name = dataset.tableName;
      var suffix = 2;
      while (!used.add(name)) {
        name = '${dataset.tableName}_$suffix';
        suffix++;
      }
      out.add(
        name == dataset.tableName
            ? dataset
            : SqlDataset(
                tableName: name,
                sourceLabel: dataset.sourceLabel,
                columns: dataset.columns,
                rows: dataset.rows,
                sourceRowCount: dataset.sourceRowCount,
              ),
      );
    }
    return out;
  }

  /// SQLite's message, with sqflite's wrapper noise removed so the user reads
  /// "no such column: totl" rather than a stack of framework text.
  static String _clean(Object error) {
    var text = error is DatabaseException ? error.toString() : error.toString();
    text = text.replaceFirst(RegExp(r'^DatabaseException\(\s*'), '');
    text = text.replaceFirst(RegExp(r'\)\s*$'), '');
    final sqlAt = text.indexOf(' (Sqlite code');
    if (sqlAt > 0) text = text.substring(0, sqlAt);
    return text.trim().isEmpty ? 'The query could not run.' : text.trim();
  }
}
