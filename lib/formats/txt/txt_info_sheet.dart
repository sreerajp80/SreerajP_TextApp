import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'txt_document_session.dart';
import 'txt_encoding_labels.dart';

/// A bottom sheet showing the file's stats and metadata (task 4.3): word /
/// character / line counts plus size, dates, encoding, and line ending.
Future<void> showInfoSheet(BuildContext context, TxtDocumentSession session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final stats = session.stats;
      final meta = session.metadata;
      final rows = <MapEntry<String, String>>[
        MapEntry(l10n.txtInfoWords, '${stats.words}'),
        MapEntry(l10n.txtInfoCharacters, '${stats.characters}'),
        MapEntry(l10n.txtInfoCharactersNoLineBreaks, '${stats.charactersNoLineBreaks}'),
        MapEntry(l10n.txtInfoLines, '${stats.lines}'),
        if (meta != null) ...[
          MapEntry(l10n.txtEncoding, session.encoding.label),
          MapEntry(l10n.txtLineEnding, session.lineEnding.label),
          if (meta.size != null) MapEntry(l10n.txtInfoSize, _formatBytes(meta.size!)),
          if (meta.modifiedAt != null)
            MapEntry(l10n.txtInfoModified, _formatDate(meta.modifiedAt!)),
        ],
      ];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.txtInfoTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.key)),
                      Text(
                        row.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
