import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/draft_store.dart';
import '../../core/editor/editor_providers.dart';
import '../../core/editor/editor_settings_controller.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/saf_service.dart';
import '../../shell/tabs/document_tab.dart';
import '../../shell/tabs/tabs_controller.dart';
import 'md_document_session.dart';

/// Owns the live [MdDocumentSession] for each open Markdown tab.
///
/// Mirrors `TxtSessionManager`: sessions are kept in a map keyed by tab id so a
/// document's editor state (content, undo history, scroll, parsed AST) survives
/// switching between tabs. A session is created lazily the first time its tab is
/// shown and disposed when the tab closes (see [release]) or at app shutdown.
class MdSessionManager {
  final Ref _ref;
  final Map<String, MdDocumentSession> _sessions = {};

  MdSessionManager(this._ref);

  MdDocumentSession sessionFor(DocumentTab tab) {
    final existing = _sessions[tab.id];
    if (existing != null) return existing;

    final editor = _ref.read(editorSettingsProvider);
    final session = MdDocumentSession(
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
    );
    _sessions[tab.id] = session;
    session.load();
    return session;
  }

  MdDocumentSession? peek(String tabId) => _sessions[tabId];

  /// Tab ids that currently hold a live (heavy) session. Used by the workspace
  /// to release background tabs' state when memory is tight (Phase 10.3).
  Iterable<String> get liveIds => _sessions.keys;

  void release(String tabId) {
    _sessions.remove(tabId)?.dispose();
  }

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
}

/// App-wide Markdown session manager, kept alive for the app's lifetime.
final mdSessionManagerProvider = Provider<MdSessionManager>((ref) {
  final manager = MdSessionManager(ref);
  ref.onDispose(manager._disposeAll);
  return manager;
});
