import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../sync_constants.dart';

/// "Choose what to share" panel (arch §9.6, host tab 2).
///
/// A **Full Sync** action for a fresh device, plus a selective section with
/// per-category checkboxes and an optional settings checkbox. All actions are
/// disabled until a device is [connected]. Standalone and callback-driven so it
/// is easy to test the gating.
class ShareChooser extends StatefulWidget {
  final bool connected;
  final bool sending;
  final void Function() onFullSync;
  final void Function(List<String> categories, bool includeSettings) onSelective;

  /// Categories pre-checked when the panel opens (task 11.5). Defaults to every
  /// category when null. Always narrowed to the known categories.
  final Set<String>? initialCategories;

  const ShareChooser({
    super.key,
    required this.connected,
    required this.sending,
    required this.onFullSync,
    required this.onSelective,
    this.initialCategories,
  });

  @override
  State<ShareChooser> createState() => _ShareChooserState();
}

class _ShareChooserState extends State<ShareChooser> {
  late final Set<String> _selected = {
    for (final c in SyncConstants.allCategories)
      if (widget.initialCategories == null ||
          widget.initialCategories!.contains(c))
        c,
  };
  bool _includeSettings = true;

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
    final enabled = widget.connected && !widget.sending;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.syncFreshDevice, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.syncFreshDeviceBody,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: enabled ? widget.onFullSync : null,
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.syncFullSync),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.syncChooseWhatToShare,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final category in SyncConstants.allCategories)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_label(l10n, category)),
                    value: _selected.contains(category),
                    onChanged: enabled
                        ? (v) => setState(() {
                              if (v == true) {
                                _selected.add(category);
                              } else {
                                _selected.remove(category);
                              }
                            })
                        : null,
                  ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.syncDisplaySettings),
                  value: _includeSettings,
                  onChanged: enabled
                      ? (v) => setState(() => _includeSettings = v == true)
                      : null,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.syncWontOverride,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: enabled && _selected.isNotEmpty
                      ? () => widget.onSelective(
                            _selected.toList(growable: false),
                            _includeSettings,
                          )
                      : null,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(l10n.syncSendSelected),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
