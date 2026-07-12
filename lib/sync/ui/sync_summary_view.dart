import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../sync_constants.dart';
import '../sync_provider.dart';

/// Shows the "added / kept / applied" summary after a client import
/// (arch §9.6). Standalone so it is easy to test with a made-up [SyncSummary].
class SyncSummaryView extends StatelessWidget {
  final SyncSummary summary;

  const SyncSummaryView({super.key, required this.summary});

  static String _label(AppLocalizations l10n, String category) {
    switch (category) {
      case SyncConstants.categoryFavorites:
        return l10n.syncCatFavorites;
      case SyncConstants.categoryBookmarks:
        return l10n.syncCatBookmarks;
      case SyncConstants.categoryRecents:
        return l10n.syncCatRecents;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 56),
        const SizedBox(height: 8),
        Center(
          child: Text(l10n.syncComplete, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            l10n.syncAddedKept(summary.totalAdded, summary.totalKept),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in summary.records.entries)
          ListTile(
            dense: true,
            leading: const Icon(Icons.folder_outlined),
            title: Text(_label(l10n, entry.key)),
            trailing: Text(
              l10n.syncAddedKept(entry.value.added, entry.value.kept),
            ),
          ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.tune),
          title: Text(l10n.syncDisplaySettings),
          trailing: Text(
            l10n.syncAppliedKept(summary.settings.applied, summary.settings.kept),
          ),
        ),
      ],
    );
  }
}
