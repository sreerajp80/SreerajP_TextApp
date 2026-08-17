import 'dart:typed_data';

import 'package:sreerajp_textapp/core/index/search_index_service.dart';

/// Small best-effort helpers the open, save, and recents flows call to keep the
/// workspace search index up to date (Feature 11).
///
/// They take the service as a future (the database opens asynchronously) plus
/// the on/off setting, so callers can read both from whichever kind of Riverpod
/// ref they hold. Every failure — including a database that never opened — is
/// swallowed: the index is a convenience and must never break opening, saving,
/// or closing a file.
class WorkspaceIndexHooks {
  const WorkspaceIndexHooks._();

  /// Indexes a file the app has just read as bytes (the open flow).
  static Future<void> indexBytes({
    required Future<SearchIndexService> service,
    required bool enabled,
    required String fingerprint,
    required String uri,
    required String displayName,
    required Uint8List bytes,
    String? mimeType,
    int? size,
  }) async {
    if (!enabled) return;
    try {
      final index = await service;
      await index.indexBytes(
        fingerprint: fingerprint,
        uri: uri,
        displayName: displayName,
        bytes: bytes,
        mimeType: mimeType,
        size: size,
      );
    } catch (_) {
      // ignored on purpose — see the class comment
    }
  }

  /// Re-indexes a file from the text already in memory (the save flow).
  static Future<void> indexText({
    required Future<SearchIndexService> service,
    required bool enabled,
    required String fingerprint,
    required String uri,
    required String displayName,
    required String text,
    String? mimeType,
    int? size,
  }) async {
    if (!enabled) return;
    try {
      final index = await service;
      await index.indexText(
        fingerprint: fingerprint,
        uri: uri,
        displayName: displayName,
        text: text,
        mimeType: mimeType,
        size: size,
      );
    } catch (_) {
      // ignored on purpose
    }
  }

  /// Drops one file from the index (a recent was removed).
  static Future<void> remove({
    required Future<SearchIndexService> service,
    required String fingerprint,
  }) async {
    try {
      final index = await service;
      await index.remove(fingerprint);
    } catch (_) {
      // ignored on purpose
    }
  }

  /// Drops every entry the user is no longer keeping (recents cleared). Files
  /// kept as favorites stay.
  static Future<void> removeUnpinned({
    required Future<SearchIndexService> service,
  }) async {
    try {
      final index = await service;
      await index.removeUnpinned();
    } catch (_) {
      // ignored on purpose
    }
  }

  /// Marks a file as a favorite (or not) in the index.
  static Future<void> setPinned({
    required Future<SearchIndexService> service,
    required String fingerprint,
    required bool pinned,
  }) async {
    try {
      final index = await service;
      await index.setPinned(fingerprint, pinned);
    } catch (_) {
      // ignored on purpose
    }
  }
}
