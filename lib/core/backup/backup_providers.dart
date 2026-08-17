import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/backup/backup_bundle_service.dart';
import 'package:sreerajp_textapp/core/backup/backup_service.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/storage_providers.dart';

/// Provider for the unencrypted bundle packaging service.
final backupBundleServiceProvider = Provider<BackupBundleService>((ref) {
  return const BackupBundleService();
});

/// Async provider for the [BackupService] facade.
final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final recentsRepo = await ref.watch(recentsRepositoryProvider.future);
  final favoritesRepo = await ref.watch(favoritesRepositoryProvider.future);
  final bookmarksRepo = await ref.watch(bookmarksRepositoryProvider.future);
  final store = ref.watch(keyValueStoreSyncProvider);
  final bundleService = ref.watch(backupBundleServiceProvider);

  return BackupService(
    recentsRepo: recentsRepo,
    favoritesRepo: favoritesRepo,
    bookmarksRepo: bookmarksRepo,
    store: store,
    bundleService: bundleService,
  );
});
