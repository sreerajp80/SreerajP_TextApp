import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'csv_types.dart';

/// A simple bar chart for one CSV column (task 7.4), drawn with `fl_chart`
/// (MIT). A numeric column plots each row's value (first [maxBars] rows); a
/// non-numeric column plots the counts of its most common values. Read-only.
class CsvColumnChart extends StatelessWidget {
  final String columnName;
  final List<String> values;
  final int maxBars;

  const CsvColumnChart({
    super.key,
    required this.columnName,
    required this.values,
    this.maxBars = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = inferColumnType(values);
    final numeric = type == ColumnType.number || type == ColumnType.currency;

    final List<_Bar> bars =
        numeric ? _numericBars() : _categoryBars();
    if (bars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nothing to chart for this column.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final maxY = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numeric ? '$columnName (values)' : '$columnName (top values)',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY <= 0 ? 1 : maxY * 1.15,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bars[i].label,
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].value,
                        color: theme.colorScheme.primary,
                        width: 14,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_Bar> _numericBars() {
    final bars = <_Bar>[];
    for (var i = 0; i < values.length && bars.length < maxBars; i++) {
      final n = parseNumber(values[i]) ?? parseCurrency(values[i]);
      if (n != null) bars.add(_Bar('${i + 1}', n.toDouble()));
    }
    return bars;
  }

  List<_Bar> _categoryBars() {
    final counts = <String, int>{};
    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries.take(maxBars)) _Bar(e.key, e.value.toDouble()),
    ];
  }
}

class _Bar {
  final String label;
  final double value;
  const _Bar(this.label, this.value);
}
