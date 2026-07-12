import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../txt/txt_encoding_labels.dart';
import 'xml_document_session.dart';

/// A bottom sheet showing the XML file's insights and metadata (task 9.6):
/// root element, element count, depth, most-common tags, namespaces, plus size,
/// dates, encoding, and line ending.
Future<void> showXmlInfoSheet(
    BuildContext context, XmlDocumentSession session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final stats = session.stats;
      final meta = session.metadata;
      final ns = session.namespaces;

      final rows = <MapEntry<String, String>>[
        MapEntry(l10n.xmlInfoWellFormed,
            session.isWellFormed ? l10n.commonYes : l10n.commonNo),
        if (stats != null) ...[
          MapEntry(l10n.xmlInfoRoot, stats.rootElement ?? '—'),
          MapEntry(l10n.xmlInfoElements, '${stats.elementCount}'),
          MapEntry(l10n.xmlInfoMaxDepth, '${stats.maxDepth}'),
          MapEntry(l10n.xmlInfoAttributes, '${stats.attributeCount}'),
          MapEntry(l10n.xmlInfoCommonTags, _commonTags(stats.mostCommonTags)),
        ],
        if (ns.isNotEmpty) MapEntry(l10n.xmlInfoNamespaces, ns.join(', ')),
        if (meta != null) ...[
          MapEntry(l10n.labelEncoding, session.encoding.label),
          MapEntry(l10n.labelLineEnding, session.lineEnding.label),
          if (meta.size != null) MapEntry(l10n.infoSize, _formatBytes(meta.size!)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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

String _commonTags(List<MapEntry<String, int>> tags) {
  if (tags.isEmpty) return '—';
  return tags.take(5).map((e) => '${e.key} (${e.value})').join(', ');
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
