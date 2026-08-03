import 'csv_table.dart';
import 'csv_types.dart';

/// The chart shapes the full-screen chart offers (roadmap §4.2.4).
enum CsvChartType { bar, line, pie }

/// One plotted point: a label for the axis / legend and its numeric value.
class CsvChartPoint {
  final String label;
  final double value;

  const CsvChartPoint(this.label, this.value);

  @override
  bool operator ==(Object other) =>
      other is CsvChartPoint && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'CsvChartPoint($label, $value)';
}

/// A ready-to-draw series plus the note the chart shows when it had to leave
/// data out.
class CsvChartSeries {
  final String title;
  final List<CsvChartPoint> points;

  /// How many source rows / values the series left out, so the screen can say
  /// "showing the first 100 of 4,000".
  final int omitted;

  const CsvChartSeries({
    required this.title,
    required this.points,
    this.omitted = 0,
  });

  bool get isEmpty => points.isEmpty;

  double get maxValue =>
      points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  double get minValue =>
      points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
}

/// Turns a CSV column into chart points (roadmap §4.2.4).
///
/// Pure Dart with no Flutter import, so the shaping rules are host-tested and
/// the chart widget stays a drawing job only.
class CsvChartData {
  const CsvChartData._();

  /// The default number of points a bar or line chart draws before it stops.
  static const int defaultMaxPoints = 100;

  /// The number of slices a pie chart shows before the rest is grouped.
  static const int defaultMaxSlices = 8;

  /// Column indices whose values read as numbers, so the screen can offer only
  /// the columns worth plotting.
  static List<int> numericColumns(CsvTable table) {
    final out = <int>[];
    for (var c = 0; c < table.columnCount; c++) {
      final type = inferColumnType(table.column(c));
      if (type == ColumnType.number || type == ColumnType.currency) out.add(c);
    }
    return out;
  }

  /// Builds the series for a bar or line chart: one point per row of
  /// [valueColumn], labelled from [labelColumn] when given (otherwise the row
  /// number). Rows whose value is not a number are skipped.
  ///
  /// Only [rows] are considered, so the chart follows the grid's current filter
  /// when the caller passes the visible rows.
  static CsvChartSeries series(
    CsvTable table, {
    required int valueColumn,
    int? labelColumn,
    List<int>? rows,
    int maxPoints = defaultMaxPoints,
  }) {
    final title = _columnName(table, valueColumn);
    if (valueColumn < 0 || valueColumn >= table.columnCount) {
      return CsvChartSeries(title: title, points: const []);
    }
    final source = rows ?? [for (var r = 0; r < table.rowCount; r++) r];

    final points = <CsvChartPoint>[];
    var considered = 0;
    for (final r in source) {
      final n = _numberAt(table, r, valueColumn);
      if (n == null) continue;
      considered++;
      if (points.length >= maxPoints) continue;
      final label = labelColumn != null && labelColumn >= 0
          ? table.cell(r, labelColumn)
          : '${r + 1}';
      points.add(CsvChartPoint(label.isEmpty ? '${r + 1}' : label, n));
    }
    return CsvChartSeries(
      title: title,
      points: points,
      omitted: considered - points.length,
    );
  }

  /// Builds the slices for a pie chart.
  ///
  /// With a [labelColumn] the values in [valueColumn] are **totalled per
  /// label**, which is what makes a pie meaningful ("sales per region").
  /// Without one, each row is its own slice. Negative values cannot be drawn as
  /// slices, so they are left out. Beyond [maxSlices] the remainder is grouped
  /// into one "Other" slice rather than dropped.
  static CsvChartSeries pieSeries(
    CsvTable table, {
    required int valueColumn,
    int? labelColumn,
    List<int>? rows,
    int maxSlices = defaultMaxSlices,
    String otherLabel = 'Other',
  }) {
    final title = _columnName(table, valueColumn);
    if (valueColumn < 0 || valueColumn >= table.columnCount) {
      return CsvChartSeries(title: title, points: const []);
    }
    final source = rows ?? [for (var r = 0; r < table.rowCount; r++) r];

    final totals = <String, double>{};
    var skipped = 0;
    for (final r in source) {
      final n = _numberAt(table, r, valueColumn);
      if (n == null) continue;
      if (n < 0) {
        skipped++;
        continue;
      }
      final rawLabel = labelColumn != null && labelColumn >= 0
          ? table.cell(r, labelColumn)
          : '${r + 1}';
      final label = rawLabel.trim().isEmpty ? '${r + 1}' : rawLabel.trim();
      totals[label] = (totals[label] ?? 0) + n;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.length <= maxSlices) {
      return CsvChartSeries(
        title: title,
        points: [for (final e in entries) CsvChartPoint(e.key, e.value)],
        omitted: skipped,
      );
    }

    final kept = entries.take(maxSlices - 1).toList();
    final rest = entries.skip(maxSlices - 1).fold<double>(0, (a, e) => a + e.value);
    return CsvChartSeries(
      title: title,
      points: [
        for (final e in kept) CsvChartPoint(e.key, e.value),
        CsvChartPoint(otherLabel, rest),
      ],
      omitted: skipped,
    );
  }

  static String _columnName(CsvTable table, int col) {
    if (col < 0 || col >= table.header.length) return '';
    final name = table.header[col];
    return name.isEmpty ? 'Column ${col + 1}' : name;
  }

  static double? _numberAt(CsvTable table, int row, int col) {
    final raw = table.cell(row, col);
    final n = parseNumber(raw) ?? parseCurrency(raw);
    return n?.toDouble();
  }
}
