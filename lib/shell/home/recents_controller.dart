import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/index/index_hooks.dart';
import 'package:sreerajp_textapp/core/index/index_providers.dart';
import 'package:sreerajp_textapp/core/storage/recents_repository.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/storage/storage_models.dart';
import 'package:sreerajp_textapp/core/storage/storage_providers.dart';

/// A recent file plus whether its saved URI is still reachable. A stale entry
/// (moved / deleted / permission revoked) is shown as unavailable with a remove
/// option rather than failing when tapped (task 2.3).
class RecentEntry {
  final RecentFile file;
  final bool available;

  const RecentEntry({required this.file, required this.available});
}

/// Loads and manages the Home / Recent Files list (task 2.3).
///
/// Reads recents from the DB (Phase 1.4) and checks each URI's accessibility via
/// the SAF service (Phase 1.1). Also records a freshly opened file so it appears
/// at the top next time.
class RecentsController extends AsyncNotifier<List<RecentEntry>> {
  RecentsRepository? _repo;

  Future<RecentsRepository> _repository() async {
    final existing = _repo;
    if (existing != null) return existing;
    final repo = await ref.watch(recentsRepositoryProvider.future);
    _repo = repo;
    return repo;
  }

  SafService get _saf => ref.read(safServiceProvider);

  @override
  Future<List<RecentEntry>> build() async {
    return _loadEntries();
  }

  Future<List<RecentEntry>> _loadEntries() async {
    final repo = await _repository();
    final files = await repo.all();
    final entries = <RecentEntry>[];
    for (final f in files) {
      final available = await _saf.isAccessible(f.uri);
      entries.add(RecentEntry(file: f, available: available));
    }
    return entries;
  }

  /// Records that [file] (already fingerprinted) was opened, moving it to the
  /// top of the list.
  Future<void> recordOpen(SafFile file, String fingerprint) async {
    final repo = await _repository();
    // Drop any older rows for the same file location (its content, and so its
    // fingerprint, may have changed since it was last opened) so the list keeps
    // one entry per file instead of a new one per edit.
    await repo.removeOtherUris(file.uri, fingerprint);
    await repo.upsert(
      RecentFile(
        fingerprint: fingerprint,
        uri: file.uri,
        displayName: file.displayName,
        mimeType: file.mimeType,
        size: file.size,
        lastOpenedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await refreshList();
  }

  /// Removes one recent entry. Its workspace-index entry goes with it, so a
  /// file the user dropped stops showing up in search results.
  Future<void> remove(String fingerprint) async {
    final repo = await _repository();
    await repo.remove(fingerprint);
    await WorkspaceIndexHooks.remove(
      service: ref.read(searchIndexServiceProvider.future),
      fingerprint: fingerprint,
    );
    await refreshList();
  }

  /// Clears the whole recents list, and with it every index entry that is not
  /// kept as a favorite.
  Future<void> clearAll() async {
    final repo = await _repository();
    await repo.clear();
    await WorkspaceIndexHooks.removeUnpinned(
      service: ref.read(searchIndexServiceProvider.future),
    );
    await refreshList();
  }

  /// Re-reads the list and re-checks accessibility.
  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadEntries);
  }
}

final recentsControllerProvider =
    AsyncNotifierProvider<RecentsController, List<RecentEntry>>(
      RecentsController.new,
    );
