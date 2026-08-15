import 'package:text_data/core/index/search_index_service.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/storage/storage_models.dart';

/// Fills the workspace search index with files the user already knows about but
/// has not opened since the index was added (Feature 11).
///
/// It is deliberately small and bounded: favorites first, then the newest
/// recents, skipping anything already indexed and anything the app can no
/// longer read. One file is handled at a time, with a gap between files so the
/// UI keeps its frames. Failures are skipped silently — a file that cannot be
/// read simply stays out of the index.
class SearchIndexBackfill {
  /// How many recent files one pass looks at.
  static const int maxRecents = 20;

  final SearchIndexService _index;
  final RecentsRepository _recents;
  final FavoritesRepository _favorites;
  final SafService _saf;

  const SearchIndexBackfill({
    required this._index,
    required this._recents,
    required this._favorites,
    required this._saf,
  });

  /// Runs one pass and returns how many files it added to the index.
  Future<int> run({int maxRecents = maxRecents}) async {
    final Set<String> known;
    try {
      known = await _index.repository.indexedFingerprints();
    } catch (_) {
      return 0;
    }

    var added = 0;
    final favorites = await _safeFavorites();
    for (final favorite in favorites) {
      if (known.contains(favorite.fingerprint)) {
        // Already indexed — just make sure it survives a "clear recents".
        await _index.setPinned(favorite.fingerprint, true);
        continue;
      }
      if (await _indexOne(
        fingerprint: favorite.fingerprint,
        uri: favorite.uri,
        displayName: favorite.displayName,
        pinned: true,
      )) {
        added++;
        known.add(favorite.fingerprint);
      }
    }

    final recents = await _safeRecents(maxRecents);
    for (final recent in recents) {
      if (known.contains(recent.fingerprint)) continue;
      if (await _indexOne(
        fingerprint: recent.fingerprint,
        uri: recent.uri,
        displayName: recent.displayName,
        mimeType: recent.mimeType,
        size: recent.size,
      )) {
        added++;
        known.add(recent.fingerprint);
      }
    }
    return added;
  }

  Future<bool> _indexOne({
    required String fingerprint,
    required String uri,
    required String displayName,
    String? mimeType,
    int? size,
    bool pinned = false,
  }) async {
    // Give the UI a turn between files; a backfill must never feel like a stall.
    await Future<void>.delayed(Duration.zero);
    try {
      final bytes = await _saf.readBytes(uri);
      final skipped = await _index.indexBytes(
        fingerprint: fingerprint,
        uri: uri,
        displayName: displayName,
        bytes: bytes,
        mimeType: mimeType,
        size: size,
        pinned: pinned,
      );
      return skipped == IndexSkipReason.none;
    } on SafException {
      return false; // moved, deleted, or permission gone — skip it
    } catch (_) {
      return false;
    }
  }

  Future<List<Favorite>> _safeFavorites() async {
    try {
      return await _favorites.all();
    } catch (_) {
      return const [];
    }
  }

  Future<List<RecentFile>> _safeRecents(int limit) async {
    try {
      return await _recents.all(limit: limit);
    } catch (_) {
      return const [];
    }
  }
}
