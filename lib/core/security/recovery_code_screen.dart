import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'app_lock_hasher.dart';

/// Shows a freshly generated recovery code **once** so the user can write it
/// down. The app stores only a hash, so this is the only time the code is
/// visible. Used after enabling app-lock and after a recovery/reset (task 13.2).
class RecoveryCodeScreen extends StatelessWidget {
  final String code;

  const RecoveryCodeScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final formatted = AppLockHasher.formatRecoveryCode(code);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recoveryTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.recoveryBody,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                formatted,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l10n.actionCopy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formatted));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.recoveryCopied),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.recoverySaved),
          ),
        ],
      ),
    );
  }
}
