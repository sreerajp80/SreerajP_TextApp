import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Shows the tables and columns the query engine holds (Feature 4).
///
/// The user should never have to guess a name, so every table and column is on
/// screen and tapping one drops it into the SQL box. A column whose header had
/// to be repaired (blank, or repeated) says what it used to be, so a name that
/// does not match the file is never a surprise.
class SqlSchemaPanel extends StatelessWidget {
  final List<SqlDataset> datasets;

  /// Called with the text to insert when a table or column chip is tapped.
  final ValueChanged<String> onInsert;

  /// Removes an added table. Null for the document's own table, which cannot be
  /// removed.
  final void Function(SqlDataset dataset)? onRemove;

  const SqlSchemaPanel({
    super.key,
    required this.datasets,
    required this.onInsert,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < datasets.length; i++) ...[
          _table(context, theme, l10n, datasets[i], removable: i > 0),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.sqlReadOnlyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.sqlSnapshotNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _table(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SqlDataset dataset, {
    required bool removable,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataset.tableName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      Text(
                        dataset.sourceLabel,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.sqlTableSummary(dataset.rowCount, dataset.columnCount),
                  style: theme.textTheme.bodySmall,
                ),
                if (removable && onRemove != null)
                  IconButton(
                    tooltip: l10n.sqlRemoveTable,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemove!(dataset),
                  ),
              ],
            ),
            if (dataset.truncated)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.sqlRowsCapped(dataset.rowCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final column in dataset.columns)
                  _ColumnChip(
                    column: column,
                    onTap: () => onInsert(column.quotedName),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnChip extends StatelessWidget {
  final SqlColumn column;
  final VoidCallback onTap;

  const _ColumnChip({required this.column, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final renamed = column.wasRenamed;
    final original = column.sourceName.trim().isEmpty
        ? l10n.sqlColumnBlankName
        : column.sourceName;

    return ActionChip(
      onPressed: onTap,
      avatar: Icon(_iconFor(column.type), size: 16),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(column.name, style: theme.textTheme.labelMedium),
          if (renamed)
            Text(
              l10n.sqlColumnRenamed(original),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(SqlColumnType type) {
    switch (type) {
      case SqlColumnType.real:
        return Icons.numbers;
      case SqlColumnType.integer:
        return Icons.toggle_on_outlined;
      case SqlColumnType.text:
        return Icons.abc;
    }
  }
}
