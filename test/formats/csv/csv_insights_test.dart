import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/csv/csv_insights.dart';
import 'package:text_data/formats/csv/csv_types.dart';

void main() {
  group('type inference', () {
    test('numbers, currency, boolean, date, text', () {
      expect(inferColumnType(['1', '2', '3']), ColumnType.number);
      expect(inferColumnType([r'$1,299.00', r'$5']), ColumnType.currency);
      expect(inferColumnType(['true', 'no', 'YES']), ColumnType.boolean);
      expect(inferColumnType(['2020-01-01', '2021-12-31']), ColumnType.date);
      expect(inferColumnType(['red', 'blue']), ColumnType.text);
    });

    test('empty cells are ignored and a mixed column is text', () {
      expect(inferColumnType(['1', '', '2']), ColumnType.number);
      expect(inferColumnType(['1', 'two']), ColumnType.text);
      expect(inferColumnType(['', '']), ColumnType.text);
    });
  });

  group('column insights', () {
    test('numeric aggregates are correct', () {
      final i = CsvInsights.forColumn('score', ['10', '20', '30', '']);
      expect(i.type, ColumnType.number);
      expect(i.count, 4);
      expect(i.emptyCount, 1);
      expect(i.numericCount, 3);
      expect(i.min, 10);
      expect(i.max, 30);
      expect(i.sum, 60);
      expect(i.average, 20);
    });

    test('unique count on a text column, no numeric aggregates', () {
      final i = CsvInsights.forColumn('city', ['A', 'B', 'A', 'C']);
      expect(i.uniqueCount, 3);
      expect(i.isNumeric, isFalse);
      expect(i.average, isNull);
    });

    test('currency values are summed numerically', () {
      final i = CsvInsights.forColumn('price', [r'$10', r'$20.50']);
      expect(i.isNumeric, isTrue);
      expect(i.sum, 30.5);
    });
  });
}
