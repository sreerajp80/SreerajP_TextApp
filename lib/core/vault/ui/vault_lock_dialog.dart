import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/vault/vault_constants.dart';
import 'package:sreerajp_textapp/core/vault/vault_crypto.dart';
import 'package:sreerajp_textapp/core/vault/vault_models.dart';
import 'package:sreerajp_textapp/core/vault/vault_providers.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';

/// Shows a dialog allowing the user to lock the current document in a Biometric Vault (.txvault).
Future<void> showVaultLockDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DocumentTab tab,
  required String content,
  String encoding = 'utf-8',
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.shield_outlined),
          const SizedBox(width: 8),
          Text(l10n.vaultLockAction),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.vaultLockBody(tab.displayName)),
          const SizedBox(height: 12),
          Text(l10n.vaultLockNote, style: const TextStyle(fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          icon: const Icon(Icons.fingerprint),
          label: Text(l10n.vaultEncryptAndSave),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final vaultService = ref.read(vaultServiceProvider);
    final saf = ref.read(safServiceProvider);

    final payload = VaultPayload(
      originalFileName: tab.displayName,
      mimeType: tab.mimeType ?? 'text/plain',
      encoding: encoding,
      content: content,
      createdAt: DateTime.now(),
    );

    final encryptedBytes = await vaultService.lockDocument(
      payload: payload,
      reason: l10n.vaultBiometricReason(tab.displayName),
    );

    final suggestedName = tab.displayName.endsWith('.txvault')
        ? tab.displayName
        : '${tab.displayName}.txvault';

    final destFile = await saf.createDocument(
      suggestedName: suggestedName,
      bytes: encryptedBytes,
      mimeType: VaultConstants.mimeType,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.vaultSavedAs(destFile.displayName)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } on SafCancelled {
    // User backed out of SAF picker
  } on VaultCryptoException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.vaultSaveFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
