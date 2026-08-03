import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'md_table_source.dart';

/// The visual Markdown table builder (roadmap §4.4.2).
///
/// A grid of text fields with buttons to add or remove rows and columns and to
/// set each column's alignment, plus a live preview of the Markdown it will
/// write. Returns the finished table text, or null when the user backs out.
///
/// [initial] pre-fills the grid — that is how the table under the cursor is
/// opened for editing instead of a fresh one.
Future<String?> showMdTableBuilder(
  BuildContext context, {
  MdTableData? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TableBuilderDialog(initial: initial),
  );
}

class _TableBuilderDialog extends StatefulWidget {
  final MdTableData? initial;

  const _TableBuilderDialog({this.initial});

  @override
  State<_TableBuilderDialog> createState() => _TableBuilderDialogState();
}

class _TableBuilderDialogState extends State<_TableBuilderDialog> {
  late final MdTableData _table = widget.initial?.copy() ?? MdTableData.blank();

  /// One controller per cell, keyed `row:col` with row -1 meaning the header.
  /// Rebuilt whenever the shape changes, so a removed column cannot leave a
  /// stale controller behind.
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int row, int col) {
    final key = '$row:$col';
    final text = row < 0 ? _table.header[col] : _table.cell(row, col);
    final existing = _controllers[key];
    if (existing != null) {
      if (existing.text != text) existing.text = text;
      return existing;
    }
    final created = TextEditingController(text: text);
    _controllers[key] = created;
    return created;
  }

  /// Drops the controllers for cells that no longer exist, so the grid and the
  /// controllers never drift apart.
  void _pruneControllers() {
    _controllers.removeWhere((key, controller) {
      final parts = key.split(':');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final gone = col >= _table.columnCount || row >= _table.rowCount;
      if (gone) controller.dispose();
      return gone;
    });
  }

  /// After a shape change the cells shift, so the text is re-read from the
  /// model rather than left in whichever field it used to be in.
  void _resync() {
    for (final entry in _controllers.entries) {
      final parts = entry.key.split(':');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final text = row < 0 ? _table.header[col] : _table.cell(row, col);
      if (entry.value.text != text) entry.value.text = text;
    }
  }

  void _change(void Function() edit) {
    setState(() {
      edit();
      _pruneControllers();
      _resync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.mdTableBuilder),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.mdTableBuilderHelp,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _alignmentRow(l10n),
                    const SizedBox(height: 6),
                    _headerRow(l10n),
                    const SizedBox(height: 6),
                    for (var r = 0; r < _table.rowCount; r++) ...[
                      _bodyRow(l10n, r),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('md-table-add-row'),
                    onPressed: () => _change(_table.addRow),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.mdTableAddRow),
                  ),
                  OutlinedButton.icon(
                    key: const Key('md-table-add-column'),
                    onPressed: () => _change(_table.addColumn),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.mdTableAddColumn),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.mdTablePreview, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _table.toMarkdown(),
                    key: const Key('md-table-preview'),
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('md-table-insert'),
          onPressed: () => Navigator.of(context).pop(_table.toMarkdown()),
          child: Text(l10n.mdTableInsert),
        ),
      ],
    );
  }

  Widget _alignmentRow(AppLocalizations l10n) {
    return Row(
      children: [
        for (var c = 0; c < _table.columnCount; c++)
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<MdColumnAlign>(
                      value: _table.alignments[c],
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final align in MdColumnAlign.values)
                          DropdownMenuItem(
                            value: align,
                            child: Text(
                              _alignLabel(l10n, align),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _table.setAlignment(c, value));
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.mdTableRemoveColumn,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _table.columnCount <= 1
                        ? null
                        : () => _change(() => _table.removeColumn(c)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _headerRow(AppLocalizations l10n) {
    return Row(
      children: [
        for (var c = 0; c < _table.columnCount; c++)
          _cellField(
            row: -1,
            col: c,
            label: l10n.mdTableHeaderCell,
            bold: true,
          ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _bodyRow(AppLocalizations l10n, int row) {
    return Row(
      children: [
        for (var c = 0; c < _table.columnCount; c++)
          _cellField(row: row, col: c, label: null, bold: false),
        SizedBox(
          width: 40,
          child: IconButton(
            tooltip: l10n.mdTableRemoveRow,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => _change(() => _table.removeRow(row)),
          ),
        ),
      ],
    );
  }

  Widget _cellField({
    required int row,
    required int col,
    required String? label,
    required bool bold,
  }) {
    return SizedBox(
      width: 150,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: TextField(
          key: Key('md-table-cell-$row-$col'),
          controller: _controllerFor(row, col),
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onChanged: (value) => setState(() {
            if (row < 0) {
              _table.setHeader(col, value);
            } else {
              _table.setCell(row, col, value);
            }
          }),
        ),
      ),
    );
  }

  String _alignLabel(AppLocalizations l10n, MdColumnAlign align) {
    switch (align) {
      case MdColumnAlign.none:
        return l10n.mdTableAlignDefault;
      case MdColumnAlign.left:
        return l10n.mdTableAlignLeft;
      case MdColumnAlign.center:
        return l10n.mdTableAlignCenter;
      case MdColumnAlign.right:
        return l10n.mdTableAlignRight;
    }
  }
}
