import 'package:flutter/material.dart';
import 'package:text_data/sync/diff/diff_models.dart';
import 'package:text_data/sync/diff/live_diff_controller.dart';

/// Renders tabular CSV cell-by-cell and row-by-row diffs with interactive merge switches.
class CsvDiffView extends StatelessWidget {
  final LiveDiffController controller;

  const CsvDiffView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final csvDiff = controller.csvDiff;
    final theme = Theme.of(context);

    if (csvDiff == null || csvDiff.rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No CSV data to compare.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: csvDiff.rows.length,
      itemBuilder: (context, index) {
        final rowDiff = csvDiff.rows[index];
        return _CsvRowCard(
          controller: controller,
          rowDiff: rowDiff,
          headers: csvDiff.headers,
          theme: theme,
        );
      },
    );
  }
}

class _CsvRowCard extends StatelessWidget {
  final LiveDiffController controller;
  final CsvRowDiff rowDiff;
  final List<String> headers;
  final ThemeData theme;

  const _CsvRowCard({
    required this.controller,
    required this.rowDiff,
    required this.headers,
    required this.theme,
  });

  Color _getRowColor() {
    switch (rowDiff.type) {
      case DiffType.added:
        return Colors.green.withValues(alpha: 0.12);
      case DiffType.deleted:
        return Colors.red.withValues(alpha: 0.12);
      case DiffType.modified:
        return Colors.amber.withValues(alpha: 0.12);
      case DiffType.unchanged:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: rowDiff.isChanged
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: rowDiff.isChanged
          ? _getRowColor()
          : (isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  )
                : theme.colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  rowDiff.type == DiffType.added
                      ? Icons.add_circle_outline
                      : rowDiff.type == DiffType.deleted
                      ? Icons.remove_circle_outline
                      : rowDiff.type == DiffType.modified
                      ? Icons.change_circle_outlined
                      : Icons.check_circle_outline,
                  size: 16,
                  color: rowDiff.type == DiffType.added
                      ? Colors.green
                      : rowDiff.type == DiffType.deleted
                      ? Colors.red
                      : rowDiff.type == DiffType.modified
                      ? Colors.amber[800]
                      : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Row ${(rowDiff.localRowIndex ?? rowDiff.remoteRowIndex ?? 0) + 1} · ${rowDiff.type.name.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (rowDiff.isChanged)
                  Wrap(
                    spacing: 4,
                    children: [
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('← Mine'),
                        selected:
                            rowDiff.resolution == HunkResolution.acceptLocal,
                        onSelected: (_) => controller.resolveCsvRow(
                          rowDiff.id,
                          HunkResolution.acceptLocal,
                        ),
                      ),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Peer →'),
                        selected:
                            rowDiff.resolution == HunkResolution.acceptRemote,
                        onSelected: (_) => controller.resolveCsvRow(
                          rowDiff.id,
                          HunkResolution.acceptRemote,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 28,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 48,
                columnSpacing: 16,
                horizontalMargin: 8,
                columns: headers
                    .map(
                      (h) => DataColumn(
                        label: Text(
                          h,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: [
                  DataRow(
                    cells: rowDiff.cells.map((cell) {
                      return DataCell(_CellContent(cell: cell, theme: theme));
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CellContent extends StatelessWidget {
  final CsvCellDiff cell;
  final ThemeData theme;

  const _CellContent({required this.cell, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (!cell.isChanged) {
      return Text(
        cell.localValue,
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (cell.localValue.isNotEmpty)
          Text(
            'Mine: ${cell.localValue}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red[700],
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        if (cell.remoteValue.isNotEmpty)
          Text(
            'Peer: ${cell.remoteValue}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}
