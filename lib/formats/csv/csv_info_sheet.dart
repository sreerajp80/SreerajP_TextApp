import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../txt/txt_encoding_labels.dart';
import 'csv_dialect.dart';
import 'csv_document_session.dart';

/// A bottom sheet showing the CSV file's metadata (task 7.6): row / column
/// counts, delimiter, whether it has a header, encoding, line ending, size, and
/// modified date.
Future<void> showCsvInfoSheet(BuildContext context, CsvDocumentSession session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final table = session.table;
      final meta = session.metadata;

      final rows = <MapEntry<String, String>>[
        MapEntry(l10n.csvInfoRows, '${table.rowCount}'),
        MapEntry(l10n.csvInfoColumns, '${table.columnCount}'),
        MapEntry(l10n.csvInfoDelimiter, session.dialect.delimiter.label),
        MapEntry(l10n.csvInfoHeaderRow,
            session.dialect.hasHeader ? l10n.csvYes : l10n.csvNo),
        MapEntry(l10n.csvInfoEncoding, session.encoding.label),
        MapEntry(l10n.csvInfoLineEnding, session.lineEnding.label),
        if (meta != null) ...[
          if (meta.size != null)
            MapEntry(l10n.csvInfoSize, _formatBytes(meta.size!)),
          if (meta.modifiedAt != null)
            MapEntry(l10n.csvInfoModified, _formatDate(meta.modifiedAt!)),
        ],
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.csvInfoTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.key)),
                      Flexible(
                        child: Text(
                          row.value,
                          textAlign: TextAlign.right,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  double value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
