import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/bookmarks_repository.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/storage_models.dart';

void main() {
  // Run sqflite on the host with an in-memory database (no device needed).
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });

  tearDown(() => database.close());

  group('RecentsRepository', () {
    test('insert, read, update position, delete', () async {
      final repo = RecentsRepository(database.db);
      await repo.upsert(const RecentFile(
        fingerprint: '10-aaa',
        uri: 'content://1',
        displayName: 'a.txt',
        lastOpenedAt: 100,
      ));
      await repo.upsert(const RecentFile(
        fingerprint: '20-bbb',
        uri: 'content://2',
        displayName: 'b.txt',
        lastOpenedAt: 200,
      ));

      final all = await repo.all();
      expect(all.length, 2);
      // Newest first.
      expect(all.first.fingerprint, '20-bbb');

      await repo.updateScrollPosition('10-aaa', 555);
      final one = await repo.byFingerprint('10-aaa');
      expect(one!.scrollPosition, 555);

      await repo.remove('10-aaa');
      expect(await repo.byFingerprint('10-aaa'), isNull);

      await repo.clear();
      expect(await repo.all(), isEmpty);
    });

    test('upsert replaces on the same fingerprint', () async {
      final repo = RecentsRepository(database.db);
      await repo.upsert(const RecentFile(
        fingerprint: '10-aaa',
        uri: 'content://1',
        displayName: 'a.txt',
        lastOpenedAt: 100,
      ));
      await repo.upsert(const RecentFile(
        fingerprint: '10-aaa',
        uri: 'content://1b',
        displayName: 'a-renamed.txt',
        lastOpenedAt: 300,
      ));
      final all = await repo.all();
      expect(all.length, 1);
      expect(all.first.displayName, 'a-renamed.txt');
    });
  });

  group('BookmarksRepository', () {
    test('add assigns id, list in order, remove', () async {
      final repo = BookmarksRepository(database.db);
      final b1 = await repo.add(const Bookmark(
        fingerprint: 'fp',
        label: 'second',
        position: 20,
        createdAt: 2,
      ));
      await repo.add(const Bookmark(
        fingerprint: 'fp',
        label: 'first',
        position: 10,
        createdAt: 1,
      ));
      expect(b1.id, isNotNull);

      final list = await repo.forFile('fp');
      expect(list.map((b) => b.label), ['first', 'second']);

      await repo.remove(b1.id!);
      expect((await repo.forFile('fp')).length, 1);

      await repo.clearForFile('fp');
      expect(await repo.forFile('fp'), isEmpty);
    });
  });

  group('FavoritesRepository', () {
    test('add, isFavorite, list, remove', () async {
      final repo = FavoritesRepository(database.db);
      await repo.add(const Favorite(
        fingerprint: 'fp1',
        uri: 'content://1',
        displayName: 'x',
        addedAt: 1,
      ));
      expect(await repo.isFavorite('fp1'), isTrue);
      expect(await repo.isFavorite('nope'), isFalse);
      expect((await repo.all()).length, 1);
      await repo.remove('fp1');
      expect(await repo.isFavorite('fp1'), isFalse);
    });
  });

  group('DraftsIndexRepository', () {
    test('upsert, read, list, remove', () async {
      final repo = DraftsIndexRepository(database.db);
      await repo.upsert(const DraftIndexEntry(
        fingerprint: 'fp',
        draftPath: '/drafts/fp.tmp',
        updatedAt: 5,
      ));
      final entry = await repo.byFingerprint('fp');
      expect(entry!.draftPath, '/drafts/fp.tmp');
      expect((await repo.all()).length, 1);
      await repo.remove('fp');
      expect(await repo.byFingerprint('fp'), isNull);
    });
  });

  test('database reports the expected schema version', () async {
    final version = await database.db.getVersion();
    expect(version, AppDatabase.version);
  });
}
