import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fingerprint/content_fingerprint.dart';
import '../core/storage/saf_exceptions.dart';
import '../core/storage/saf_service.dart';
import '../core/storage/storage_models.dart';
import '../l10n/app_localizations.dart';
import 'home/recents_controller.dart';
import 'shell_providers.dart';
import 'tabs/document_tab.dart';
import 'tabs/tabs_controller.dart';

/// The one path a file takes to become an open tab (used by the "Open a file"
/// button and by tapping a recent). Coordinates SAF (Phase 1.1), the content
/// fingerprint (Phase 1.2), the recents list (task 2.3), and the tab system
/// (task 2.5).
///
/// Every SAF failure is caught and shown as a friendly snackbar — a bad or
/// revoked file never crashes the app (CLAUDE.md §3.4).
class OpenFileAction {
  final WidgetRef ref;

  const OpenFileAction(this.ref);

  SafService get _saf => ref.read(safServiceProvider);

  /// Opens the system picker, then opens the chosen file.
  Future<void> pickAndOpen(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    SafFile file;
    try {
      file = await _saf.pickFile();
    } on SafCancelled {
      return; // user backed out — nothing to do
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!context.mounted) return;
    await openFile(context, file);
  }

  /// Re-opens a recent entry from its saved URI.
  Future<void> openRecent(BuildContext context, RecentFile recent) async {
    final file = SafFile(
      uri: recent.uri,
      displayName: recent.displayName,
      mimeType: recent.mimeType,
      size: recent.size,
    );
    await openFile(context, file);
  }

  /// Opens an already selected or newly created SAF document through the one
  /// shared fingerprint, recents, tab, and navigation flow.
  Future<void> openFile(
    BuildContext context,
    SafFile file, {
    TabViewMode initialViewMode = TabViewMode.view,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // The recents refresh can rebuild and dispose the widget that started this
    // action. Capture every provider dependency while its WidgetRef is valid so
    // the rest of the open flow remains safe across asynchronous gaps.
    final saf = _saf;
    final recents = ref.read(recentsControllerProvider.notifier);
    final tabs = ref.read(tabsControllerProvider.notifier);
    final destination = ref.read(shellDestinationProvider.notifier);
    String fingerprintKey;
    try {
      final bytes = await saf.readBytes(file.uri);
      fingerprintKey = ContentFingerprint.fromBytes(bytes).key;
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    // Record it in recents (best-effort) and open the tab.
    await recents.recordOpen(file, fingerprintKey);

    final outcome = tabs.openFile(
      file,
      fingerprintKey,
      initialViewMode: initialViewMode,
    );

    if (outcome == OpenOutcome.cappedNeedsChoice) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.openTooManyTabs)));
      return;
    }

    // Bring the workspace to the front.
    destination.select(ShellDestination.editor);
  }
}
