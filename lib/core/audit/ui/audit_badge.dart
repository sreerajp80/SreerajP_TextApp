/// A compact status chip showing the audit chain verification state (Feature 8).
///
/// Shows a green checkmark with "Chain Verified" or a red warning with
/// "Chain Corrupted" (or grey "Empty" if no entries). Used in the Settings
/// audit section and on the audit log screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/audit/audit_models.dart';
import 'package:text_data/core/audit/audit_providers.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// Displays a compact chip reflecting the current chain verification status.
class AuditBadge extends ConsumerWidget {
  const AuditBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStatus = ref.watch(auditChainStatusProvider);
    final l10n = AppLocalizations.of(context);

    return asyncStatus.when(
      data: (result) => _buildChip(context, l10n, result),
      loading: () => _chip(
        context,
        icon: Icons.hourglass_empty,
        label: l10n.auditBadgeVerifying,
        color: Theme.of(context).colorScheme.outline,
      ),
      error: (_, _) => _chip(
        context,
        icon: Icons.error_outline,
        label: l10n.auditBadgeError,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    AppLocalizations l10n,
    AuditVerificationResult result,
  ) {
    switch (result.status) {
      case AuditChainStatus.verified:
        return _chip(
          context,
          icon: Icons.verified,
          label: l10n.auditBadgeVerified,
          color: Colors.green,
        );
      case AuditChainStatus.corrupted:
        return _chip(
          context,
          icon: Icons.warning_amber_rounded,
          label: l10n.auditBadgeCorrupted,
          color: Theme.of(context).colorScheme.error,
        );
      case AuditChainStatus.empty:
        return _chip(
          context,
          icon: Icons.remove_circle_outline,
          label: l10n.auditBadgeEmpty,
          color: Theme.of(context).colorScheme.outline,
        );
    }
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withAlpha(80)),
      backgroundColor: color.withAlpha(20),
    );
  }
}
