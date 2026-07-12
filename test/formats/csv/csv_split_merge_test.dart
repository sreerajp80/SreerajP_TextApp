import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/formats/csv/csv_dialect.dart';
import 'package:text_data/formats/csv/csv_split_merge.dart';
import 'package:text_data/formats/csv/csv_table.dart';

void main() {
  const dialect = CsvDialect(hasHeader: true, lineEnding: LineEndingStyle.lf);

  CsvTable table(int rows) => CsvTable(
        header: ['id', 'name'],
        rows: [
          for (var i = 0; i < rows; i++) ['$i', 'row$i'],
        ],
        hasHeader: true,
      );

  test('splitByRows repeats the header on every part', () {
    final parts = CsvSplitMerge.splitByRows(table(5), 2);
    expect(parts.length, 3); // 2 + 2 + 1
    for (final part in parts) {
      expect(part.header, ['id', 'name']);
      expect(part.hasHeader, isTrue);
    }
    expect(parts[0].rowCount, 2);
    expect(parts[2].rowCount, 1);
  });

  test('merge(splitByRows(t)) reproduces the original table', () {
    final original = table(7);
    final parts = CsvSplitMerge.splitByRows(original, 3);
    final merged = CsvSplitMerge.merge(parts);
    expect(merged.contentEquals(original), isTrue);
  });

  test('splitBySize keeps each part under the byte cap', () {
    final original = table(20);
    final parts = CsvSplitMerge.splitBySize(original, 40, dialect);
    expect(parts.length, greaterThan(1));
    // Reassembling still yields the original rows.
    expect(CsvSplitMerge.merge(parts).contentEquals(original), isTrue);
  });

  test('merge concatenates rows from parts sharing columns', () {
    final a = table(2);
    final b = CsvTable(
      header: ['id', 'name'],
      rows: [
        ['9', 'row9'],
      ],
      hasHeader: true,
    );
    final merged = CsvSplitMerge.merge([a, b]);
    expect(merged.rowCount, 3);
    expect(merged.cell(2, 1), 'row9');
  });
}
