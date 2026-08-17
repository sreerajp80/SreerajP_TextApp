import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/csv/csv_chart.dart';
import 'package:sreerajp_textapp/formats/csv/csv_chart_data.dart';
import 'package:sreerajp_textapp/formats/csv/csv_document_session.dart';

/// The full-screen interactive chart for a CSV (roadmap §4.2.4).
///
/// The user picks the chart shape, the numeric column to plot and an optional
/// column to label the points with; the chart follows the grid's current filter
/// so what is on screen is what is charted.
class CsvChartScreen extends StatefulWidget {
  final CsvDocumentSession session;

  /// The column to start on. Falls back to the first numeric column.
  final int? initialColumn;

  const CsvChartScreen({super.key, required this.session, this.initialColumn});

  static Future<void> open(
    BuildContext context,
    CsvDocumentSession session, {
    int? initialColumn,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            CsvChartScreen(session: session, initialColumn: initialColumn),
      ),
    );
  }

  @override
  State<CsvChartScreen> createState() => _CsvChartScreenState();
}

class _CsvChartScreenState extends State<CsvChartScreen> {
  CsvChartType _type = CsvChartType.bar;
  int? _valueColumn;
  int? _labelColumn;

  /// Only plot what the grid is currently showing, so a filtered table charts
  /// the rows the user can actually see.
  bool _visibleRowsOnly = true;

  @override
  void initState() {
    super.initState();
    final numeric = CsvChartData.numericColumns(widget.session.table);
    _valueColumn =
        widget.initialColumn != null && numeric.contains(widget.initialColumn)
        ? widget.initialColumn
        : (numeric.isNotEmpty ? numeric.first : null);
  }

  String _columnName(int col) {
    final l10n = AppLocalizations.of(context);
    final header = widget.session.table.header;
    if (col < 0 || col >= header.length) return l10n.csvColumnN(col + 1);
    return header[col].isEmpty ? l10n.csvColumnN(col + 1) : header[col];
  }

  CsvChartSeries _buildSeries() {
    final table = widget.session.table;
    final rows = _visibleRowsOnly ? widget.session.visibleRowIndices : null;
    final l10n = AppLocalizations.of(context);
    if (_type == CsvChartType.pie) {
      return CsvChartData.pieSeries(
        table,
        valueColumn: _valueColumn!,
        labelColumn: _labelColumn,
        rows: rows,
        otherLabel: l10n.csvChartOther,
      );
    }
    return CsvChartData.series(
      table,
      valueColumn: _valueColumn!,
      labelColumn: _labelColumn,
      rows: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final table = widget.session.table;
    final numeric = CsvChartData.numericColumns(table);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvChartTitle)),
      body: numeric.isEmpty || _valueColumn == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.csvChartNoNumericColumns,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : _body(theme, l10n, numeric),
    );
  }

  Widget _body(ThemeData theme, AppLocalizations l10n, List<int> numeric) {
    final series = _buildSeries();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<CsvChartType>(
              segments: [
                ButtonSegment(
                  value: CsvChartType.bar,
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: Text(l10n.csvChartBar),
                ),
                ButtonSegment(
                  value: CsvChartType.line,
                  icon: const Icon(Icons.show_chart, size: 18),
                  label: Text(l10n.csvChartLine),
                ),
                ButtonSegment(
                  value: CsvChartType.pie,
                  icon: const Icon(Icons.pie_chart_outline, size: 18),
                  label: Text(l10n.csvChartPie),
                ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: CsvChartView(
                series: series,
                type: _type,
                emptyMessage: l10n.csvChartNothingToDraw,
              ),
            ),
          ),
          if (series.omitted > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _type == CsvChartType.pie
                    ? l10n.csvChartSkippedNegative(series.omitted)
                    : l10n.csvChartShowingFirst(series.points.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _valueColumn,
                  decoration: InputDecoration(
                    labelText: l10n.csvChartValueColumn,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final c in numeric)
                      DropdownMenuItem(
                        value: c,
                        child: Text(
                          _columnName(c),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _valueColumn = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _labelColumn ?? -1,
                  decoration: InputDecoration(
                    labelText: l10n.csvChartLabelColumn,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: -1,
                      child: Text(l10n.csvChartRowNumbers),
                    ),
                    for (var c = 0; c < widget.session.table.columnCount; c++)
                      DropdownMenuItem(
                        value: c,
                        child: Text(
                          _columnName(c),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => _labelColumn = value == null || value < 0
                        ? null
                        : value,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _visibleRowsOnly,
                  title: Text(l10n.csvChartVisibleRowsOnly),
                  onChanged: (value) =>
                      setState(() => _visibleRowsOnly = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
