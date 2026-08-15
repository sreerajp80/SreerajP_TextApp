import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/audit/audit_hooks.dart';
import 'package:text_data/core/audit/audit_providers.dart';
import 'package:text_data/core/audit/audit_settings.dart';

import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/editor/editor_providers.dart';
import 'package:text_data/core/editor/editor_settings_controller.dart';
import 'package:text_data/core/ephemeral/ephemeral_controller.dart';
import 'package:text_data/core/index/index_hooks.dart';
import 'package:text_data/core/index/index_providers.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/formats/json/json_document_session.dart';

/// Owns the live [JsonDocumentSession] for each open JSON tab.
///
/// Mirrors `MdSessionManager`: sessions are kept in a map keyed by tab id so a
/// document's editor state (content, undo history, scroll, parsed tree) survives
/// switching between tabs. A session is created lazily the first time its tab is
/// shown and disposed when the tab closes (see [release]) or at app shutdown.
class JsonSessionManager {
  final Ref _ref;
  final Map<String, JsonDocumentSession> _sessions = {};

  JsonSessionManager(this._ref);

  JsonDocumentSession sessionFor(DocumentTab tab) {
    final existing = _sessions[tab.id];
    if (existing != null) return existing;

    final editor = _ref.read(editorSettingsProvider);
    final session = JsonDocumentSession(
      tab: tab,
      saf: _ref.read(safServiceProvider),
      codec: _ref.read(textCodecServiceProvider),
      saver: _ref.read(atomicSaverProvider),
      metadata: _ref.read(metadataServiceProvider),
      store: _ref.read(keyValueStoreSyncProvider),
      draftStore: _ref.read(draftStoreProvider.future),
      tempDir: _ref.read(saveTempDirProvider.future),
      autoSaveInterval: editor.autoSaveInterval,
      defaultSaveEncoding: editor.encodingDefault.resolve(),
      defaultSaveLineEnding: editor.lineEndingDefault.resolve(),
      onDirtyChanged: (dirty) =>
          _ref.read(tabsControllerProvider.notifier).setDirty(tab.id, dirty),
      onSaved: (text) {
        _reindex(tab, text);
        _auditSave(tab, text);
      },
    );
    _sessions[tab.id] = session;
    session.load();
    return session;
  }

  JsonDocumentSession? peek(String tabId) => _sessions[tabId];

  /// Tab ids that currently hold a live (heavy) session. Used by the workspace
  /// to release background tabs' state when memory is tight (Phase 10.3).
  Iterable<String> get liveIds => _sessions.keys;

  void release(String tabId) {
    _sessions.remove(tabId)?.dispose();
  }

  void retainOnly(Set<String> openTabIds) {
    final gone = _sessions.keys
        .where((id) => !openTabIds.contains(id))
        .toList();
    for (final id in gone) {
      _sessions.remove(id)?.dispose();
    }
  }

  /// Refreshes the workspace search index after a successful save, so a search
  /// finds what the file says now (Feature 11). Best effort: any failure is
  /// swallowed inside the hook.
  void _reindex(DocumentTab tab, String text) {
    // An ephemeral tab never feeds the workspace search index: that index stores
    // the document's own text, which is exactly the trace the user asked the app
    // not to keep (Feature 9).
    if (_ref.read(ephemeralControllerProvider.notifier).isEphemeral(tab.id)) {
      return;
    }
    unawaited(
      WorkspaceIndexHooks.indexText(
        service: _ref.read(searchIndexServiceProvider.future),
        enabled: _ref.read(workspaceIndexEnabledProvider),
        fingerprint: tab.fingerprint,
        uri: tab.uri,
        displayName: tab.displayName,
        text: text,
        mimeType: tab.mimeType,
        size: tab.size,
      ),
    );
  }

  /// Records a file-save event in the audit log (Feature 8). Best effort.
  void _auditSave(DocumentTab tab, String text) {
    unawaited(
      AuditHooks.onFileSaved(
        service: _ref.read(auditServiceProvider.future),
        enabled: _ref.read(auditEnabledProvider),
        fileName: tab.displayName,
        fingerprint: tab.fingerprint,
      ),
    );
  }

  void _disposeAll() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
  }
}

/// App-wide JSON session manager, kept alive for the app's lifetime.
final jsonSessionManagerProvider = Provider<JsonSessionManager>((ref) {
  final manager = JsonSessionManager(ref);
  ref.onDispose(manager._disposeAll);
  return manager;
});
