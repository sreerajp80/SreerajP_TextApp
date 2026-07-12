import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/csv/csv_filter_sort.dart';
import 'package:text_data/formats/csv/csv_table.dart';

void main() {
  CsvTable table() => CsvTable(
        header: ['name', 'age'],
        rows: [
          ['Ada', '36'],
          ['Bob', '40'],
          ['Cid', '8'],
        ],
        hasHeader: true,
      );

  test('filter returns matching row indices (case-insensitive)', () {
    final t = table();
    expect(CsvFilterSort.filter(t, 'bob'), [1]);
    expect(CsvFilterSort.filter(t, '8'), [2]);
    expect(CsvFilterSort.filter(t, ''), [0, 1, 2]); // all rows
    expect(CsvFilterSort.filter(t, 'zzz'), isEmpty);
  });

  test('sort numeric column ascending and descending', () {
    final t = table();
    final all = [0, 1, 2];
    final asc = CsvFilterSort.sort(t, all, 1, SortDirection.ascending);
    expect(asc, [2, 0, 1]); // 8, 36, 40
    final desc = CsvFilterSort.sort(t, all, 1, SortDirection.descending);
    expect(desc, [1, 0, 2]);
  });

  test('sort text column alphabetically', () {
    final t = table();
    final asc = CsvFilterSort.sort(t, [0, 1, 2], 0, SortDirection.ascending);
    expect(asc, [0, 1, 2]); // Ada, Bob, Cid
  });

  test('sort none returns the input order unchanged', () {
    final t = table();
    expect(CsvFilterSort.sort(t, [2, 0, 1], 0, SortDirection.none), [2, 0, 1]);
  });
}
