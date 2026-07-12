import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../l10n/app_localizations.dart';
import 'csv_cell_editor.dart';
import 'csv_document_session.dart';
import 'csv_filter_sort.dart';
import 'csv_types.dart';

/// The data grid for a CSV document (tasks 7.2, 7.5).
///
/// Built on `two_dimensional_scrollables`' [TableView.builder], which lazily
/// builds only visible cells and supports pinned (frozen) rows and columns — so
/// the header row and the first column can be frozen and large grids scroll both
/// ways without a bespoke engine. A leading row-number column carries the
/// per-row menu (insert / delete / move). Header taps sort; data-cell taps edit.
///
/// Rows render in the session's filtered + sorted order, but every edit is
/// addressed to the **original** row, so filtering/sorting never corrupts data.
class CsvGrid extends StatefulWidget {
  final CsvDocumentSession session;
  final bool editable;

  const CsvGrid({super.key, required this.session, required this.editable});

  @override
  State<CsvGrid> createState() => CsvGridState();
}

class CsvGridState extends State<CsvGrid> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  static const double _rowHeight = 40;
  static const double _headerHeight = 44;
  static const double _rowHeaderWidth = 56;

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  /// Scrolls the grid so the data row at display position [displayIndex]
  /// (0-based, in the current filtered/sorted order) is near the top. Used by
  /// the toolbar's "jump to row".
  void jumpToDisplayRow(int displayIndex) {
    if (!_vertical.hasClients) return;
    final offset = (displayIndex * _rowHeight)
        .clamp(0.0, _vertical.position.maxScrollExtent);
    _vertical.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  List<int> get _visibleCols {
    final s = widget.session;
    return [
      for (var c = 0; c < s.table.columnCount; c++)
        if (!s.hiddenColumns.contains(c)) c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final theme = Theme.of(context);
    final visibleCols = _visibleCols;
    final visibleRows = session.visibleRowIndices;
    final types = session.columnTypes;
    final widths = _columnWidths(visibleCols, visibleRows);

    // Consume a one-shot jump request from the toolbar.
    final jump = session.pendingJumpRow;
    if (jump != null) {
      session.clearPendingJump();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final display = visibleRows.indexOf(jump);
        if (display >= 0) jumpToDisplayRow(display);
      });
    }

    return TableView.builder(
      verticalDetails: ScrollableDetails.vertical(controller: _vertical),
      horizontalDetails: ScrollableDetails.horizontal(controller: _horizontal),
      diagonalDragBehavior: DiagonalDragBehavior.free,
      pinnedRowCount: session.freezeHeader ? 1 : 0,
      pinnedColumnCount: session.freezeFirstColumn ? 2 : 1,
      columnCount: 1 + visibleCols.length,
      rowCount: 1 + visibleRows.length,
      columnBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(
          index == 0 ? _rowHeaderWidth : widths[index - 1],
        ),
      ),
      rowBuilder: (index) {
        final Color? color;
        if (index == 0) {
          color = theme.colorScheme.surfaceContainerHighest;
        } else if (index.isEven) {
          color = theme.colorScheme.surfaceContainerLow;
        } else {
          color = null;
        }
        return TableSpan(
          extent: FixedTableSpanExtent(index == 0 ? _headerHeight : _rowHeight),
          backgroundDecoration:
              color == null ? null : TableSpanDecoration(color: color),
        );
      },
      cellBuilder: (context, vicinity) => _cell(
        context,
        vicinity,
        visibleCols,
        visibleRows,
        types,
      ),
    );
  }

  TableViewCell _cell(
    BuildContext context,
    TableVicinity vicinity,
    List<int> visibleCols,
    List<int> visibleRows,
    List<ColumnType> types,
  ) {
    final session = widget.session;
    final theme = Theme.of(context);
    final border = Border(
      right: BorderSide(color: theme.dividerColor, width: 0.5),
      bottom: BorderSide(color: theme.dividerColor, width: 0.5),
    );

    // Corner cell.
    if (vicinity.row == 0 && vicinity.column == 0) {
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(border: border),
          alignment: Alignment.center,
          child: widget.editable
              ? IconButton(
                  tooltip: AppLocalizations.of(context).csvAddRow,
                  iconSize: 18,
                  icon: const Icon(Icons.add),
                  onPressed: () => session.insertRow(session.table.rowCount),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    // Row-number / row-menu column.
    if (vicinity.column == 0) {
      final display = vicinity.row - 1;
      final originalRow = visibleRows[display];
      final selected = session.selectedRows.contains(originalRow);
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            border: border,
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
          ),
          child: InkWell(
            onTap: () => session.toggleRowSelected(originalRow),
            onLongPress: widget.editable
                ? () => _showRowMenu(context, originalRow)
                : null,
            child: Center(
              child: Text(
                '${originalRow + 1}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ),
      );
    }

    final col = visibleCols[vicinity.column - 1];

    // Header row.
    if (vicinity.row == 0) {
      final sortIcon = session.sortColumn == col
          ? (session.sortDirection == SortDirection.ascending
              ? Icons.arrow_upward
              : session.sortDirection == SortDirection.descending
                  ? Icons.arrow_downward
                  : null)
          : null;
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(border: border),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            onTap: () => session.sortBy(col),
            onLongPress:
                widget.editable ? () => _showColumnMenu(context, col) : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    session.table.header.isNotEmpty
                        ? session.table.header[col]
                        : '',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (sortIcon != null) Icon(sortIcon, size: 14),
              ],
            ),
          ),
        ),
      );
    }

    // Data cell.
    final display = vicinity.row - 1;
    final originalRow = visibleRows[display];
    final value = session.table.cell(originalRow, col);
    final numeric =
        types[col] == ColumnType.number || types[col] == ColumnType.currency;
    return TableViewCell(
      child: InkWell(
        onTap: widget.editable
            ? () => _editCell(context, originalRow, col, value)
            : null,
        child: Container(
          decoration: BoxDecoration(border: border),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
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

  Future<void> _editCell(
    BuildContext context,
    int row,
    int col,
    String value,
  ) async {
    final l10n = AppLocalizations.of(context);
    final header = widget.session.table.header;
    final name = col < header.length ? header[col] : l10n.csvCellFallback;
    final result = await showCsvCellEditor(
      context,
      title: l10n.csvEditCell(name),
      initialValue: value,
    );
    if (result != null) widget.session.setCell(row, col, result);
  }

  Future<void> _showColumnMenu(BuildContext context, int col) async {
    final session = widget.session;
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.csvRenameColumn),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: Text(l10n.csvInsertColumnLeft),
              onTap: () => Navigator.pop(context, 'insertLeft'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: Text(l10n.csvInsertColumnRight),
              onTap: () => Navigator.pop(context, 'insertRight'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(l10n.csvHideColumn),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.csvDeleteColumn),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        final header = session.table.header;
        final result = await showCsvCellEditor(
          context,
          title: l10n.csvRenameColumn,
          initialValue: col < header.length ? header[col] : '',
        );
        if (result != null) session.renameHeader(col, result);
        break;
      case 'insertLeft':
        session.insertColumn(col);
        break;
      case 'insertRight':
        session.insertColumn(col + 1);
        break;
      case 'hide':
        session.setColumnHidden(col, true);
        break;
      case 'delete':
        session.deleteColumn(col);
        break;
    }
  }

  Future<void> _showRowMenu(BuildContext context, int row) async {
    final session = widget.session;
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.csvInsertRowAbove),
              onTap: () => Navigator.pop(context, 'above'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.csvInsertRowBelow),
              onTap: () => Navigator.pop(context, 'below'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(l10n.csvMoveUp),
              onTap: () => Navigator.pop(context, 'up'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text(l10n.csvMoveDown),
              onTap: () => Navigator.pop(context, 'down'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.csvDeleteRow),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case 'above':
        session.insertRow(row);
        break;
      case 'below':
        session.insertRow(row + 1);
        break;
      case 'up':
        session.moveRow(row, row - 1);
        break;
      case 'down':
        session.moveRow(row, row + 1);
        break;
      case 'delete':
        session.deleteRow(row);
        break;
    }
  }

  /// Auto-fits each visible column's width to its content (header + a sample of
  /// visible rows), clamped to a sensible range. A cheap approximation using an
  /// average character width — enough for a readable grid without measuring text.
  List<double> _columnWidths(List<int> visibleCols, List<int> visibleRows) {
    final session = widget.session;
    const charWidth = 8.0;
    const minWidth = 72.0;
    const maxWidth = 320.0;
    final sampleRows = visibleRows.take(50).toList();
    return [
      for (final col in visibleCols)
        () {
          var longest = col < session.table.header.length
              ? session.table.header[col].length
              : 0;
          for (final r in sampleRows) {
            final len = session.table.cell(r, col).length;
            if (len > longest) longest = len;
          }
          return (longest * charWidth + 24).clamp(minWidth, maxWidth);
        }(),
    ];
  }
}
