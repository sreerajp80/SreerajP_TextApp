import 'package:flutter_test/flutter_test.dart';

import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';
import 'package:sreerajp_textapp/formats/csv/csv_sql_source.dart';
import 'package:sreerajp_textapp/formats/csv/csv_table.dart';
import 'package:sreerajp_textapp/formats/json/json_parser.dart';
import 'package:sreerajp_textapp/formats/json/json_sql_source.dart';
import 'package:sreerajp_textapp/formats/json/json_table.dart';

/// Feature 4 — the format-neutral dataset the SQL engine loads.
void main() {
  group('table and column naming', () {
    test('a file name becomes a plain table name', () {
      expect(SqlDataset.sanitizeTableName('Sales Report'), 'sales_report');
      expect(SqlDataset.sanitizeTableName('2026-data'), 't_2026_data');
      expect(SqlDataset.sanitizeTableName('***'), 'data');
      expect(SqlDataset.sanitizeTableName(''), 'data');
    });

    test('a blank header gets a usable name', () {
      final dataset = SqlDataset.fromRows(
        tableName: 'data',
        sourceLabel: 'x.csv',
        columnNames: ['name', '', 'age'],
        rows: [
          ['a', 'b', '1'],
        ],
      );
      expect(dataset.columns[1].name, 'column_2');
      expect(dataset.columns[1].wasRenamed, isTrue);
      expect(dataset.columns[0].wasRenamed, isFalse);
    });

    test('a repeated header is made unique', () {
      final dataset = SqlDataset.fromRows(
        tableName: 'data',
        sourceLabel: 'x.csv',
        columnNames: ['total', 'total', 'TOTAL'],
        rows: const [],
      );
      // Each keeps the header's own spelling; only the suffix is added, and
      // the clash is judged without case so `TOTAL` does not slip past `total`.
      expect(dataset.columns.map((c) => c.name), [
        'total',
        'total_2',
        'TOTAL_3',
      ]);
    });

    test('a header with a quote in it does not break the schema', () {
      final dataset = SqlDataset.fromRows(
        tableName: 'data',
        sourceLabel: 'x.csv',
        columnNames: ['he said "hi"'],
        rows: const [],
      );
      expect(dataset.columns.single.quotedName, '"he said ""hi"""');
      expect(dataset.createTableSql(), contains('"he said ""hi""" TEXT'));
    });

    test('a reserved word is quoted', () {
      expect(SqlDataset.quoteIdentifier('order'), '"order"');
      expect(SqlDataset.quoteIdentifier('amount'), 'amount');
    });
  });

  group('type inference', () {
    test('all-numeric columns become REAL, mixed stays text', () {
      expect(SqlDataset.inferType(['1', '2.5', '']), SqlColumnType.real);
      expect(SqlDataset.inferType(['1', 'two']), SqlColumnType.text);
      expect(SqlDataset.inferType(['true', 'no']), SqlColumnType.integer);
      expect(SqlDataset.inferType(['', '  ']), SqlColumnType.text);
    });

    test('currency and thousands separators read as numbers', () {
      expect(SqlDataset.inferType([r'$1,299.00', '₹500']), SqlColumnType.real);
      expect(SqlDataset.parseNumeric('1,234'), 1234);
      expect(SqlDataset.parseNumeric(r'$12.50'), 12.5);
      expect(SqlDataset.parseNumeric('abc'), isNull);
    });

    test('a date column stays text so it still compares in order', () {
      expect(
        SqlDataset.inferType(['2026-01-01', '2026-02-01']),
        SqlColumnType.text,
      );
    });
  });

  group('values handed to SQLite', () {
    test('a blank cell is NULL, never zero or empty text', () {
      expect(SqlDataset.sqlValue('', SqlColumnType.real), isNull);
      expect(SqlDataset.sqlValue('   ', SqlColumnType.text), isNull);
      expect(SqlDataset.sqlValue('0', SqlColumnType.real), 0.0);
    });

    test('booleans become 1 and 0', () {
      expect(SqlDataset.sqlValue('Yes', SqlColumnType.integer), 1);
      expect(SqlDataset.sqlValue('false', SqlColumnType.integer), 0);
    });

    test('text keeps its original spacing', () {
      expect(SqlDataset.sqlValue('  hi  ', SqlColumnType.text), '  hi  ');
    });
  });

  group('building from a CSV table', () {
    test('header and rows load, ragged rows are padded', () {
      final table = CsvTable(
        header: ['name', 'amount'],
        rows: [
          ['Ann', '10'],
          ['Bob'],
        ],
        hasHeader: true,
      );
      final dataset = csvSqlDataset(
        table,
        tableName: 'sales.csv',
        sourceLabel: 'sales.csv',
      );
      expect(dataset.tableName, 'sales_csv');
      expect(dataset.rowCount, 2);
      expect(dataset.rows[1], ['Bob', '']);
      expect(dataset.columns[1].type, SqlColumnType.real);
      expect(dataset.truncated, isFalse);
    });

    test('the row cap is applied and reported', () {
      final table = CsvTable(
        header: ['n'],
        rows: [
          for (var i = 0; i < 10; i++) ['$i'],
        ],
        hasHeader: true,
      );
      final dataset = csvSqlDataset(
        table,
        tableName: 'big',
        sourceLabel: 'big.csv',
        maxRows: 4,
      );
      expect(dataset.rowCount, 4);
      expect(dataset.sourceRowCount, 10);
      expect(dataset.truncated, isTrue);
    });
  });

  group('building from a JSON array', () {
    const parser = JsonParser();

    test('an array of objects becomes columns and rows', () {
      final dataset = jsonSqlDataset(
        JsonTable.fromNode(
          parser
              .parse('[{"id":1,"city":"Kochi"},{"id":2,"city":"Delhi"}]')
              .root,
        ),
        tableName: 'people',
        sourceLabel: 'people.json',
      );
      expect(dataset, isNotNull);
      expect(dataset!.columns.map((c) => c.name), ['id', 'city']);
      expect(dataset.columns[0].type, SqlColumnType.real);
      expect(dataset.rows, [
        ['1', 'Kochi'],
        ['2', 'Delhi'],
      ]);
    });

    test('a document with no array gives null instead of an empty table', () {
      final dataset = jsonSqlDataset(
        JsonTable.fromNode(parser.parse('{"a":1}').root),
        tableName: 'x',
        sourceLabel: 'x.json',
      );
      expect(dataset, isNull);
    });
  });
}
