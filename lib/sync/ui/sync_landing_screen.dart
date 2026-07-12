import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'sync_client_screen.dart';
import 'sync_host_screen.dart';

/// Entry point for P2P LAN sync: pick Send (host) or Receive (client).
///
/// Opened from the Home app bar. The full Settings "Sync" section is Phase 11.
class SyncLandingScreen extends StatelessWidget {
  const SyncLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.syncIntro,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.send),
              title: Text(l10n.syncSend),
              subtitle: Text(l10n.syncSendSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SyncHostScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: Text(l10n.syncReceive),
              subtitle: Text(l10n.syncReceiveSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SyncClientScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
