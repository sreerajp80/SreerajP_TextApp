import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:text_data/core/sql/sql_dataset.dart';
import 'package:text_data/core/sql/sql_presets.dart';
import 'package:text_data/core/sql/sql_query_engine.dart';
import 'package:text_data/core/sql/sql_result.dart';

/// Feature 4 — the in-memory SQL engine, driven on the host through the FFI
/// factory (no device needed), the same way the search index is tested.
void main() {
  setUpAll(() => sqfliteFfiInit());

  SqlDataset sales() => SqlDataset.fromRows(
    tableName: 'data',
    sourceLabel: 'sales.csv',
    columnNames: ['region', 'amount', 'active'],
    rows: [
      ['South', '100', 'true'],
      ['North', '250.5', 'false'],
      ['South', '50', 'true'],
      ['East', '', 'true'],
    ],
  );

  SqlDataset regions() => SqlDataset.fromRows(
    tableName: 'regions',
    sourceLabel: 'regions.json',
    columnNames: ['region', 'manager'],
    rows: [
      ['South', 'Ann'],
      ['North', 'Bob'],
    ],
  );

  late SqlQueryEngine engine;

  setUp(() async {
    engine = SqlQueryEngine(factory: databaseFactoryFfi);
  });

  tearDown(() async => engine.close());

  test('a loaded table can be selected from', () async {
    await engine.load([sales()]);
    final result = await engine.run('SELECT region FROM data');
    expect(result.columns, ['region']);
    expect(result.rowCount, 4);
    expect(result.rows.first, ['South']);
  });

  test('a numeric column compares as a number, not as text', () async {
    await engine.load([sales()]);
    // As text, '50' would sort after '250.5'; as a number it does not.
    final result = await engine.run(
      'SELECT region FROM data WHERE amount > 60',
    );
    expect(result.rowCount, 2);
  });

  test('a blank cell is NULL, so AVG ignores it', () async {
    await engine.load([sales()]);
    final result = await engine.run(
      'SELECT COUNT(amount) AS filled, COUNT(*) AS total FROM data',
    );
    expect(result.rows.single, ['3', '4']);
  });

  test('GROUP BY with an aggregate works', () async {
    await engine.load([sales()]);
    final result = await engine.run(
      'SELECT region, SUM(amount) AS total FROM data '
      'GROUP BY region ORDER BY total DESC',
    );
    expect(result.columns, ['region', 'total']);
    expect(result.rows.first, ['North', '250.5']);
    expect(result.rows[1], ['South', '150']);
  });

  test('two documents can be joined', () async {
    await engine.load([sales(), regions()]);
    final result = await engine.run(
      'SELECT r.manager, SUM(d.amount) AS total '
      'FROM data AS d JOIN regions AS r ON d.region = r.region '
      'GROUP BY r.manager ORDER BY r.manager',
    );
    expect(result.rows, [
      ['Ann', '150'],
      ['Bob', '250.5'],
    ]);
  });

  test('two files with the same name get separate tables', () async {
    await engine.load([sales(), sales()]);
    expect(engine.datasets.map((d) => d.tableName), ['data', 'data_2']);
  });

  test('a boolean column loads as 1 and 0', () async {
    await engine.load([sales()]);
    final result = await engine.run(
      'SELECT COUNT(*) AS n FROM data WHERE active = 1',
    );
    expect(result.rows.single.single, '3');
  });

  test('a result longer than the cap is truncated and says so', () async {
    final many = SqlDataset.fromRows(
      tableName: 'data',
      sourceLabel: 'many.csv',
      columnNames: ['n'],
      rows: [
        for (var i = 0; i < 50; i++) ['$i'],
      ],
    );
    await engine.load([many]);
    final result = await engine.run('SELECT * FROM data', maxRows: 10);
    expect(result.rowCount, 10);
    expect(result.truncated, isTrue);
  });

  test('a header with a quote in it survives the round trip', () async {
    final odd = SqlDataset.fromRows(
      tableName: 'data',
      sourceLabel: 'odd.csv',
      columnNames: ['he said "hi"', 'order'],
      rows: [
        ['x', '1'],
      ],
    );
    await engine.load([odd]);
    final result = await engine.run('SELECT "order" FROM data');
    expect(result.rows.single.single, '1');
  });

  group('failure paths never crash', () {
    test('an unknown column gives a friendly message', () async {
      await engine.load([sales()]);
      expect(
        () => engine.run('SELECT totl FROM data'),
        throwsA(
          isA<SqlQueryException>().having(
            (e) => e.message,
            'message',
            contains('totl'),
          ),
        ),
      );
    });

    test('broken SQL gives a message, not a crash', () async {
      await engine.load([sales()]);
      expect(
        () => engine.run('SELECT FROM WHERE'),
        throwsA(isA<SqlQueryException>()),
      );
    });

    test('a blocked statement never reaches SQLite', () async {
      await engine.load([sales()]);
      expect(
        () => engine.run('DROP TABLE data'),
        throwsA(isA<SqlQueryException>()),
      );
      // The table is still there.
      final result = await engine.run('SELECT COUNT(*) AS n FROM data');
      expect(result.rows.single.single, '4');
    });

    test('running before loading is refused', () async {
      expect(() => engine.run('SELECT 1'), throwsA(isA<SqlQueryException>()));
    });

    test('closing twice is safe', () async {
      await engine.load([sales()]);
      await engine.close();
      await engine.close();
      expect(engine.isLoaded, isFalse);
    });

    test('a fresh load does not see the previous tables', () async {
      await engine.load([sales()]);
      await engine.load([regions()]);
      expect(
        () => engine.run('SELECT * FROM data'),
        throwsA(isA<SqlQueryException>()),
      );
      final result = await engine.run('SELECT COUNT(*) AS n FROM regions');
      expect(result.rows.single.single, '2');
    });
  });

  group('starter queries', () {
    test('they are written with the real table and column names', () {
      final presets = buildSqlPresets([sales()]);
      expect(presets, isNotEmpty);
      expect(presets.first.sql, contains('FROM data'));
      expect(presets.any((p) => p.kind == SqlPresetKind.groupCount), isTrue);
      expect(presets.any((p) => p.kind == SqlPresetKind.join), isFalse);
    });

    test('a join preset appears only with a second table', () {
      final presets = buildSqlPresets([sales(), regions()]);
      final join = presets.where((p) => p.kind == SqlPresetKind.join).single;
      expect(join.sql, contains('JOIN regions'));
      // The shared `region` column is picked as the key.
      expect(join.sql, contains('a.region = b.region'));
    });

    test('every starter query passes the guard and runs', () async {
      await engine.load([sales(), regions()]);
      for (final preset in buildSqlPresets(engine.datasets)) {
        final result = await engine.run(preset.sql);
        expect(result.columns, isNotEmpty, reason: preset.sql);
      }
    });
  });

  group('result rendering', () {
    test('whole doubles print without a trailing .0', () {
      expect(SqlQueryResult.display(12.0), '12');
      expect(SqlQueryResult.display(12.5), '12.5');
      expect(SqlQueryResult.display(null), '');
    });

    test('the result exports as CSV with quoting', () {
      const result = SqlQueryResult(
        columns: ['a', 'b'],
        rows: [
          ['1', 'x,y'],
        ],
      );
      expect(result.toCsv(), 'a,b\n1,"x,y"');
    });
  });
}
