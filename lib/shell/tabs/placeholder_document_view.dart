import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'document_tab.dart';

/// Temporary body shown inside a tab until the real per-format viewer/editor
/// lands (Phase 3 gives the editor core, Phase 4 the first TXT viewer).
///
/// It shows the file's details so the tab is clearly "the right file", and makes
/// the workspace usable and testable now without any format code.
class PlaceholderDocumentView extends StatelessWidget {
  final DocumentTab tab;

  const PlaceholderDocumentView({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              tab.displayName,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _details(l10n),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.placeholderComingSoon,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _details(AppLocalizations l10n) {
    final parts = <String>[
      if (tab.mimeType != null) tab.mimeType!,
      if (tab.size != null) _formatBytes(tab.size!),
    ];
    return parts.isEmpty ? l10n.placeholderOpenedFile : parts.join('  ·  ');
  }

  static String _formatBytes(int bytes) {
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
}
