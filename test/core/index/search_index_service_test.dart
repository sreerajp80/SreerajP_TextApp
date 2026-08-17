import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sreerajp_textapp/core/index/search_index_backfill.dart';
import 'package:sreerajp_textapp/core/index/search_index_models.dart';
import 'package:sreerajp_textapp/core/index/search_index_repository.dart';
import 'package:sreerajp_textapp/core/index/search_index_service.dart';
import 'package:sreerajp_textapp/core/storage/app_database.dart';
import 'package:sreerajp_textapp/core/storage/favorites_repository.dart';
import 'package:sreerajp_textapp/core/storage/recents_repository.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/storage/storage_models.dart';

/// A SAF stand-in that serves bytes from a map, so the backfill can be tested
/// with no device and no real files.
class _FakeSaf implements SafService {
  final Map<String, Uint8List> files;

  _FakeSaf(this.files);

  @override
  Future<Uint8List> readBytes(String uri) async {
    final bytes = files[uri];
    if (bytes == null) throw const SafUriStale();
    return bytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used in tests');
}

Uint8List _text(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late SearchIndexRepository repo;
  late SearchIndexService service;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repo = SearchIndexRepository(
      database.db,
      ftsAvailable: database.ftsAvailable,
    );
    service = SearchIndexService(repo);
  });

  tearDown(() => database.close());

  group('eligibility', () {
    test('a normal text file is indexed', () {
      expect(
        SearchIndexService.eligibility(_text('hello')),
        IndexSkipReason.none,
      );
    });

    test('binary content is skipped', () {
      final bytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0x00, 0x01]);
      expect(SearchIndexService.eligibility(bytes), IndexSkipReason.binary);
    });

    test('an oversized file is skipped without reading it all', () {
      expect(
        SearchIndexService.eligibility(_text('small'), size: 60 * 1024 * 1024),
        IndexSkipReason.tooLarge,
      );
    });

    test('an empty file is fine', () {
      expect(
        SearchIndexService.eligibility(Uint8List(0)),
        IndexSkipReason.none,
      );
    });
  });

  group('indexing', () {
    test('indexBytes decodes and stores the text', () async {
      final skipped = await service.indexBytes(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'notes.txt',
        bytes: _text('the quick brown fox'),
      );
      expect(skipped, IndexSkipReason.none);
      expect(await service.search('brown'), hasLength(1));
    });

    test('binary bytes are not indexed', () async {
      final skipped = await service.indexBytes(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'photo.bin',
        bytes: Uint8List.fromList([0x00, 0x01, 0x02, 0x03]),
      );
      expect(skipped, IndexSkipReason.binary);
      expect(await service.count(), 0);
    });

    test('wrong-encoding bytes never throw', () async {
      // Lone continuation bytes are not valid UTF-8.
      final broken = Uint8List.fromList([0x41, 0x80, 0x81, 0x42]);
      final skipped = await service.indexBytes(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'odd.txt',
        bytes: broken,
      );
      expect(skipped, IndexSkipReason.none);
      expect(await service.count(), 1);
    });

    test('a long file is stored up to the cap and marked truncated', () async {
      final long = 'x' * (SearchIndexService.maxBodyChars + 10);
      await service.indexText(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'big.txt',
        text: '$long needle',
      );
      final doc = await repo.byFingerprint('a');
      expect(doc, isNotNull);
      expect(doc!.truncated, isTrue);
      // The part past the cap is not searchable, which is what "partly
      // indexed" means on screen.
      expect(await service.search('needle'), isEmpty);
    });

    test('the format comes from the file name', () async {
      await service.indexText(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'data.csv',
        text: 'name,age',
      );
      expect((await repo.byFingerprint('a'))!.format, IndexFormat.csv);
    });

    test('re-indexing keeps a favorite pinned', () async {
      await service.indexText(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'fav.txt',
        text: 'first',
        pinned: true,
      );
      await service.indexText(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'fav.txt',
        text: 'second',
      );
      expect((await repo.byFingerprint('a'))!.pinned, isTrue);
    });

    test('a closed database never throws at the caller', () async {
      await database.close();
      final skipped = await service.indexText(
        fingerprint: 'a',
        uri: 'content://a',
        displayName: 'a.txt',
        text: 'text',
      );
      expect(skipped, IndexSkipReason.none);
      expect(await service.search('text'), isEmpty);
      // Re-open so tearDown's close() has something valid to close.
      database = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    });
  });

  group('backfill', () {
    test('indexes favorites and recents, skipping unreadable files', () async {
      final favorites = FavoritesRepository(database.db);
      final recents = RecentsRepository(database.db);
      await favorites.add(
        const Favorite(
          fingerprint: 'fav',
          uri: 'content://fav',
          displayName: 'fav.md',
          addedAt: 1,
        ),
      );
      await recents.upsert(
        const RecentFile(
          fingerprint: 'rec',
          uri: 'content://rec',
          displayName: 'rec.txt',
          lastOpenedAt: 2,
        ),
      );
      await recents.upsert(
        const RecentFile(
          fingerprint: 'gone',
          uri: 'content://gone',
          displayName: 'gone.txt',
          lastOpenedAt: 3,
        ),
      );

      final backfill = SearchIndexBackfill(
        index: service,
        recents: recents,
        favorites: favorites,
        saf: _FakeSaf({
          'content://fav': _text('favorite notes'),
          'content://rec': _text('recent notes'),
        }),
      );

      expect(await backfill.run(), 2);
      expect(await service.search('notes'), hasLength(2));
      // The favorite is pinned, so clearing recents keeps it.
      await service.removeUnpinned();
      final left = await service.search('notes');
      expect(left, hasLength(1));
      expect(left.single.displayName, 'fav.md');
    });

    test('a second pass adds nothing new', () async {
      final favorites = FavoritesRepository(database.db);
      final recents = RecentsRepository(database.db);
      await recents.upsert(
        const RecentFile(
          fingerprint: 'rec',
          uri: 'content://rec',
          displayName: 'rec.txt',
          lastOpenedAt: 2,
        ),
      );
      final backfill = SearchIndexBackfill(
        index: service,
        recents: recents,
        favorites: favorites,
        saf: _FakeSaf({'content://rec': _text('some words')}),
      );
      expect(await backfill.run(), 1);
      expect(await backfill.run(), 0);
      expect(await service.count(), 1);
    });
  });
}
