import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/formats/json/json_document_session.dart';
import 'package:text_data/formats/json/json_table.dart';

/// A JSON array shown as a read-only grid (roadmap §4.3.1).
///
/// Built on the same `two_dimensional_scrollables` engine as the CSV grid, so a
/// long array scrolls both ways without building every cell. Tapping a header
/// sorts by that column; tapping a cell copies its value. It is deliberately
/// **read-only** — the tree view is where JSON is edited.
class JsonTableView extends StatelessWidget {
  final JsonDocumentSession session;

  const JsonTableView({super.key, required this.session});

  static const double _rowHeight = 40;
  static const double _headerHeight = 44;
  static const double _rowHeaderWidth = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final table = session.jsonTable;

    if (table.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_rows_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.jsonTableNothingToShow,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final order = table.sortedRowIndices(
      session.tableSortColumn,
      session.tableSortDirection,
    );

    return Column(
      children: [
        _SourceBar(session: session, table: table),
        Expanded(
          child: TableView.builder(
            pinnedRowCount: 1,
            pinnedColumnCount: 1,
            columnCount: 1 + table.columnCount,
            rowCount: 1 + table.rowCount,
            columnBuilder: (index) => TableSpan(
              extent: FixedTableSpanExtent(
                index == 0 ? _rowHeaderWidth : _columnWidth(table, index - 1),
              ),
            ),
            rowBuilder: (index) => TableSpan(
              extent: FixedTableSpanExtent(
                index == 0 ? _headerHeight : _rowHeight,
              ),
              backgroundDecoration: index == 0
                  ? TableSpanDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                    )
                  : (index.isEven
                        ? TableSpanDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                          )
                        : null),
            ),
            cellBuilder: (context, vicinity) =>
                _cell(context, vicinity, table, order),
          ),
        ),
      ],
    );
  }

  TableViewCell _cell(
    BuildContext context,
    TableVicinity vicinity,
    JsonTable table,
    List<int> order,
  ) {
    final theme = Theme.of(context);
    final border = Border(
      right: BorderSide(color: theme.dividerColor, width: 0.5),
      bottom: BorderSide(color: theme.dividerColor, width: 0.5),
    );

    // Corner.
    if (vicinity.row == 0 && vicinity.column == 0) {
      return TableViewCell(
        child: Container(decoration: BoxDecoration(border: border)),
      );
    }

    // Row numbers, in the array's own order so a sorted view still says which
    // element each row came from.
    if (vicinity.column == 0) {
      final sourceRow = order[vicinity.row - 1];
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            border: border,
            color: theme.colorScheme.surfaceContainerHigh,
          ),
          alignment: Alignment.center,
          child: Text('$sourceRow', style: theme.textTheme.labelSmall),
        ),
      );
    }

    final col = vicinity.column - 1;

    // Header.
    if (vicinity.row == 0) {
      final sorted = session.tableSortColumn == col;
      final icon = !sorted
          ? null
          : (session.tableSortDirection == JsonSortDirection.ascending
                ? Icons.arrow_upward
                : session.tableSortDirection == JsonSortDirection.descending
                ? Icons.arrow_downward
                : null);
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(border: border),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            onTap: () => session.sortTableBy(col),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    table.columns[col],
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 14),
              ],
            ),
          ),
        ),
      );
    }

    final value = table.cell(order[vicinity.row - 1], col);
    return TableViewCell(
      child: InkWell(
        onTap: value.isEmpty
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).jsonTableCopied),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(border: border),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  /// A cheap width estimate from the header and the first rows — the same
  /// approach the CSV grid uses, which is enough for a readable table without
  /// measuring every cell.
  double _columnWidth(JsonTable table, int col) {
    var longest = table.columns[col].length;
    final sample = table.rowCount < 30 ? table.rowCount : 30;
    for (var r = 0; r < sample; r++) {
      final length = table.cell(r, col).length;
      if (length > longest) longest = length;
    }
    return (longest * 8.0 + 24).clamp(80.0, 320.0);
  }
}

/// Says which array is on screen and offers a way back to the whole document.
class _SourceBar extends StatelessWidget {
  final JsonDocumentSession session;
  final JsonTable table;

  const _SourceBar({required this.session, required this.table});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final path = session.tablePath;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.jsonTableSummary(path, table.rowCount, table.columnCount),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.tableSortDirection != JsonSortDirection.none)
            TextButton(
              onPressed: session.clearTableSort,
              child: Text(l10n.csvSortClear),
            ),
          if (path != r'$')
            TextButton(
              onPressed: session.showWholeDocumentAsTable,
              child: Text(l10n.jsonTableWholeDocument),
            ),
        ],
      ),
    );
  }
}
