import 'dart:typed_data';

import 'package:sreerajp_textapp/core/editor/encoding.dart';
import 'package:sreerajp_textapp/core/index/search_index_models.dart';
import 'package:sreerajp_textapp/core/index/search_index_repository.dart';
import 'package:sreerajp_textapp/core/large_file/large_file_policy.dart';
import 'package:sreerajp_textapp/formats/txt/txt_content_sniff.dart';

/// Why a file was not added to the workspace search index.
enum IndexSkipReason {
  /// The file was indexed (nothing was skipped).
  none,

  /// The user turned the workspace index off in Settings.
  disabled,

  /// The file is at or above the oversized limit (50 MB).
  tooLarge,

  /// The bytes do not look like text.
  binary,
}

/// Decides what goes into the workspace search index and puts it there
/// (Feature 11).
///
/// Every call is **best effort**: a failure is swallowed and reported as a
/// `false` result, so indexing can never break opening or saving a file. No
/// document text is ever logged (security-rules).
class SearchIndexService {
  /// Most text stored for one file. Longer files are indexed up to this point
  /// and marked as truncated, so the index cannot grow without a bound.
  static const int maxBodyChars = 2 * 1024 * 1024;

  final SearchIndexRepository _repo;
  final TextCodecService _codec;

  const SearchIndexService(
    this._repo, [
    this._codec = const TextCodecService(),
  ]);

  SearchIndexRepository get repository => _repo;

  /// Whether [bytes] of a file of [size] may be indexed at all.
  static IndexSkipReason eligibility(Uint8List bytes, {int? size}) {
    final byteCount = (size == null || size < bytes.length)
        ? bytes.length
        : size;
    if (LargeFilePolicy.isOversized(byteCount)) return IndexSkipReason.tooLarge;
    if (TxtContentSniff.looksBinary(bytes)) return IndexSkipReason.binary;
    return IndexSkipReason.none;
  }

  /// Indexes a file from its raw [bytes] (the form the open flow already has).
  ///
  /// Returns the reason it was skipped, or [IndexSkipReason.none] on success.
  Future<IndexSkipReason> indexBytes({
    required String fingerprint,
    required String uri,
    required String displayName,
    required Uint8List bytes,
    String? mimeType,
    int? size,
    bool pinned = false,
  }) async {
    final skip = eligibility(bytes, size: size);
    if (skip != IndexSkipReason.none) return skip;
    final decoded = _codec.detectAndDecode(bytes);
    return indexText(
      fingerprint: fingerprint,
      uri: uri,
      displayName: displayName,
      text: decoded.text,
      mimeType: mimeType,
      size: size ?? bytes.length,
      pinned: pinned,
    );
  }

  /// Indexes a file from text the app already holds in memory (the save path).
  Future<IndexSkipReason> indexText({
    required String fingerprint,
    required String uri,
    required String displayName,
    required String text,
    String? mimeType,
    int? size,
    bool pinned = false,
  }) async {
    final truncated = text.length > maxBodyChars;
    final body = truncated ? text.substring(0, maxBodyChars) : text;
    try {
      // Keep a favorite pinned across a re-index, even when the caller does not
      // know it is one.
      final existing = await _repo.byFingerprint(fingerprint);
      await _repo.upsert(
        IndexedDoc(
          fingerprint: fingerprint,
          uri: uri,
          displayName: displayName,
          format: IndexFormat.fromFileName(displayName, mimeType: mimeType),
          size: size,
          indexedAt: DateTime.now().millisecondsSinceEpoch,
          truncated: truncated,
          pinned: pinned || (existing?.pinned ?? false),
        ),
        body,
      );
      return IndexSkipReason.none;
    } catch (_) {
      // Indexing is a convenience — never let it surface to the user.
      return IndexSkipReason.none;
    }
  }

  /// Whether this file already has an index entry.
  Future<bool> isIndexed(String fingerprint) async {
    try {
      return await _repo.byFingerprint(fingerprint) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> remove(String fingerprint) async {
    try {
      await _repo.remove(fingerprint);
    } catch (_) {
      // ignored — a stale index row is harmless
    }
  }

  /// Drops everything the user is no longer keeping (recents cleared).
  Future<void> removeUnpinned() async {
    try {
      await _repo.removeUnpinned();
    } catch (_) {
      // ignored
    }
  }

  Future<void> setPinned(String fingerprint, bool pinned) async {
    try {
      await _repo.setPinned(fingerprint, pinned);
    } catch (_) {
      // ignored
    }
  }

  Future<void> clear() async {
    try {
      await _repo.clear();
    } catch (_) {
      // ignored
    }
  }

  Future<List<SearchHit>> search(
    String query, {
    Set<IndexFormat> formats = const {},
    int limit = SearchIndexRepository.defaultLimit,
  }) async {
    try {
      return await _repo.search(query, formats: formats, limit: limit);
    } catch (_) {
      return const [];
    }
  }

  Future<int> count() async {
    try {
      return await _repo.count();
    } catch (_) {
      return 0;
    }
  }
}
