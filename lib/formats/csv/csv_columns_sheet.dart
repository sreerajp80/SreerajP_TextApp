import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'csv_document_session.dart';

/// A bottom sheet for table options (task 7.2): freeze header / first column,
/// treat the first row as a header, and show / hide individual columns.
Future<void> showCsvColumnsSheet(
  BuildContext context,
  CsvDocumentSession session, {
  required bool editable,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          final table = session.table;
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(l10n.csvColumnsView,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              SwitchListTile(
                title: Text(l10n.csvFreezeHeader),
                value: session.freezeHeader,
                onChanged: (_) => session.toggleFreezeHeader(),
              ),
              SwitchListTile(
                title: Text(l10n.csvFreezeFirstColumn),
                value: session.freezeFirstColumn,
                onChanged: (_) => session.toggleFreezeFirstColumn(),
              ),
              SwitchListTile(
                title: Text(l10n.csvFirstRowHeader),
                value: session.dialect.hasHeader,
                onChanged:
                    editable ? (value) => session.setHasHeader(value) : null,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Text(l10n.csvShowColumns,
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              for (var c = 0; c < table.columnCount; c++)
                CheckboxListTile(
                  dense: true,
                  title: Text(
                    table.header[c].isEmpty
                        ? l10n.csvColumnN(c + 1)
                        : table.header[c],
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: !session.hiddenColumns.contains(c),
                  onChanged: (visible) =>
                      session.setColumnHidden(c, !(visible ?? true)),
                ),
            ],
          );
        },
      ),
    ),
  );
}
