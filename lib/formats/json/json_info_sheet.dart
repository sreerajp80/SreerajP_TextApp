import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../txt/txt_encoding_labels.dart';
import 'json_document_session.dart';
import 'json_node.dart';

/// A bottom sheet showing the JSON file's insights and metadata (task 8.6):
/// top-level type, item / key counts, depth, array sizes, a type breakdown, plus
/// size, dates, encoding, and line ending.
Future<void> showJsonInfoSheet(
    BuildContext context, JsonDocumentSession session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final stats = session.stats;
      final meta = session.metadata;

      final rows = <MapEntry<String, String>>[
        MapEntry(l10n.jsonInfoValid,
            session.isWellFormed ? l10n.commonYes : l10n.commonNo),
        if (stats != null) ...[
          MapEntry(l10n.jsonInfoTopType, stats.topLevelType.label),
          MapEntry(l10n.jsonInfoTopItems, '${stats.topLevelItemCount}'),
          MapEntry(l10n.jsonInfoKeys, '${stats.keyCount}'),
          MapEntry(l10n.xmlInfoMaxDepth, '${stats.maxDepth}'),
          MapEntry(l10n.jsonInfoArrays, '${stats.arrayCount}'),
          MapEntry(l10n.jsonInfoLargestArray, '${stats.largestArray}'),
          MapEntry(l10n.jsonInfoTypes, _typeBreakdown(stats.typeBreakdown)),
        ],
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

String _typeBreakdown(Map<JsonKind, int> breakdown) {
  if (breakdown.isEmpty) return '—';
  final parts = <String>[];
  for (final kind in JsonKind.values) {
    final count = breakdown[kind];
    if (count != null && count > 0) parts.add('${kind.label}: $count');
  }
  return parts.join(', ');
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
