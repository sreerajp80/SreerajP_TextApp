import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/csv/csv_chart_data.dart';
import 'package:text_data/formats/csv/csv_table.dart';

/// Guards the shaping rules behind the full-screen interactive charts
/// (roadmap §4.2.4). The drawing itself is `fl_chart`'s job; only the data
/// decisions are tested here.
void main() {
  CsvTable table() => CsvTable(
        header: ['region', 'sales', 'note'],
        rows: [
          ['North', '100', 'a'],
          ['South', '50', 'b'],
          ['North', '25', 'c'],
          ['East', 'n/a', 'd'],
        ],
        hasHeader: true,
      );

  test('numericColumns finds only the columns worth plotting', () {
    final t = CsvTable(
      header: ['region', 'sales', 'note'],
      rows: [
        ['North', '100', 'a'],
        ['South', '50', 'b'],
      ],
      hasHeader: true,
    );
    expect(CsvChartData.numericColumns(t), [1]);
  });

  test('numericColumns on a table with no numbers is empty', () {
    final t = CsvTable(
      header: ['a'],
      rows: [
        ['x'],
        ['y'],
      ],
      hasHeader: true,
    );
    expect(CsvChartData.numericColumns(t), isEmpty);
  });

  group('bar and line series', () {
    test('one point per row, labelled from the label column', () {
      final s = CsvChartData.series(table(), valueColumn: 1, labelColumn: 0);
      expect(s.points, const [
        CsvChartPoint('North', 100),
        CsvChartPoint('South', 50),
        CsvChartPoint('North', 25),
      ]);
      expect(s.title, 'sales');
    });

    test('rows whose value is not a number are left out', () {
      final s = CsvChartData.series(table(), valueColumn: 1);
      expect(s.points.length, 3); // the "n/a" row is skipped
    });

    test('without a label column the row number is used', () {
      final s = CsvChartData.series(table(), valueColumn: 1);
      expect(s.points.first.label, '1');
      expect(s.points.last.label, '3');
    });

    test('only the given rows are plotted', () {
      final s = CsvChartData.series(table(), valueColumn: 1, rows: [1]);
      expect(s.points, const [CsvChartPoint('2', 50)]);
    });

    test('long data is capped and the leftover is reported', () {
      final s = CsvChartData.series(table(), valueColumn: 1, maxPoints: 2);
      expect(s.points.length, 2);
      expect(s.omitted, 1);
    });

    test('min and max describe the series', () {
      final s = CsvChartData.series(table(), valueColumn: 1);
      expect(s.maxValue, 100);
      expect(s.minValue, 25);
    });

    test('a column outside the table gives an empty series', () {
      final s = CsvChartData.series(table(), valueColumn: 9);
      expect(s.isEmpty, isTrue);
      expect(s.maxValue, 0);
    });
  });

  group('pie series', () {
    test('totals the value column per label', () {
      final s = CsvChartData.pieSeries(table(), valueColumn: 1, labelColumn: 0);
      expect(s.points, const [
        CsvChartPoint('North', 125), // 100 + 25
        CsvChartPoint('South', 50),
      ]);
    });

    test('slices are ordered largest first', () {
      final s = CsvChartData.pieSeries(table(), valueColumn: 1, labelColumn: 0);
      expect(s.points.first.label, 'North');
    });

    test('negative values cannot be a slice and are reported', () {
      final t = CsvTable(
        header: ['k', 'v'],
        rows: [
          ['a', '10'],
          ['b', '-5'],
        ],
        hasHeader: true,
      );
      final s = CsvChartData.pieSeries(t, valueColumn: 1, labelColumn: 0);
      expect(s.points, const [CsvChartPoint('a', 10)]);
      expect(s.omitted, 1);
    });

    test('extra labels are grouped instead of dropped', () {
      final t = CsvTable(
        header: ['k', 'v'],
        rows: [
          ['a', '10'],
          ['b', '9'],
          ['c', '8'],
          ['d', '7'],
        ],
        hasHeader: true,
      );
      final s = CsvChartData.pieSeries(
        t,
        valueColumn: 1,
        labelColumn: 0,
        maxSlices: 3,
        otherLabel: 'Other',
      );
      expect(s.points, const [
        CsvChartPoint('a', 10),
        CsvChartPoint('b', 9),
        CsvChartPoint('Other', 15), // 8 + 7, nothing lost
      ]);
    });

    test('without a label column each row is its own slice', () {
      final s = CsvChartData.pieSeries(table(), valueColumn: 1);
      expect(s.points.length, 3);
    });
  });
}
