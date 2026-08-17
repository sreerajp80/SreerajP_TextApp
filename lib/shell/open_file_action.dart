import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/audit/audit_hooks.dart';
import 'package:sreerajp_textapp/core/audit/audit_providers.dart';
import 'package:sreerajp_textapp/core/audit/audit_service.dart';
import 'package:sreerajp_textapp/core/audit/audit_settings.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_controller.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_models.dart';
import 'package:sreerajp_textapp/core/fingerprint/content_fingerprint.dart';
import 'package:sreerajp_textapp/core/index/index_hooks.dart';
import 'package:sreerajp_textapp/core/index/index_providers.dart';
import 'package:sreerajp_textapp/core/index/search_index_service.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/storage/storage_models.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/home/recents_controller.dart';
import 'package:sreerajp_textapp/shell/shell_providers.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';

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

  /// The index service future, read while the ref is still valid. It resolves
  /// only once the database is open; a failure here is handled by the hooks.
  Future<SearchIndexService> _indexService() =>
      ref.read(searchIndexServiceProvider.future);

  /// The audit service future, read while the ref is still valid.
  Future<AuditService> _auditService() => ref.read(auditServiceProvider.future);

  /// Whether the user keeps the workspace index turned on. Falls back to `true`
  /// when the settings store is not available (tests).
  bool _indexEnabled() {
    try {
      return ref.read(workspaceIndexEnabledProvider);
    } catch (_) {
      return true;
    }
  }

  /// Whether the user keeps the audit log turned on. Falls back to `true`
  /// when the settings store is not available (tests).
  bool _auditEnabled() {
    try {
      return ref.read(auditEnabledProvider);
    } catch (_) {
      return true;
    }
  }

  /// Opens the system picker, then opens the chosen file.
  ///
  /// Pass [ephemeral] to open the file straight into a self-destructing tab
  /// (Feature 9).
  Future<void> pickAndOpen(
    BuildContext context, {
    EphemeralOption? ephemeral,
  }) async {
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
    await openFile(context, file, ephemeral: ephemeral);
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
  /// Pass [ephemeral] to open the file into a self-destructing tab (Feature 9).
  /// The recents row and the search-index entry are then never written at all,
  /// rather than written and cleaned up afterwards — the trace that is never
  /// made is the one that cannot be missed on the way out.
  Future<void> openFile(
    BuildContext context,
    SafFile file, {
    TabViewMode initialViewMode = TabViewMode.view,
    EphemeralOption? ephemeral,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // The recents refresh can rebuild and dispose the widget that started this
    // action. Capture every provider dependency while its WidgetRef is valid so
    // the rest of the open flow remains safe across asynchronous gaps.
    final saf = _saf;
    final indexService = _indexService();
    final auditService = _auditService();
    // An ephemeral open never indexes: the index stores the document's own text.
    final indexEnabled = ephemeral == null && _indexEnabled();
    final auditEnabled = _auditEnabled();
    final recents = ref.read(recentsControllerProvider.notifier);
    final tabs = ref.read(tabsControllerProvider.notifier);
    final ephemeralTabs = ref.read(ephemeralControllerProvider.notifier);
    final destination = ref.read(shellDestinationProvider.notifier);
    String fingerprintKey;
    try {
      final bytes = await saf.readBytes(file.uri);
      final fp = ContentFingerprint.fromBytes(bytes);
      fingerprintKey = fp.key;
      // Add the file to the workspace search index while its bytes are already
      // in hand. It runs alongside the rest of the open flow and never blocks
      // it (Feature 11).
      unawaited(
        WorkspaceIndexHooks.indexBytes(
          service: indexService,
          enabled: indexEnabled,
          fingerprint: fingerprintKey,
          uri: file.uri,
          displayName: file.displayName,
          bytes: bytes,
          mimeType: file.mimeType,
          size: file.size,
        ),
      );
      // Record file open in the audit log (Feature 8).
      unawaited(
        AuditHooks.onFileOpened(
          service: auditService,
          enabled: auditEnabled,
          fileName: file.displayName,
          fingerprint: fingerprintKey,
          contentHash: fp.sha256Hex,
        ),
      );
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    // Record it in recents (best-effort) and open the tab. An ephemeral open
    // skips recents entirely (Feature 9).
    if (ephemeral == null) {
      await recents.recordOpen(file, fingerprintKey);
    }

    final outcome = tabs.openFile(
      file,
      fingerprintKey,
      initialViewMode: initialViewMode,
    );

    if (outcome == OpenOutcome.cappedNeedsChoice) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.openTooManyTabs)));
      return;
    }

    // Mark the freshly opened (now active) tab before anything can write a
    // trace for it.
    if (ephemeral != null) {
      final opened = ref.read(tabsControllerProvider).activeTab;
      if (opened != null) ephemeralTabs.mark(opened, ephemeral);
    }

    // Bring the workspace to the front.
    destination.select(ShellDestination.editor);
  }
}
