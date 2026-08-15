import 'dart:typed_data';

import 'package:text_data/core/backup/backup_bundle_service.dart';
import 'package:text_data/core/backup/backup_crypto.dart';
import 'package:text_data/core/backup/backup_models.dart';
import 'package:text_data/core/storage/bookmarks_repository.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/storage_models.dart';

/// Orchestrates zero-knowledge encrypted backup creation and restoration.
class BackupService {
  final RecentsRepository recentsRepo;
  final FavoritesRepository favoritesRepo;
  final BookmarksRepository bookmarksRepo;
  final KeyValueStore store;
  final BackupBundleService bundleService;

  const BackupService({
    required this.recentsRepo,
    required this.favoritesRepo,
    required this.bookmarksRepo,
    required this.store,
    required this.bundleService,
  });

  /// Gathers selected data from repositories and preferences, bundles it, and
  /// encrypts it into a `.txdata` archive under [password].
  Future<Uint8List> createBackup({
    required String password,
    required BackupExportOptions options,
  }) async {
    final recents = options.includeRecents
        ? await recentsRepo.all()
        : <RecentFile>[];
    final favorites = options.includeFavorites
        ? await favoritesRepo.all()
        : <Favorite>[];
    final bookmarks = options.includeBookmarks
        ? await bookmarksRepo.all()
        : <Bookmark>[];
    final settings = options.includeSettings
        ? store.getAllNonSensitiveSettings()
        : <String, Object?>{};
    final files = options.files;

    final manifest = BackupManifest(
      createdAt: DateTime.now().millisecondsSinceEpoch,
      recentsCount: recents.length,
      favoritesCount: favorites.length,
      bookmarksCount: bookmarks.length,
      hasSettings: settings.isNotEmpty,
      files: files,
    );

    final payloadBytes = bundleService.packBundle(
      manifest: manifest,
      recents: recents,
      favorites: favorites,
      bookmarks: bookmarks,
      settings: settings,
      files: files,
    );

    return BackupCrypto.encryptArchive(payloadBytes, password);
  }

  /// Decrypts [archiveBytes] using [password] and returns a parsed preview of the
  /// contents without writing anything to the database or settings.
  ///
  /// Throws [BackupCryptoException] if the password is wrong or archive is corrupted.
  BackupPreview inspectBackup({
    required Uint8List archiveBytes,
    required String password,
  }) {
    final decryptedBytes = BackupCrypto.decryptArchive(archiveBytes, password);
    return bundleService.unpackBundle(decryptedBytes);
  }

  /// Restores chosen items from [preview] into the database and preferences.
  Future<BackupRestoreResult> restoreBackup({
    required BackupPreview preview,
    required BackupRestoreOptions options,
  }) async {
    var restoredRecents = 0;
    var restoredFavorites = 0;
    var restoredBookmarks = 0;
    var restoredSettings = 0;
    var restoredFiles = 0;
    final warnings = <String>[];

    // 1. Recents
    if (options.restoreRecents && preview.recents.isNotEmpty) {
      try {
        if (!options.mergeMode) {
          await recentsRepo.clear();
        }
        for (final r in preview.recents) {
          await recentsRepo.upsert(r);
          restoredRecents++;
        }
      } catch (e) {
        warnings.add('Failed to restore recents: $e');
      }
    }

    // 2. Favorites
    if (options.restoreFavorites && preview.favorites.isNotEmpty) {
      try {
        if (!options.mergeMode) {
          await favoritesRepo.clear();
        }
        for (final f in preview.favorites) {
          await favoritesRepo.add(f);
          restoredFavorites++;
        }
      } catch (e) {
        warnings.add('Failed to restore favorites: $e');
      }
    }

    // 3. Bookmarks
    if (options.restoreBookmarks && preview.bookmarks.isNotEmpty) {
      try {
        if (!options.mergeMode) {
          await bookmarksRepo.clear();
        }
        for (final b in preview.bookmarks) {
          await bookmarksRepo.add(b);
          restoredBookmarks++;
        }
      } catch (e) {
        warnings.add('Failed to restore bookmarks: $e');
      }
    }

    // 4. Settings
    if (options.restoreSettings && preview.settings.isNotEmpty) {
      try {
        await store.restoreNonSensitiveSettings(preview.settings);
        restoredSettings = preview.settings.length;
      } catch (e) {
        warnings.add('Failed to restore settings: $e');
      }
    }

    // 5. Files count (metadata restored)
    if (options.restoreFiles) {
      restoredFiles = preview.files.where((f) => f.bytes != null).length;
    }

    return BackupRestoreResult(
      restoredRecents: restoredRecents,
      restoredFavorites: restoredFavorites,
      restoredBookmarks: restoredBookmarks,
      restoredSettings: restoredSettings,
      restoredFiles: restoredFiles,
      warnings: warnings,
    );
  }
}
