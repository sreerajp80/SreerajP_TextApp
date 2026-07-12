import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import '../sync_provider.dart';
import 'sync_summary_view.dart';

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
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanScreen()),
    );
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
        Text(l10n.syncOrTypeDetails,
            style: Theme.of(context).textTheme.titleMedium),
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
            Text(AppLocalizations.of(context).syncFailed,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
