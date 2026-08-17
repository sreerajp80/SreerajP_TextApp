import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/core/sql/sql_source.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Picks another open document to load as a second SQL table, which is what
/// makes `JOIN` useful (Feature 4).
///
/// Only CSV and JSON tabs appear, because only those have rows and columns. The
/// list is supplied by the formats layer, so this sheet does not know what a CSV
/// is.
Future<SqlSource?> showSqlSourcePicker(
  BuildContext context,
  List<SqlSource> sources,
) {
  return showModalBottomSheet<SqlSource>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.sqlAddTableTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (sources.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(
                  l10n.sqlAddTableEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final source in sources)
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(
                  source.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  source.suggestedTableName,
                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                ),
                onTap: () => Navigator.of(context).pop(source),
              ),
          ],
        ),
      );
    },
  );
}
