import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/airqr/ui/airqr_receive_action.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Entry point for optical air-gap transfer: explain what it is, then send or
/// receive.
///
/// Only *receive* starts from here. Sending always begins from the thing being
/// sent — a document tab or a text selection — because there is nothing to send
/// without one.
class AirqrLandingScreen extends ConsumerWidget {
  const AirqrLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.airqrTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.airqrIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(l10n.airqrReceive),
              subtitle: Text(l10n.airqrReceiveSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AirqrReceiveAction(ref).receive(context),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.send_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.airqrHowToSend,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.airqrHowToSendBody,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.airqrSpeedNoteTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.airqrSpeedNoteBody,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
