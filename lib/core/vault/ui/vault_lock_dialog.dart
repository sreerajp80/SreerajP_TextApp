import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/vault/vault_constants.dart';
import 'package:text_data/core/vault/vault_crypto.dart';
import 'package:text_data/core/vault/vault_models.dart';
import 'package:text_data/core/vault/vault_providers.dart';
import 'package:text_data/shell/tabs/document_tab.dart';

/// Shows a dialog allowing the user to lock the current document in a Biometric Vault (.txvault).
Future<void> showVaultLockDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DocumentTab tab,
  required String content,
  String encoding = 'utf-8',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.shield_outlined),
          SizedBox(width: 8),
          Text('Lock in Biometric Vault'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encrypt "${tab.displayName}" using AES-256-GCM hardware key encryption.',
          ),
          const SizedBox(height: 12),
          const Text(
            'The resulting .txvault file can only be decrypted and read by this app using your fingerprint or device biometrics.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          icon: const Icon(Icons.fingerprint),
          label: const Text('Encrypt & Save'),
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
      reason: 'Lock ${tab.displayName} in Biometric Vault',
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
          content: Text('Encrypted vault saved as "${destFile.displayName}"'),
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
          content: const Text('Could not save encrypted vault file.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
