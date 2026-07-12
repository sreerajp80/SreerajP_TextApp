import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/draft_store.dart';
import '../../core/editor/editor_providers.dart';
import '../../core/editor/editor_settings_controller.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/saf_service.dart';
import '../../core/theme/theme_controller.dart';
import '../../shell/tabs/document_tab.dart';
import '../../shell/tabs/tabs_controller.dart';
import 'txt_document_session.dart';

/// Owns the live [TxtDocumentSession] for each open TXT tab.
///
/// Sessions are kept in a map keyed by tab id so a document's editor state
/// (content, undo history, scroll) **survives switching between tabs** — the
/// workspace shows one body at a time, so the session cannot live in the widget.
/// A session is created lazily the first time its tab is shown and disposed when
/// the tab closes (see [release]) or when the app shuts down.
class TxtSessionManager {
  final Ref _ref;
  final Map<String, TxtDocumentSession> _sessions = {};

  TxtSessionManager(this._ref);

  /// Returns the session for [tab], creating and starting its load on first use.
  TxtDocumentSession sessionFor(DocumentTab tab) {
    final existing = _sessions[tab.id];
    if (existing != null) return existing;

    final editor = _ref.read(editorSettingsProvider);
    final session = TxtDocumentSession(
      tab: tab,
      saf: _ref.read(safServiceProvider),
      codec: _ref.read(textCodecServiceProvider),
      saver: _ref.read(atomicSaverProvider),
      metadata: _ref.read(metadataServiceProvider),
      store: _ref.read(keyValueStoreSyncProvider),
      draftStore: _resolveDraftStore(),
      tempDir: _ref.read(saveTempDirProvider.future),
      autoSaveInterval: editor.autoSaveInterval,
      initialWordWrap: _ref.read(themeControllerProvider).wordWrap,
      defaultSaveEncoding: editor.encodingDefault.resolve(),
      defaultSaveLineEnding: editor.lineEndingDefault.resolve(),
      onDirtyChanged: (dirty) =>
          _ref.read(tabsControllerProvider.notifier).setDirty(tab.id, dirty),
    );
    _sessions[tab.id] = session;
    // Fire the load; the session moves itself to ready/failed and notifies.
    session.load();
    return session;
  }

  /// The session for [tabId] if one exists (does not create one).
  TxtDocumentSession? peek(String tabId) => _sessions[tabId];

  /// Tab ids that currently hold a live (heavy) session. Used by the workspace
  /// to release background tabs' state when memory is tight (Phase 10.3).
  Iterable<String> get liveIds => _sessions.keys;

  /// Disposes and forgets the session for [tabId] (call when the tab closes).
  void release(String tabId) {
    _sessions.remove(tabId)?.dispose();
  }

  /// Disposes any sessions whose tab is no longer open. Called by the workspace
  /// whenever the tab set changes, so closing a tab frees its editor state (and
  /// its auto-save timer) without the shell needing to know about TXT.
  void retainOnly(Set<String> openTabIds) {
    final gone = _sessions.keys.where((id) => !openTabIds.contains(id)).toList();
    for (final id in gone) {
      _sessions.remove(id)?.dispose();
    }
  }

  void _disposeAll() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
  }

  Future<DraftStore> _resolveDraftStore() => _ref.read(draftStoreProvider.future);
}

/// App-wide TXT session manager. Kept alive for the app's lifetime; disposes all
/// open sessions when the provider scope is torn down.
final txtSessionManagerProvider = Provider<TxtSessionManager>((ref) {
  final manager = TxtSessionManager(ref);
  ref.onDispose(manager._disposeAll);
  return manager;
});
