import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/diff/csv_diff_engine.dart';
import 'package:text_data/sync/diff/diff_models.dart';

void main() {
  const engine = CsvDiffEngine();

  group('CsvDiffEngine tests', () {
    test('identical CSV tables return zero differences', () {
      const csv = 'Name,Age,Role\nAlice,30,Engineer\nBob,25,Designer';
      final result = engine.compare(csv, csv);

      expect(result.isIdentical, isTrue);
      expect(result.totalDifferences, 0);
      expect(result.unchangedRowCount, 2);
      expect(result.headers, ['Name', 'Age', 'Role']);
    });

    test('detects cell modification in row', () {
      const local = 'Name,Age,Role\nAlice,30,Engineer\nBob,25,Designer';
      const remote = 'Name,Age,Role\nAlice,31,Lead Engineer\nBob,25,Designer';
      final result = engine.compare(local, remote);

      expect(result.isIdentical, isFalse);
      expect(result.modifiedRowCount, 1);
      expect(result.unchangedRowCount, 1);

      final modRow = result.rows.firstWhere((r) => r.type == DiffType.modified);
      final ageCell = modRow.cells.firstWhere((c) => c.columnName == 'Age');
      expect(ageCell.isChanged, isTrue);
      expect(ageCell.localValue, '30');
      expect(ageCell.remoteValue, '31');
    });

    test('detects added and deleted rows', () {
      const local = 'Name,City\nAlice,Tokyo\nBob,London';
      const remote = 'Name,City\nAlice,Tokyo\nBob,London\nCharlie,Paris';
      final result = engine.compare(local, remote);

      expect(result.addedRowCount, 1);
      expect(result.rows.last.type, DiffType.added);
      expect(result.rows.last.cells.first.remoteValue, 'Charlie');
    });
  });
}
