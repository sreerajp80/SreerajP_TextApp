import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/sync/diff/diff_payload.dart';
import 'package:sreerajp_textapp/sync/diff/live_diff_controller.dart';
import 'package:sreerajp_textapp/sync/file_transfer_payload.dart';
import 'package:sreerajp_textapp/sync/sync_provider.dart';
import 'package:sreerajp_textapp/sync/ui/live_diff_screen.dart';
import 'package:sreerajp_textapp/sync/ui/sync_summary_view.dart';

/// Client (receive) screen (arch §9.6):
///   scan a QR or type the details → waiting → added / kept / applied summary.
class SyncClientScreen extends ConsumerWidget {
  const SyncClientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(syncDataAccessProvider);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncClientTitle)),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.syncCouldNotStart('$e'))),
        data: (_) {
          final controller = ref.watch(syncControllerProvider);
          return ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _ClientBody(controller: controller),
          );
        },
      ),
    );
  }
}

class _ClientBody extends StatelessWidget {
  final SyncController controller;

  const _ClientBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (controller.clientPhase) {
      case ClientPhase.idle:
        return _ConnectForm(controller: controller);
      case ClientPhase.connecting:
        return _Busy(message: l10n.syncConnecting);
      case ClientPhase.connected:
      case ClientPhase.waiting:
        return _Busy(message: l10n.syncConnectedWaiting);
      case ClientPhase.applying:
        return _Busy(message: l10n.syncApplying);
      case ClientPhase.done:
        if (controller.receivedDiffSession != null) {
          return _ReceivedDiffSessionView(
            payload: controller.receivedDiffSession!,
            controller: controller,
          );
        }
        if (controller.receivedFile != null) {
          return _ReceivedFileView(payload: controller.receivedFile!);
        }
        return SyncSummaryView(summary: controller.summary!);
      case ClientPhase.error:
        return _ErrorBody(
          message: controller.errorMessage ?? l10n.syncFailedGeneric,
        );
    }
  }
}

class _ConnectForm extends StatefulWidget {
  final SyncController controller;

  const _ConnectForm({required this.controller});

  @override
  State<_ConnectForm> createState() => _ConnectFormState();
}

class _ConnectFormState extends State<_ConnectForm> {
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final raw = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _ScanScreen()));
    if (raw != null) {
      await widget.controller.connectFromScan(raw);
    }
  }

  void _connectManual() {
    final port = int.tryParse(_port.text.trim());
    if (port == null) return;
    widget.controller.connectManual(
      host: _host.text.trim(),
      port: port,
      code: _code.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l10n.syncScanQr),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          l10n.syncOrTypeDetails,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _host,
          decoration: InputDecoration(
            labelText: l10n.syncAddress,
            hintText: l10n.syncAddressHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _port,
          decoration: InputDecoration(
            labelText: l10n.syncPort,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          decoration: InputDecoration(
            labelText: l10n.syncPairingCode,
            border: const OutlineInputBorder(),
          ),
          autocorrect: false,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _connectManual,
          icon: const Icon(Icons.link),
          label: Text(l10n.syncConnect),
        ),
      ],
    );
  }
}

/// Full-screen QR scanner. Returns the scanned raw string via [Navigator.pop].
class _ScanScreen extends StatelessWidget {
  const _ScanScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncScanTitle)),
      body: Semantics(
        label: l10n.syncScanSemantics,
        child: MobileScanner(
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;
            final raw = barcodes.first.rawValue;
            if (raw != null && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(raw);
            }
          },
        ),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  final String message;

  const _Busy({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).syncFailed,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReceivedFileView extends ConsumerStatefulWidget {
  final FileTransferPayload payload;

  const _ReceivedFileView({required this.payload});

  @override
  ConsumerState<_ReceivedFileView> createState() => _ReceivedFileViewState();
}

class _ReceivedFileViewState extends ConsumerState<_ReceivedFileView> {
  bool _isSaving = false;
  String? _savedFileName;

  Future<void> _saveToStorage() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      final saf = ref.read(safServiceProvider);
      final bytes = Uint8List.fromList(utf8.encode(widget.payload.fileContent));
      final destFile = await saf.createDocument(
        suggestedName: widget.payload.fileName,
        bytes: bytes,
        mimeType: widget.payload.mimeType,
      );

      if (mounted) {
        setState(() {
          _savedFileName = destFile.displayName;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.syncClientSavedAs(destFile.displayName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on SafCancelled {
      if (mounted) setState(() => _isSaving = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.syncClientSaveFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sizeKb = (widget.payload.fileSizeBytes / 1024).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Document Received Successfully',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transferred directly over encrypted P2P local socket.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.payload.fileName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$sizeKb KB • ${widget.payload.mimeType}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Content Preview:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.payload.fileContent,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_savedFileName == null)
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveToStorage,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_alt),
            label: Text(
              _isSaving ? l10n.syncClientSaving : l10n.syncClientSaveToDevice,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved to storage as $_savedFileName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.tabClose),
        ),
      ],
    );
  }
}

class _ReceivedDiffSessionView extends ConsumerStatefulWidget {
  final DiffSessionPayload payload;
  final SyncController controller;

  const _ReceivedDiffSessionView({
    required this.payload,
    required this.controller,
  });

  @override
  ConsumerState<_ReceivedDiffSessionView> createState() =>
      _ReceivedDiffSessionViewState();
}

class _ReceivedDiffSessionViewState
    extends ConsumerState<_ReceivedDiffSessionView> {
  String? _localFileName;
  String? _localContent;

  Future<void> _pickLocalFile() async {
    final l10n = AppLocalizations.of(context);
    try {
      final saf = ref.read(safServiceProvider);
      final file = await saf.pickFile();
      final bytes = await saf.readBytes(file.uri);
      final text = utf8.decode(bytes, allowMalformed: true);

      setState(() {
        _localFileName = file.displayName;
        _localContent = text;
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
        _localFileName = tab.displayName;
        _localContent = text;
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

  void _openLiveDiffScreen() {
    final localText = _localContent ?? '';
    final remoteText = widget.payload.content;

    final diffCtrl = LiveDiffController(
      documentName: widget.payload.fileName,
      mimeType: widget.payload.mimeType,
      mode: DiffSessionMode.p2pClient,
      initialLocalContent: localText,
      initialRemoteContent: remoteText,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.difference_outlined,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Live Diff Session Offered',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Peer is sharing "${widget.payload.fileName}" for side-by-side comparison & merge.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Remote: ${widget.payload.fileName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a local document to compare against:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickLocalFile,
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.syncClientPickLocalFile),
                ),
                if (tabsState.tabs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.syncClientMatchOpenTab,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tabsState.tabs.map((t) {
                      final isChosen = _localFileName == t.displayName;
                      return ChoiceChip(
                        label: Text(t.displayName),
                        selected: isChosen,
                        onSelected: (_) => _selectOpenTab(t),
                      );
                    }).toList(),
                  ),
                ],
                if (_localFileName != null) ...[
                  const SizedBox(height: 12),
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: Text(l10n.syncClientComparingWith(_localFileName!)),
                    onDeleted: () => setState(() {
                      _localFileName = null;
                      _localContent = null;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _openLiveDiffScreen,
          icon: const Icon(Icons.compare_arrows),
          label: Text(
            _localFileName == null
                ? 'Open Diff (Inspect Remote Only)'
                : 'Start Live Side-by-Side Diff',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.tabClose),
        ),
      ],
    );
  }
}
