import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/index/search_index_backfill.dart';
import 'package:sreerajp_textapp/core/index/search_index_repository.dart';
import 'package:sreerajp_textapp/core/index/search_index_service.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/storage/storage_providers.dart';

/// Settings key for the workspace search index on/off switch.
const String kWorkspaceIndexEnabledKey = 'workspace_index_enabled';

/// The repository over the index tables, built on the shared app database.
final searchIndexRepositoryProvider = FutureProvider<SearchIndexRepository>((
  ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return SearchIndexRepository(
    database.db,
    ftsAvailable: database.ftsAvailable,
  );
});

/// The service the rest of the app talks to when indexing or searching.
final searchIndexServiceProvider = FutureProvider<SearchIndexService>((
  ref,
) async {
  final repo = await ref.watch(searchIndexRepositoryProvider.future);
  return SearchIndexService(repo);
});

/// The bounded startup backfill (favorites + newest recents).
final searchIndexBackfillProvider = FutureProvider<SearchIndexBackfill>((
  ref,
) async {
  final index = await ref.watch(searchIndexServiceProvider.future);
  final recents = await ref.watch(recentsRepositoryProvider.future);
  final favorites = await ref.watch(favoritesRepositoryProvider.future);
  return SearchIndexBackfill(
    index: index,
    recents: recents,
    favorites: favorites,
    saf: ref.watch(safServiceProvider),
  );
});

/// Runs one backfill pass, quietly. Called once after the first frame; does
/// nothing when the user turned the index off.
Future<void> runWorkspaceIndexBackfill(WidgetRef ref) async {
  try {
    if (!ref.read(workspaceIndexEnabledProvider)) return;
    final backfill = await ref.read(searchIndexBackfillProvider.future);
    await backfill.run();
  } catch (_) {
    // ignored — the index fills itself as files are opened anyway
  }
}

/// Whether the workspace index is turned on (Settings › Files & Tabs).
///
/// Defaults to on. Turning it off stops all new indexing; the user can also
/// clear what was already stored from the same settings screen.
class WorkspaceIndexEnabled extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(keyValueStoreSyncProvider);
    return store.getBool(kWorkspaceIndexEnabledKey) ?? true;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref
        .read(keyValueStoreSyncProvider)
        .setBool(kWorkspaceIndexEnabledKey, enabled);
  }
}

final workspaceIndexEnabledProvider =
    NotifierProvider<WorkspaceIndexEnabled, bool>(WorkspaceIndexEnabled.new);
