import 'csv_types.dart';

/// Read-only statistics for one CSV column (task 7.4): totals that apply to any
/// column (count, empty, unique) plus numeric aggregates (min/max/sum/average)
/// when the column holds numbers or currency. Pure Dart, host-tested.
class ColumnInsights {
  final String name;
  final ColumnType type;

  /// Number of data rows (including empty cells).
  final int count;

  /// Number of empty cells.
  final int emptyCount;

  /// Number of distinct non-empty values.
  final int uniqueCount;

  /// How many cells parsed as a number (or currency).
  final int numericCount;

  /// Numeric aggregates — null when the column has no numeric values.
  final num? min;
  final num? max;
  final num? sum;
  final double? average;

  const ColumnInsights({
    required this.name,
    required this.type,
    required this.count,
    required this.emptyCount,
    required this.uniqueCount,
    required this.numericCount,
    required this.min,
    required this.max,
    required this.sum,
    required this.average,
  });

  bool get isNumeric => numericCount > 0;
}

/// Builds [ColumnInsights] for a column's [values].
class CsvInsights {
  const CsvInsights._();

  static ColumnInsights forColumn(String name, List<String> values) {
    final type = inferColumnType(values);
    var empty = 0;
    final distinct = <String>{};
    final numbers = <num>[];

    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty) {
        empty++;
        continue;
      }
      distinct.add(v);
      final n = parseNumber(v) ?? parseCurrency(v);
      if (n != null) numbers.add(n);
    }

    num? min, max, sum;
    double? average;
    if (numbers.isNotEmpty) {
      min = numbers.reduce((a, b) => a < b ? a : b);
      max = numbers.reduce((a, b) => a > b ? a : b);
      sum = numbers.reduce((a, b) => a + b);
      average = sum / numbers.length;
    }

    return ColumnInsights(
      name: name,
      type: type,
      count: values.length,
      emptyCount: empty,
      uniqueCount: distinct.length,
      numericCount: numbers.length,
      min: min,
      max: max,
      sum: sum,
      average: average,
    );
  }
}
