import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'csv_chart.dart';
import 'csv_document_session.dart';
import 'csv_insights.dart';
import 'csv_types.dart';

/// A bottom sheet with read-only data insights for the CSV (task 7.4): pick a
/// column to see its type, count / empty / unique, numeric min / max / sum /
/// average, and a simple bar chart.
Future<void> showCsvInsightsSheet(
  BuildContext context,
  CsvDocumentSession session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) =>
          _InsightsBody(session: session, scrollController: scrollController),
    ),
  );
}

class _InsightsBody extends StatefulWidget {
  final CsvDocumentSession session;
  final ScrollController scrollController;

  const _InsightsBody({required this.session, required this.scrollController});

  @override
  State<_InsightsBody> createState() => _InsightsBodyState();
}

class _InsightsBodyState extends State<_InsightsBody> {
  int _column = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final table = widget.session.table;
    if (table.columnCount == 0) {
      return Center(child: Text(l10n.csvNoColumns));
    }
    final col = _column.clamp(0, table.columnCount - 1);
    final values = table.column(col);
    final insights = CsvInsights.forColumn(table.header[col], values);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(l10n.csvDataInsights, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: col,
          decoration: InputDecoration(
            labelText: l10n.csvColumnLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (var c = 0; c < table.columnCount; c++)
              DropdownMenuItem(
                value: c,
                child: Text(
                  table.header[c].isEmpty
                      ? l10n.csvColumnN(c + 1)
                      : table.header[c],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _column = value);
          },
        ),
        const SizedBox(height: 16),
        _stat(l10n.csvStatType, insights.type.label),
        _stat(l10n.csvStatValues, '${insights.count}'),
        _stat(l10n.csvStatEmpty, '${insights.emptyCount}'),
        _stat(l10n.csvStatUnique, '${insights.uniqueCount}'),
        if (insights.isNumeric) ...[
          const Divider(height: 24),
          _stat(l10n.csvStatMin, _fmt(insights.min)),
          _stat(l10n.csvStatMax, _fmt(insights.max)),
          _stat(l10n.csvStatSum, _fmt(insights.sum)),
          _stat(l10n.csvStatAverage, _fmt(insights.average)),
        ],
        const SizedBox(height: 20),
        CsvColumnChart(columnName: insights.name, values: values),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _fmt(num? value) {
    if (value == null) return '—';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
