import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/drafts_index_repository.dart';
import '../storage/storage_models.dart';
import '../storage/storage_providers.dart';

/// Persists in-progress edits so a crash or a killed process never loses work
/// (architecture.md §6). Each draft is a small file in the app's **private**
/// storage, keyed to the file's content fingerprint, with a row in
/// `drafts_index` pointing at it. On the next open the editor offers to restore
/// or discard; a real save clears the draft.
///
/// The base directory is injected so tests use a temporary folder and the app
/// uses its private support directory. Pure `dart:io`, no Flutter widgets.
class DraftStore {
  final Directory _baseDir;
  final DraftsIndexRepository _index;
  final int Function() _now;

  DraftStore({
    required Directory baseDir,
    required DraftsIndexRepository index,
    int Function()? now,
  })  : _baseDir = baseDir,
        _index = index,
        _now = now ?? _wallClockMillis;

  static int _wallClockMillis() => DateTime.now().millisecondsSinceEpoch;

  /// The folder drafts live in (created on demand under the base directory).
  Directory get _draftsDir => Directory('${_baseDir.path}/drafts');

  /// Writes (or overwrites) the draft for [fingerprint] and records its pointer.
  /// Draft content is never logged (security-rules: file contents stay private).
  Future<void> save(String fingerprint, String content) async {
    final dir = _draftsDir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = _draftFileFor(fingerprint);
    // Write to a sibling temp then rename, so a crash mid-write cannot leave a
    // half-written draft that would then be "restored".
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);

    await _index.upsert(DraftIndexEntry(
      fingerprint: fingerprint,
      draftPath: file.path,
      updatedAt: _now(),
    ));
  }

  /// Returns the saved draft text for [fingerprint], or null when there is none
  /// (or the file went missing). Never throws on a missing/corrupt draft.
  Future<String?> load(String fingerprint) async {
    final entry = await _index.byFingerprint(fingerprint);
    if (entry == null) return null;
    final file = File(entry.draftPath);
    if (!await file.exists()) {
      // Index points at a file that is gone — clean up the stale pointer.
      await _index.remove(fingerprint);
      return null;
    }
    try {
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  /// True when a usable draft exists for [fingerprint].
  Future<bool> hasDraft(String fingerprint) async {
    final entry = await _index.byFingerprint(fingerprint);
    if (entry == null) return false;
    return File(entry.draftPath).exists();
  }

  /// Removes the draft and its pointer (call after a real save, or when the user
  /// chooses "discard"). Safe to call when nothing is stored.
  Future<void> discard(String fingerprint) async {
    final entry = await _index.byFingerprint(fingerprint);
    if (entry != null) {
      final file = File(entry.draftPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } on FileSystemException {
          // Ignore — the pointer removal below still clears the draft.
        }
      }
    }
    await _index.remove(fingerprint);
  }

  File _draftFileFor(String fingerprint) {
    // The fingerprint key is `<size>-<hex>` — already filename-safe. Base64-url
    // encode defensively in case a caller passes an unusual key.
    final safe = base64Url.encode(utf8.encode(fingerprint));
    return File('${_draftsDir.path}/$safe.draft');
  }
}

/// Periodically writes the current editor content to the [DraftStore] so an
/// unexpected kill loses at most one interval's work (architecture.md §6).
///
/// Kept deliberately small and testable: [tick] does one save-if-changed pass
/// and is what the timer calls, so a test can drive it directly without waiting
/// on wall-clock time.
class AutoSaver {
  final DraftStore _store;
  final String _fingerprint;
  final String Function() _getContent;

  String? _lastSaved;
  Timer? _timer;

  AutoSaver({
    required DraftStore store,
    required String fingerprint,
    required String Function() getContent,
  })  : _store = store,
        _fingerprint = fingerprint,
        _getContent = getContent;

  /// Saves a draft only when the content changed since the last write, to avoid
  /// churning the disk. Returns true when it wrote.
  Future<bool> tick() async {
    final content = _getContent();
    if (content == _lastSaved) return false;
    await _store.save(_fingerprint, content);
    _lastSaved = content;
    return true;
  }

  /// Starts periodic auto-save on [interval]. Call [stop] when the editor
  /// closes.
  void start(Duration interval) {
    stop();
    _timer = Timer.periodic(interval, (_) => tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Marks the current content as clean (call right after a real save) so the
  /// next tick does not immediately rewrite the same draft.
  void markSaved(String content) {
    _lastSaved = content;
  }
}

/// Builds the app's [DraftStore] using the private support directory (no storage
/// permission needed). Tests construct a [DraftStore] directly with a temp dir.
final draftStoreProvider = FutureProvider<DraftStore>((ref) async {
  final dir = await getApplicationSupportDirectory();
  final index = await ref.watch(draftsIndexRepositoryProvider.future);
  return DraftStore(baseDir: dir, index: index);
});
