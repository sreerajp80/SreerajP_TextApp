import 'package:flutter/material.dart';

import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/formats/csv/csv_document_session.dart';
import 'package:text_data/formats/csv/csv_filter_sort.dart';

/// A sheet to build a multi-level sort (roadmap §4.2.1), e.g. "Department
/// ascending, then Salary descending".
///
/// The levels are edited in a working copy and only handed to the session when
/// the user applies them, so a half-built hierarchy never reshuffles the grid
/// underneath them.
Future<void> showCsvSortSheet(
  BuildContext context,
  CsvDocumentSession session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _SortBody(session: session, scrollController: controller),
    ),
  );
}

class _SortBody extends StatefulWidget {
  final CsvDocumentSession session;
  final ScrollController scrollController;

  const _SortBody({required this.session, required this.scrollController});

  @override
  State<_SortBody> createState() => _SortBodyState();
}

class _SortBodyState extends State<_SortBody> {
  late final List<CsvSortSpec> _levels = List<CsvSortSpec>.from(
    widget.session.sortSpecs,
  );

  int get _columnCount => widget.session.table.columnCount;

  /// The first column not already used by a level, so a new level starts on
  /// something useful instead of repeating one.
  int get _nextFreeColumn {
    final used = _levels.map((l) => l.column).toSet();
    for (var c = 0; c < _columnCount; c++) {
      if (!used.contains(c)) return c;
    }
    return 0;
  }

  String _columnName(int col) {
    final header = widget.session.table.header;
    final l10n = AppLocalizations.of(context);
    if (col < 0 || col >= header.length) return l10n.csvColumnN(col + 1);
    return header[col].isEmpty ? l10n.csvColumnN(col + 1) : header[col];
  }

  void _apply() {
    widget.session.setSortSpecs(_levels);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (_columnCount == 0) {
      return Center(child: Text(l10n.csvNoColumns));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.csvSortLevels,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (_levels.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_levels.clear),
                  child: Text(l10n.csvSortClear),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (_levels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.csvSortNoLevels,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (var i = 0; i < _levels.length; i++) _level(l10n, i),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _levels.length >= _columnCount
                    ? null
                    : () => setState(
                        () => _levels.add(
                          CsvSortSpec(_nextFreeColumn, SortDirection.ascending),
                        ),
                      ),
                icon: const Icon(Icons.add),
                label: Text(l10n.csvSortAddLevel),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('csv-sort-apply'),
                onPressed: _apply,
                child: Text(l10n.csvSortApply),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _level(AppLocalizations l10n, int index) {
    final level = _levels[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    index == 0 ? l10n.csvSortFirstBy : l10n.csvSortThenBy,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.csvSortMoveUp,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: index == 0
                      ? null
                      : () => setState(() {
                          final moved = _levels.removeAt(index);
                          _levels.insert(index - 1, moved);
                        }),
                ),
                IconButton(
                  tooltip: l10n.csvSortMoveDown,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: index == _levels.length - 1
                      ? null
                      : () => setState(() {
                          final moved = _levels.removeAt(index);
                          _levels.insert(index + 1, moved);
                        }),
                ),
                IconButton(
                  tooltip: l10n.actionRemove,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _levels.removeAt(index)),
                ),
              ],
            ),
            DropdownButtonFormField<int>(
              initialValue: level.column,
              decoration: InputDecoration(
                labelText: l10n.csvColumnLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (var c = 0; c < _columnCount; c++)
                  DropdownMenuItem(
                    value: c,
                    child: Text(
                      _columnName(c),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(
                  () => _levels[index] = CsvSortSpec(value, level.direction),
                );
              },
            ),
            const SizedBox(height: 8),
            SegmentedButton<SortDirection>(
              segments: [
                ButtonSegment(
                  value: SortDirection.ascending,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: Text(l10n.csvSortAscending),
                ),
                ButtonSegment(
                  value: SortDirection.descending,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(l10n.csvSortDescending),
                ),
              ],
              selected: {level.direction},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(
                () =>
                    _levels[index] = CsvSortSpec(level.column, selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
