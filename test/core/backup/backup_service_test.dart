import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/backup/backup_bundle_service.dart';
import 'package:text_data/core/backup/backup_crypto.dart';
import 'package:text_data/core/backup/backup_models.dart';
import 'package:text_data/core/backup/backup_service.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/bookmarks_repository.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/preferences_store.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/secure_store.dart';
import 'package:text_data/core/storage/storage_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db1;
  late AppDatabase db2;
  late KeyValueStore store1;
  late KeyValueStore store2;
  late InMemorySecureStore secure1;
  late InMemorySecureStore secure2;
  late BackupService service1;
  late BackupService service2;

  setUp(() async {
    db1 = await AppDatabase.open(
      path: 'backup_test_db1.db',
      factory: databaseFactoryFfi,
    );
    db2 = await AppDatabase.open(
      path: 'backup_test_db2.db',
      factory: databaseFactoryFfi,
    );
    await RecentsRepository(db1.db).clear();
    await FavoritesRepository(db1.db).clear();
    await BookmarksRepository(db1.db).clear();
    await RecentsRepository(db2.db).clear();
    await FavoritesRepository(db2.db).clear();
    await BookmarksRepository(db2.db).clear();

    SharedPreferences.setMockInitialValues({});
    final prefs1 = await PreferencesStore.open();
    secure1 = InMemorySecureStore();
    store1 = KeyValueStore(
      prefs: prefs1,
      secure: secure1,
      sensitiveKeys: const {'device_key', 'app_lock_pin', 'app_lock_recovery'},
    );

    final prefs2 = await PreferencesStore.open();
    secure2 = InMemorySecureStore();
    store2 = KeyValueStore(
      prefs: prefs2,
      secure: secure2,
      sensitiveKeys: const {'device_key', 'app_lock_pin', 'app_lock_recovery'},
    );

    const bundleService = BackupBundleService();

    service1 = BackupService(
      recentsRepo: RecentsRepository(db1.db),
      favoritesRepo: FavoritesRepository(db1.db),
      bookmarksRepo: BookmarksRepository(db1.db),
      store: store1,
      bundleService: bundleService,
    );

    service2 = BackupService(
      recentsRepo: RecentsRepository(db2.db),
      favoritesRepo: FavoritesRepository(db2.db),
      bookmarksRepo: BookmarksRepository(db2.db),
      store: store2,
      bundleService: bundleService,
    );
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
  });

  group('BackupService', () {
    test(
      'full export, inspect, and restore across distinct instances',
      () async {
        final recentsRepo1 = RecentsRepository(db1.db);
        final favoritesRepo1 = FavoritesRepository(db1.db);
        final bookmarksRepo1 = BookmarksRepository(db1.db);

        // Populate instance 1
        await recentsRepo1.upsert(
          const RecentFile(
            fingerprint: 'rec-1',
            uri: 'content://saf/doc1.txt',
            displayName: 'doc1.txt',
            lastOpenedAt: 1000,
          ),
        );
        await favoritesRepo1.add(
          const Favorite(
            fingerprint: 'fav-1',
            uri: 'content://saf/fav.csv',
            displayName: 'fav.csv',
            addedAt: 2000,
          ),
        );
        await bookmarksRepo1.add(
          const Bookmark(
            fingerprint: 'rec-1',
            label: 'Section 1',
            position: 100,
            createdAt: 3000,
          ),
        );

        // Settings in store 1
        await store1.setString('appearance.theme_mode', 'sepia');
        await store1.setBool('appearance.word_wrap', false);
        await store1.setString('device_key', 'SECRET_DEVICE_KEY_NEVER_EXPORT');

        const password = 'Password#2026';

        // 1. Create encrypted backup
        final archiveBytes = await service1.createBackup(
          password: password,
          options: const BackupExportOptions(
            includeRecents: true,
            includeFavorites: true,
            includeBookmarks: true,
            includeSettings: true,
          ),
        );

        expect(archiveBytes, isNotEmpty);

        // 2. Inspect preview on instance 2
        final preview = service2.inspectBackup(
          archiveBytes: archiveBytes,
          password: password,
        );

        expect(preview.recents.length, equals(1));
        expect(preview.recents.first.displayName, equals('doc1.txt'));
        expect(preview.favorites.length, equals(1));
        expect(preview.favorites.first.displayName, equals('fav.csv'));
        expect(preview.bookmarks.length, equals(1));
        expect(preview.bookmarks.first.label, equals('Section 1'));
        expect(preview.settings['appearance.theme_mode'], equals('sepia'));
        // Verify sensitive key was NOT exported
        expect(preview.settings.containsKey('device_key'), isFalse);

        // 3. Restore to instance 2
        final result = await service2.restoreBackup(
          preview: preview,
          options: const BackupRestoreOptions(
            restoreRecents: true,
            restoreFavorites: true,
            restoreBookmarks: true,
            restoreSettings: true,
            mergeMode: true,
          ),
        );

        expect(result.restoredRecents, equals(1));
        expect(result.restoredFavorites, equals(1));
        expect(result.restoredBookmarks, equals(1));
        expect(result.restoredSettings, greaterThanOrEqualTo(2));
        expect(result.isSuccessful, isTrue);

        // Verify instance 2 database state
        final recentsRepo2 = RecentsRepository(db2.db);
        final favoritesRepo2 = FavoritesRepository(db2.db);
        final bookmarksRepo2 = BookmarksRepository(db2.db);

        final recents2 = await recentsRepo2.all();
        expect(recents2.length, equals(1));
        expect(recents2.first.fingerprint, equals('rec-1'));

        final fav2 = await favoritesRepo2.all();
        expect(fav2.length, equals(1));
        expect(fav2.first.fingerprint, equals('fav-1'));

        final bm2 = await bookmarksRepo2.all();
        expect(bm2.length, equals(1));
        expect(bm2.first.label, equals('Section 1'));

        expect(
          await store2.getString('appearance.theme_mode'),
          equals('sepia'),
        );
        expect(store2.getBool('appearance.word_wrap'), isFalse);
      },
    );

    test('selective restore only restores chosen categories', () async {
      final recentsRepo1 = RecentsRepository(db1.db);
      await recentsRepo1.upsert(
        const RecentFile(
          fingerprint: 'rec-1',
          uri: 'content://saf/doc1.txt',
          displayName: 'doc1.txt',
          lastOpenedAt: 1000,
        ),
      );
      await store1.setString('appearance.theme_mode', 'dark');

      final archiveBytes = await service1.createBackup(
        password: 'Password123',
        options: const BackupExportOptions(
          includeRecents: true,
          includeSettings: true,
        ),
      );

      final preview = service2.inspectBackup(
        archiveBytes: archiveBytes,
        password: 'Password123',
      );

      // Restore ONLY settings, NOT recents
      final result = await service2.restoreBackup(
        preview: preview,
        options: const BackupRestoreOptions(
          restoreRecents: false,
          restoreFavorites: false,
          restoreBookmarks: false,
          restoreSettings: true,
        ),
      );

      expect(result.restoredRecents, equals(0));
      expect(result.restoredSettings, greaterThanOrEqualTo(1));

      final recentsRepo2 = RecentsRepository(db2.db);
      expect(await recentsRepo2.all(), isEmpty);
      expect(await store2.getString('appearance.theme_mode'), equals('dark'));
    });

    test('inspect with wrong password throws BackupCryptoException', () async {
      final archiveBytes = await service1.createBackup(
        password: 'CorrectPassword123',
        options: const BackupExportOptions(),
      );

      expect(
        () => service2.inspectBackup(
          archiveBytes: archiveBytes,
          password: 'WrongPassword456',
        ),
        throwsA(isA<BackupCryptoException>()),
      );
    });
  });
}
