import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/vault/vault_crypto.dart';
import 'package:sreerajp_textapp/core/vault/vault_models.dart';
import 'package:sreerajp_textapp/core/vault/vault_providers.dart';
import 'package:sreerajp_textapp/formats/csv/csv_document_view.dart';
import 'package:sreerajp_textapp/formats/format_dispatch.dart';
import 'package:sreerajp_textapp/formats/json/json_document_view.dart';
import 'package:sreerajp_textapp/formats/markdown/md_document_view.dart';
import 'package:sreerajp_textapp/formats/txt/txt_document_view.dart';
import 'package:sreerajp_textapp/formats/xml/xml_document_view.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';

/// In-workspace unlock screen for `.txvault` encrypted files.
/// Prompts for biometric authentication before loading and rendering the inner document.
class VaultUnlockView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const VaultUnlockView({super.key, required this.tab});

  @override
  ConsumerState<VaultUnlockView> createState() => _VaultUnlockViewState();
}

class _VaultUnlockViewState extends ConsumerState<VaultUnlockView> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  VaultPayload? _unlockedPayload;

  Future<void> _unlock() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final saf = ref.read(safServiceProvider);
      final vaultService = ref.read(vaultServiceProvider);

      final fileBytes = await saf.readBytes(widget.tab.uri);
      final payload = await vaultService.unlockDocument(
        fileBytes: fileBytes,
        reason: 'Unlock ${widget.tab.displayName}',
      );

      if (mounted) {
        setState(() {
          _unlockedPayload = payload;
          _isAuthenticating = false;
        });
      }
    } on VaultCryptoException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not unlock document vault.';
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = _unlockedPayload;

    if (payload != null) {
      // Build a synthetic tab representing the inner document format
      final innerTab = DocumentTab(
        id: widget.tab.id,
        fingerprint: widget.tab.fingerprint,
        uri: widget.tab.uri,
        displayName: payload.originalFileName,
        mimeType: payload.mimeType,
        size: utf8.encode(payload.content).length,
        lastActiveAt: widget.tab.lastActiveAt,
      );

      final innerFormat = detectFormat(innerTab);
      return switch (innerFormat) {
        DocumentFormat.txt => TxtDocumentView(tab: innerTab),
        DocumentFormat.markdown => MdDocumentView(tab: innerTab),
        DocumentFormat.csv => CsvDocumentView(tab: innerTab),
        DocumentFormat.json => JsonDocumentView(tab: innerTab),
        DocumentFormat.xml => XmlDocumentView(tab: innerTab),
        _ => TxtDocumentView(tab: innerTab),
      };
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 38,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.tab.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Encrypted Biometric Vault Document',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Protected with AES-256-GCM hardware key encryption.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isAuthenticating ? null : _unlock,
                      icon: _isAuthenticating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(
                        _isAuthenticating
                            ? 'Authenticating...'
                            : 'Unlock Document',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
