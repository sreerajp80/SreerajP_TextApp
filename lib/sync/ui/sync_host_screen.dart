import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/security/security_providers.dart';
import '../../shell/settings/security_settings.dart';
import '../../l10n/app_localizations.dart';
import '../sync_provider.dart';
import '../sync_share_prefs.dart';
import 'share_chooser.dart';
import 'sync_status_chip.dart';

/// Host (send) screen with two tabs (arch §9.6):
///   1. Connection details — QR + IP / port / code as selectable text, a live
///      status chip, and Stop.
///   2. Choose what to share — Full Sync + per-category checkboxes.
///
/// While this screen is open, idle/background auto-lock should be suppressed so
/// a waiting host is not torn down (arch §9.6). App-lock and FLAG_SECURE land in
/// Phase 11.6 / 13.2; the hook point is noted below.
class SyncHostScreen extends ConsumerStatefulWidget {
  const SyncHostScreen({super.key});

  @override
  ConsumerState<SyncHostScreen> createState() => _SyncHostScreenState();
}

class _SyncHostScreenState extends ConsumerState<SyncHostScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // The pairing code / QR is the most sensitive screen in the app, so force
    // screenshot protection on while it is open regardless of the user's global
    // setting (security-rules: protect screens showing the pairing code/QR).
    ref.read(windowSecurityProvider).setSecure(true);
  }

  @override
  void dispose() {
    // Stop the socket when leaving the screen.
    final async = ref.read(syncDataAccessProvider);
    if (async.hasValue) {
      ref.read(syncControllerProvider).stopHost();
    }
    // Restore FLAG_SECURE to whatever the global "block screenshots" setting is.
    final protect = ref.read(securitySettingsProvider).screenshotProtection;
    ref.read(windowSecurityProvider).setSecure(protect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(syncDataAccessProvider);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncHostTitle)),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.syncCouldNotStart('$e'))),
        data: (_) {
          final controller = ref.watch(syncControllerProvider);
          if (!_started) {
            _started = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => controller.startHost());
          }
          return ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _HostBody(controller: controller),
          );
        },
      ),
    );
  }
}

class _HostBody extends ConsumerWidget {
  final SyncController controller;

  const _HostBody({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharePrefs = ref.watch(syncSharePrefsProvider);
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.syncTabConnection),
              Tab(text: l10n.syncTabWhatToShare),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ConnectionTab(controller: controller),
                ShareChooser(
                  connected: controller.hostConnected,
                  sending: controller.isSending,
                  initialCategories: sharePrefs.enabledCategories,
                  onFullSync: controller.pushFullSync,
                  onSelective: (categories, includeSettings) =>
                      controller.pushSelective(
                    categories: categories,
                    includeSettings: includeSettings,
                  ),
                ),
              ],
            ),
          ),
          if (controller.payloadSent)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.syncDataSent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                controller.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectionTab extends StatelessWidget {
  final SyncController controller;

  const _ConnectionTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final qr = controller.qrUri();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: SyncStatusChip(phase: controller.hostPhase)),
        const SizedBox(height: 16),
        if (qr != null)
          Center(
            child: Semantics(
              image: true,
              label: 'Pairing QR code. Scan it from the other device, or type '
                  'the code, address, and port shown below.',
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: qr,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
            ),
          )
        else
          Center(
            child: Text(
              l10n.syncNoWifi,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 24),
        _DetailRow(
          label: l10n.syncPairingCode,
          value: controller.formattedCode ?? '…',
        ),
        _DetailRow(
          label: l10n.syncAddress,
          value: controller.ips.isEmpty ? '—' : controller.ips.join(', '),
        ),
        _DetailRow(
          label: l10n.syncPort,
          value: controller.port?.toString() ?? '…',
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.stop),
          label: Text(l10n.syncStop),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).actionCopy,
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
    );
  }
}
