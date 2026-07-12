import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../sync_transport.dart';

/// A live status chip for the host's connection state (arch §9.6).
///
/// Standalone (takes a plain [HostPhase]) so it is easy to test and reuse.
class SyncStatusChip extends StatelessWidget {
  final HostPhase phase;

  const SyncStatusChip({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final (label, icon, color) = switch (phase) {
      HostPhase.listening => (l10n.syncStatusWaiting, Icons.wifi_tethering, scheme.tertiary),
      HostPhase.connected => (l10n.syncStatusConnected, Icons.check_circle, scheme.primary),
      HostPhase.denied => (l10n.syncStatusWrongCode, Icons.error_outline, scheme.error),
      HostPhase.error => (l10n.syncStatusError, Icons.error_outline, scheme.error),
      HostPhase.stopped => (l10n.syncStatusStopped, Icons.stop_circle_outlined, scheme.outline),
    };
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}
