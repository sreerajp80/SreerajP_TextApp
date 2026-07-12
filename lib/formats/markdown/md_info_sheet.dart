import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../txt/txt_encoding_labels.dart';
import 'md_document_session.dart';

/// A bottom sheet showing the Markdown file's stats and metadata (task 6.5):
/// word / heading / link counts plus front-matter fields, size, dates, encoding,
/// and line ending.
Future<void> showMdInfoSheet(BuildContext context, MdDocumentSession session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final stats = session.stats;
      final meta = session.metadata;
      final fm = session.frontMatter;

      final rows = <MapEntry<String, String>>[
        MapEntry(l10n.mdInfoWords, '${stats.words}'),
        MapEntry(l10n.mdInfoHeadings, '${stats.headings}'),
        MapEntry(l10n.mdInfoLinks, '${stats.links}'),
        MapEntry(l10n.mdInfoLines, '${stats.lines}'),
        if (fm.title != null) MapEntry(l10n.mdInfoTitleField, fm.title!),
        if (fm.author != null) MapEntry(l10n.mdInfoAuthorField, fm.author!),
        if (fm.tags.isNotEmpty) MapEntry(l10n.mdInfoTags, fm.tags.join(', ')),
        if (meta != null) ...[
          MapEntry(l10n.labelEncoding, session.encoding.label),
          MapEntry(l10n.labelLineEnding, session.lineEnding.label),
          if (meta.size != null)
            MapEntry(l10n.infoSize, _formatBytes(meta.size!)),
          if (meta.modifiedAt != null)
            MapEntry(l10n.infoModified, _formatDate(meta.modifiedAt!)),
        ],
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.infoTitle,
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
