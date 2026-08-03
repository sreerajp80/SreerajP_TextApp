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

  group('multi-column sort (roadmap 4.2.1)', () {
    // Department, then salary — the roadmap's own example.
    CsvTable staff() => CsvTable(
          header: ['dept', 'salary', 'name'],
          rows: [
            ['Sales', '500', 'Ada'],
            ['Eng', '900', 'Bob'],
            ['Sales', '700', 'Cid'],
            ['Eng', '400', 'Dee'],
            ['Sales', '700', 'Eve'],
          ],
          hasHeader: true,
        );

    test('sorts by department ascending, then salary descending', () {
      final t = staff();
      final result = CsvFilterSort.sortMulti(t, [0, 1, 2, 3, 4], const [
        CsvSortSpec(0, SortDirection.ascending),
        CsvSortSpec(1, SortDirection.descending),
      ]);
      // Eng 900 (Bob), Eng 400 (Dee), Sales 700 (Cid), Sales 700 (Eve), Sales 500 (Ada)
      expect(result, [1, 3, 2, 4, 0]);
    });

    test('later levels only break ties left by earlier ones', () {
      final t = staff();
      final result = CsvFilterSort.sortMulti(t, [0, 1, 2, 3, 4], const [
        CsvSortSpec(0, SortDirection.ascending),
        CsvSortSpec(2, SortDirection.ascending),
      ]);
      expect(result, [1, 3, 0, 2, 4]);
    });

    test('is stable when every level ties', () {
      final t = staff();
      // Cid and Eve both earn 700; the incoming order decides.
      final result =
          CsvFilterSort.sortMulti(t, [4, 2], const [CsvSortSpec(1, SortDirection.ascending)]);
      expect(result, [4, 2]);
    });

    test('skips levels that are none or name a missing column', () {
      final t = staff();
      final result = CsvFilterSort.sortMulti(t, [0, 1, 2, 3, 4], const [
        CsvSortSpec(9, SortDirection.ascending),
        CsvSortSpec(0, SortDirection.none),
        CsvSortSpec(1, SortDirection.ascending),
      ]);
      expect(result, [3, 0, 2, 4, 1]); // 400, 500, 700, 700, 900
    });

    test('an empty spec list leaves the order alone', () {
      final t = staff();
      expect(CsvFilterSort.sortMulti(t, [3, 1, 0], const []), [3, 1, 0]);
    });

    test('does not mutate the list it was given', () {
      final t = staff();
      final input = [0, 1, 2, 3, 4];
      CsvFilterSort.sortMulti(t, input, const [CsvSortSpec(1, SortDirection.ascending)]);
      expect(input, [0, 1, 2, 3, 4]);
    });

    test('a non-numeric cell in a numeric column sorts after the numbers', () {
      final t = CsvTable(
        header: ['n'],
        rows: [
          ['5'],
          [''],
          ['1'],
        ],
        hasHeader: true,
      );
      final result = CsvFilterSort.sortMulti(
          t, [0, 1, 2], const [CsvSortSpec(0, SortDirection.ascending)]);
      expect(result, [2, 0, 1]);
    });
  });

  group('CsvSortSpec storage', () {
    test('round-trips through encode / decode', () {
      const spec = CsvSortSpec(3, SortDirection.descending);
      expect(CsvSortSpec.decode(spec.encode()), spec);
    });

    test('rejects text that is not a spec', () {
      expect(CsvSortSpec.decode(''), isNull);
      expect(CsvSortSpec.decode('abc'), isNull);
      expect(CsvSortSpec.decode('1'), isNull);
      expect(CsvSortSpec.decode('-1:1'), isNull);
      expect(CsvSortSpec.decode('1:99'), isNull);
    });
  });
}
