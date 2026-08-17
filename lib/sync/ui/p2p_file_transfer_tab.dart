import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/sync/sync_provider.dart';

/// Tab in SyncHostScreen allowing the user to select and stream a full document file
/// directly to the connected P2P client over local sockets.
class P2pFileTransferTab extends ConsumerStatefulWidget {
  final SyncController controller;

  const P2pFileTransferTab({super.key, required this.controller});

  @override
  ConsumerState<P2pFileTransferTab> createState() => _P2pFileTransferTabState();
}

class _P2pFileTransferTabState extends ConsumerState<P2pFileTransferTab> {
  String? _selectedFileName;
  String? _selectedMimeType;
  String? _selectedContent;
  int? _selectedSizeBytes;

  Future<void> _pickFileFromStorage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final saf = ref.read(safServiceProvider);
      final file = await saf.pickFile();
      final bytes = await saf.readBytes(file.uri);
      final text = utf8.decode(bytes, allowMalformed: true);

      setState(() {
        _selectedFileName = file.displayName;
        _selectedMimeType = file.mimeType ?? 'text/plain';
        _selectedContent = text;
        _selectedSizeBytes = bytes.length;
      });
    } on SafCancelled {
      // User cancelled picker
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.p2pReadFileFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _selectOpenTab(DocumentTab tab) async {
    final l10n = AppLocalizations.of(context);
    try {
      final saf = ref.read(safServiceProvider);
      final bytes = await saf.readBytes(tab.uri);
      final text = utf8.decode(bytes, allowMalformed: true);

      setState(() {
        _selectedFileName = tab.displayName;
        _selectedMimeType = tab.mimeType ?? 'text/plain';
        _selectedContent = text;
        _selectedSizeBytes = bytes.length;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.p2pReadTabFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _send() async {
    final fileName = _selectedFileName;
    final mimeType = _selectedMimeType ?? 'text/plain';
    final content = _selectedContent;

    if (fileName == null || content == null) return;

    await widget.controller.pushDocumentFile(
      fileName: fileName,
      mimeType: mimeType,
      content: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tabsState = ref.watch(tabsControllerProvider);
    final isConnected = widget.controller.hostConnected;
    final isSending = widget.controller.isSending;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.file_present_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'P2P Direct File Transfer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Stream an entire document (up to 50 MB) directly to your connected peer with AES-256-GCM encryption.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select File to Send',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickFileFromStorage,
          icon: const Icon(Icons.folder_open),
          label: Text(l10n.p2pPickFromStorage),
        ),
        if (tabsState.tabs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Or Choose from Open Tabs:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tabsState.tabs.map((t) {
              final isChosen = _selectedFileName == t.displayName;
              return ChoiceChip(
                label: Text(t.displayName),
                selected: isChosen,
                onSelected: (_) => _selectOpenTab(t),
              );
            }).toList(),
          ),
        ],
        if (_selectedFileName != null) ...[
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(_selectedFileName!),
              subtitle: Text(
                '${(_selectedSizeBytes ?? 0) / 1024 > 1024 ? '${((_selectedSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB' : '${((_selectedSizeBytes ?? 0) / 1024).toStringAsFixed(1)} KB'} • $_selectedMimeType',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectedFileName = null;
                  _selectedContent = null;
                  _selectedSizeBytes = null;
                }),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: (!isConnected || _selectedFileName == null || isSending)
              ? null
              : _send,
          icon: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_to_mobile),
          label: Text(
            isSending
                ? 'Streaming File...'
                : isConnected
                ? 'Send File to Peer'
                : 'Waiting for Peer Connection...',
          ),
        ),
      ],
    );
  }
}
