import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/airqr/ui/airqr_landing_screen.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/sync/sync_constants.dart';
import 'package:sreerajp_textapp/sync/sync_share_prefs.dart';
import 'package:sreerajp_textapp/sync/ui/sync_landing_screen.dart';
import 'package:sreerajp_textapp/shell/settings/sections/settings_widgets.dart';

/// Sync settings (task 11.5). Lets the user choose which record categories are
/// pre-checked when they share, opens the sync flow, and states plainly that no
/// security or identity data is ever shared (security-rules).
class SyncSection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const SyncSection({super.key, this.showHeader = true});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(syncSharePrefsProvider);
    final controller = ref.read(syncSharePrefsProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SettingsSectionHeader(title: l10n.syncSectionTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.syncDefaultCategories,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        for (final category in SyncConstants.allCategories)
          SwitchListTile(
            dense: true,
            title: Text(_label(l10n, category)),
            value: prefs.isEnabled(category),
            onChanged: (v) => controller.setEnabled(category, v),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l10n.syncLocalNote, style: theme.textTheme.bodySmall),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SyncLandingScreen()),
            ),
            icon: const Icon(Icons.sync),
            label: Text(l10n.syncOpenSync),
          ),
        ),
        // Optical transfer sits next to LAN sync because it answers the same
        // question — "get this onto the other device" — for places where even
        // LAN traffic is not allowed.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AirqrLandingScreen()),
            ),
            icon: const Icon(Icons.qr_code_2),
            label: Text(l10n.airqrTitle),
          ),
        ),
      ],
    );
  }
}
