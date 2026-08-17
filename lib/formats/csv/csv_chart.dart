import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/formats/csv/csv_chart_data.dart';
import 'package:sreerajp_textapp/formats/csv/csv_types.dart';

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

    final List<_Bar> bars = numeric ? _numericBars() : _categoryBars();
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
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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

/// An interactive chart over a prepared [CsvChartSeries] (roadmap §4.2.4).
///
/// Draws a bar, line or pie chart with `fl_chart` (MIT) and lets the user touch
/// a point to see its label and value. The data decisions live in
/// [CsvChartData]; this widget only draws.
class CsvChartView extends StatelessWidget {
  final CsvChartSeries series;
  final CsvChartType type;

  /// Shown when the series has nothing to draw.
  final String emptyMessage;

  const CsvChartView({
    super.key,
    required this.series,
    required this.type,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (series.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    switch (type) {
      case CsvChartType.bar:
        return _bar(context);
      case CsvChartType.line:
        return _line(context);
      case CsvChartType.pie:
        return _pie(context);
    }
  }

  /// A palette that stays apart from itself and reads on both themes. Slices
  /// and bars cycle through it.
  List<Color> _palette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      scheme.error,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
      scheme.secondaryContainer,
      scheme.errorContainer,
    ];
  }

  Widget _bar(BuildContext context) {
    final theme = Theme.of(context);
    final top = series.maxValue;
    final bottom = series.minValue;
    return BarChart(
      BarChartData(
        maxY: top <= 0 ? (top == 0 ? 1 : 0) : top * 1.15,
        minY: bottom < 0 ? bottom * 1.15 : 0,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
                  '${series.points[group.x].label}\n${_format(rod.toY)}',
                  theme.textTheme.labelMedium ?? const TextStyle(),
                ),
          ),
        ),
        titlesData: _titles(context),
        barGroups: [
          for (var i = 0; i < series.points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series.points[i].value,
                  color: theme.colorScheme.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context) {
    final theme = Theme.of(context);
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${series.points[spot.x.toInt()].label}\n${_format(spot.y)}',
                  theme.textTheme.labelMedium ?? const TextStyle(),
                ),
            ],
          ),
        ),
        titlesData: _titles(context),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.points.length; i++)
                FlSpot(i.toDouble(), series.points[i].value),
            ],
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: FlDotData(show: series.points.length <= 40),
          ),
        ],
      ),
    );
  }

  Widget _pie(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _palette(context);
    final total = series.points.fold<double>(0, (a, p) => a + p.value);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (var i = 0; i < series.points.length; i++)
                  PieChartSectionData(
                    value: series.points[i].value,
                    color: colors[i % colors.length],
                    radius: 70,
                    title: total <= 0
                        ? ''
                        : '${(series.points[i].value / total * 100).round()}%',
                    titleStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // A legend, because slice titles only have room for the percentage.
        SizedBox(
          width: 130,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < series.points.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            series.points[i].label,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  FlTitlesData _titles(BuildContext context) {
    final theme = Theme.of(context);
    // With many points every label would overlap, so only some are drawn.
    final step = (series.points.length / 8).ceil().clamp(1, 1000);
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 48),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= series.points.length) {
              return const SizedBox.shrink();
            }
            if (i % step != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                series.points[i].label,
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }

  static String _format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
