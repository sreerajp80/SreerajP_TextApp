import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/sync/diff/live_diff_controller.dart';
import 'package:sreerajp_textapp/sync/sync_provider.dart';
import 'package:sreerajp_textapp/sync/ui/live_diff_screen.dart';

/// Tab in SyncHostScreen allowing the user to initiate a live diff & delta sync session.
class P2pLiveDiffTab extends ConsumerStatefulWidget {
  final SyncController controller;

  const P2pLiveDiffTab({super.key, required this.controller});

  @override
  ConsumerState<P2pLiveDiffTab> createState() => _P2pLiveDiffTabState();
}

class _P2pLiveDiffTabState extends ConsumerState<P2pLiveDiffTab> {
  String? _selectedFileName;
  String? _selectedMimeType;
  String? _selectedContent;

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

  Future<void> _startLiveDiff() async {
    final fileName = _selectedFileName;
    final mimeType = _selectedMimeType ?? 'text/plain';
    final content = _selectedContent;

    if (fileName == null || content == null) return;

    // Send the document offer to peer
    await widget.controller.pushLiveDiffDocument(
      fileName: fileName,
      mimeType: mimeType,
      content: content,
    );

    if (!mounted) return;

    // Open LiveDiffScreen on host
    final diffCtrl = LiveDiffController(
      documentName: fileName,
      mimeType: mimeType,
      mode: DiffSessionMode.p2pHost,
      initialLocalContent: content,
      initialRemoteContent: content,
      onSendPayload: widget.controller.pushLiveDiffPayload,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiveDiffScreen(controller: diffCtrl)),
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
                      Icons.difference_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'P2P Live Diff & Delta Sync',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Compare and merge CSV, JSON, MD, or TXT documents side-by-side with a peer over local Wi-Fi. Resolve conflicts without cloud servers.',
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
          'Select Document to Diff & Merge',
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
              subtitle: Text('$_selectedMimeType'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectedFileName = null;
                  _selectedContent = null;
                }),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: (!isConnected || _selectedFileName == null || isSending)
              ? null
              : _startLiveDiff,
          icon: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.compare_arrows),
          label: Text(
            isSending
                ? 'Connecting Diff Session...'
                : isConnected
                ? 'Start Live Diff Session'
                : 'Waiting for Peer Connection...',
          ),
        ),
      ],
    );
  }
}
