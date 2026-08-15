import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:text_data/core/sql/sql_result.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// The result of a SQL query, shown as a scrollable read-only grid (Feature 4).
///
/// Built on the same `two_dimensional_scrollables` engine as the CSV and JSON
/// grids, so a wide result scrolls both ways without building every cell. The
/// header row and the row-number column stay pinned. Tapping a cell copies it.
class SqlResultGrid extends StatelessWidget {
  final SqlQueryResult result;

  const SqlResultGrid({super.key, required this.result});

  static const double _rowHeight = 40;
  static const double _headerHeight = 44;
  static const double _rowHeaderWidth = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.sqlResultEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return TableView.builder(
      pinnedRowCount: 1,
      pinnedColumnCount: 1,
      columnCount: 1 + result.columnCount,
      rowCount: 1 + result.rowCount,
      columnBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(
          index == 0 ? _rowHeaderWidth : _columnWidth(index - 1),
        ),
      ),
      rowBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(index == 0 ? _headerHeight : _rowHeight),
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
      cellBuilder: _cell,
    );
  }

  TableViewCell _cell(BuildContext context, TableVicinity vicinity) {
    final theme = Theme.of(context);
    final border = Border(
      right: BorderSide(color: theme.dividerColor, width: 0.5),
      bottom: BorderSide(color: theme.dividerColor, width: 0.5),
    );

    if (vicinity.row == 0 && vicinity.column == 0) {
      return TableViewCell(
        child: Container(decoration: BoxDecoration(border: border)),
      );
    }

    if (vicinity.column == 0) {
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            border: border,
            color: theme.colorScheme.surfaceContainerHigh,
          ),
          alignment: Alignment.center,
          child: Text('${vicinity.row}', style: theme.textTheme.labelSmall),
        ),
      );
    }

    final col = vicinity.column - 1;

    if (vicinity.row == 0) {
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(border: border),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            result.columns[col],
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final value = result.cell(vicinity.row - 1, col);
    return TableViewCell(
      child: InkWell(
        onTap: value.isEmpty ? null : () => _copy(context, value),
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

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).jsonTableCopied),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// A cheap width estimate from the header and the first rows — the same
  /// approach the CSV and JSON grids use.
  double _columnWidth(int col) {
    var longest = result.columns[col].length;
    final sample = result.rowCount < 30 ? result.rowCount : 30;
    for (var r = 0; r < sample; r++) {
      final length = result.cell(r, col).length;
      if (length > longest) longest = length;
    }
    return (longest * 8.0 + 24).clamp(80.0, 320.0);
  }
}
