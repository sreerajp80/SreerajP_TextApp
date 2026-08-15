/// Audit Log settings section (Feature 8).
///
/// Shows the enable/disable toggle, chain verification badge, and action tiles
/// for viewing the log, exporting a certificate, and clearing the log.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/audit/audit_providers.dart';
import 'package:text_data/core/audit/audit_settings.dart';
import 'package:text_data/core/audit/ui/audit_badge.dart';
import 'package:text_data/core/audit/ui/audit_log_screen.dart';
import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/shell/settings/sections/settings_widgets.dart';

/// The "Audit Log" section in Settings.
class AuditSection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const AuditSection({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(auditEnabledProvider);
    final settings = ref.read(auditEnabledProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SettingsSectionHeader(title: l10n.auditSectionTitle),

        // On/off toggle.
        SwitchListTile(
          title: Text(l10n.auditEnableTitle),
          subtitle: Text(l10n.auditEnableSubtitle),
          value: enabled,
          onChanged: settings.setEnabled,
        ),

        // Chain verification badge.
        if (enabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  l10n.auditChainStatusLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                const AuditBadge(),
              ],
            ),
          ),

          // View full log.
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(l10n.auditViewLogTitle),
            subtitle: _EntryCountSubtitle(),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
          ),

          // Clear log.
          ListTile(
            leading: Icon(
              Icons.delete_sweep,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.auditClearAction,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: Text(l10n.auditClearSubtitle),
            onTap: () => _clearLog(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _clearLog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.auditClearTitle),
        content: Text(l10n.auditClearConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.auditClearAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = await ref.read(auditServiceProvider.future);
      await service.clearLog();
      ref.invalidate(auditChainStatusProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.auditClearSuccess)));
      }
    } catch (_) {
      // Best effort.
    }
  }
}

/// Shows the entry count as a subtitle on the "View Audit Log" tile.
class _EntryCountSubtitle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncService = ref.watch(auditServiceProvider);
    final l10n = AppLocalizations.of(context);

    return asyncService.when(
      data: (service) => FutureBuilder<int>(
        future: service.entryCount(),
        builder: (ctx, snap) {
          if (snap.hasData) {
            return Text(l10n.auditEntryCount(snap.data!));
          }
          return const SizedBox.shrink();
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
