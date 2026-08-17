import 'package:sreerajp_textapp/core/audit/audit_service.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/index/search_index_service.dart';
import 'package:sreerajp_textapp/core/storage/bookmarks_repository.dart';
import 'package:sreerajp_textapp/core/storage/favorites_repository.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/recents_repository.dart';

/// Removes every trace the app itself keeps of one document (Feature 9).
///
/// ## What it does not do
///
/// **It never deletes the user's file.** The app is scoped-storage only
/// (`CLAUDE.md` §3 rule 3) and reaches documents through the system picker, so
/// deleting the user's own data is not its business. "Ephemeral" here means the
/// app forgets the document — not that the document is destroyed.
///
/// ## Why each step is guarded on its own
///
/// A burn must be all-or-as-much-as-possible. If the database is unavailable,
/// the draft file on disk must still be wiped, and the other way round. So each
/// step catches its own failure and the sequence continues. The one thing that
/// must not happen is a half-burn that stops early and silently leaves the
/// document text sitting in the search index.
class EphemeralWiper {
  /// Preference key prefixes that are followed by a file's content
  /// fingerprint. Each format session stores its reading position and per-file
  /// view state under one of these (see `*_document_session.dart`).
  ///
  /// **Keep this list in step with those sessions.** A prefix missing here is a
  /// trace that outlives a burn.
  static const List<String> fingerprintKeyPrefixes = [
    'txt.pos.',
    'md.pos.',
    'md.preview.',
    'json.pos.',
    'xml.pos.',
    'csv.pos.',
    'csv.dir.',
    'csv.sorts.',
    'csv.formulas.',
    'csv.rules.',
  ];

  final Future<DraftStore> draftStore;
  final Future<RecentsRepository> recents;
  final Future<FavoritesRepository> favorites;
  final Future<BookmarksRepository> bookmarks;
  final Future<SearchIndexService> searchIndex;
  final KeyValueStore store;
  final Future<AuditService>? auditService;

  const EphemeralWiper({
    required this.draftStore,
    required this.recents,
    required this.favorites,
    required this.bookmarks,
    required this.searchIndex,
    required this.store,
    this.auditService,
  });

  /// Wipes every app-owned trace of the document with this [fingerprint].
  ///
  /// Returns the steps that failed, so a caller can tell the user the burn was
  /// not complete. An empty list means everything was removed.
  Future<List<String>> wipe(String fingerprint) async {
    final failures = <String>[];

    // The search index holds the document **text**, so it goes first: if the
    // process dies part-way through a burn, the content is already gone.
    await _step(failures, 'index', () async {
      final index = await searchIndex;
      await index.remove(fingerprint);
    });

    // The draft file is the other copy of the full text.
    await _step(failures, 'draft', () async {
      final drafts = await draftStore;
      await drafts.wipe(fingerprint);
    });

    await _step(failures, 'recents', () async {
      final r = await recents;
      await r.remove(fingerprint);
    });

    await _step(failures, 'favorites', () async {
      final f = await favorites;
      await f.remove(fingerprint);
    });

    await _step(failures, 'bookmarks', () async {
      final b = await bookmarks;
      await b.clearForFile(fingerprint);
    });

    await _step(failures, 'preferences', () async {
      for (final prefix in fingerprintKeyPrefixes) {
        await store.remove('$prefix$fingerprint');
      }
    });

    if (auditService != null) {
      await _step(failures, 'audit', () async {
        final audit = await auditService!;
        await audit.clearForFingerprint(fingerprint);
      });
    }

    return failures;
  }

  Future<void> _step(
    List<String> failures,
    String name,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (_) {
      // Deliberately swallowed and reported by name instead of thrown: one
      // unreachable store must not leave the rest of the traces in place. The
      // failure is never logged with the fingerprint or the file name, because
      // that would itself be a trace of the document being burned.
      failures.add(name);
    }
  }
}
