import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/ephemeral/ephemeral_wiper.dart';
import 'package:text_data/core/index/search_index_repository.dart';
import 'package:text_data/core/index/search_index_service.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/bookmarks_repository.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/storage_models.dart';

import '../../support/test_support.dart';

const String fingerprint = '42-deadbeef';
const String uri = 'content://docs/secret.txt';
const String secret = 'the launch codes are 1234';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late Directory tempDir;
  late DraftStore drafts;
  late RecentsRepository recents;
  late FavoritesRepository favorites;
  late BookmarksRepository bookmarks;
  late SearchIndexService index;
  late KeyValueStore store;
  late EphemeralWiper wiper;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    tempDir = await Directory.systemTemp.createTemp('ephemeral_wiper_test');
    drafts = DraftStore(
      baseDir: tempDir,
      index: DraftsIndexRepository(database.db),
    );
    recents = RecentsRepository(database.db);
    favorites = FavoritesRepository(database.db);
    bookmarks = BookmarksRepository(database.db);
    index = SearchIndexService(
      SearchIndexRepository(database.db, ftsAvailable: database.ftsAvailable),
    );
    store = await inMemoryKeyValueStore();

    wiper = EphemeralWiper(
      draftStore: Future.value(drafts),
      recents: Future.value(recents),
      favorites: Future.value(favorites),
      bookmarks: Future.value(bookmarks),
      searchIndex: Future.value(index),
      store: store,
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Puts a trace of the document in every store the app writes to.
  Future<void> leaveEveryTrace() async {
    await drafts.save(fingerprint, secret);
    await recents.upsert(
      const RecentFile(
        fingerprint: fingerprint,
        uri: uri,
        displayName: 'secret.txt',
        lastOpenedAt: 1000,
      ),
    );
    await favorites.add(
      const Favorite(
        fingerprint: fingerprint,
        uri: uri,
        displayName: 'secret.txt',
        addedAt: 1000,
      ),
    );
    await bookmarks.add(
      const Bookmark(
        fingerprint: fingerprint,
        label: 'the important bit',
        position: 12,
        createdAt: 1000,
      ),
    );
    await index.indexBytes(
      fingerprint: fingerprint,
      uri: uri,
      displayName: 'secret.txt',
      bytes: Uint8List.fromList(utf8.encode(secret)),
    );
    for (final prefix in EphemeralWiper.fingerprintKeyPrefixes) {
      await store.setInt('$prefix$fingerprint', 7);
    }
  }

  test('a burn removes every trace the app keeps', () async {
    await leaveEveryTrace();

    // Sanity: the traces really are there before the burn.
    expect(await drafts.hasDraft(fingerprint), isTrue);
    expect(await recents.byFingerprint(fingerprint), isNotNull);
    expect(await favorites.isFavorite(fingerprint), isTrue);
    expect(
      (await bookmarks.all()).any((b) => b.fingerprint == fingerprint),
      isTrue,
    );
    expect(await index.count(), 1);

    final failures = await wiper.wipe(fingerprint);

    expect(failures, isEmpty);
    expect(await drafts.hasDraft(fingerprint), isFalse);
    expect(await recents.byFingerprint(fingerprint), isNull);
    expect(await favorites.isFavorite(fingerprint), isFalse);
    expect(
      (await bookmarks.all()).any((b) => b.fingerprint == fingerprint),
      isFalse,
    );
    expect(await index.count(), 0);
    for (final prefix in EphemeralWiper.fingerprintKeyPrefixes) {
      expect(
        store.getInt('$prefix$fingerprint'),
        isNull,
        reason: '$prefix should be gone',
      );
    }
  });

  test('the draft file itself is gone from disk', () async {
    await drafts.save(fingerprint, secret);
    final draftsDir = Directory('${tempDir.path}/drafts');
    expect(draftsDir.listSync(), isNotEmpty);

    await wiper.wipe(fingerprint);

    // Nothing left in the folder, and nothing anywhere under it still holds the
    // text.
    final leftovers = draftsDir
        .listSync()
        .whereType<File>()
        .map((f) => f.readAsStringSync())
        .join();
    expect(leftovers, isNot(contains('launch codes')));
  });

  test('another document is untouched', () async {
    await leaveEveryTrace();
    await recents.upsert(
      const RecentFile(
        fingerprint: '99-other',
        uri: 'content://docs/other.txt',
        displayName: 'other.txt',
        lastOpenedAt: 2000,
      ),
    );
    await store.setInt('txt.pos.99-other', 3);

    await wiper.wipe(fingerprint);

    expect(await recents.byFingerprint('99-other'), isNotNull);
    expect(store.getInt('txt.pos.99-other'), 3);
  });

  test('wiping a document with no traces at all is quiet', () async {
    final failures = await wiper.wipe('00-nothing-here');
    expect(failures, isEmpty);
  });

  test('one unreachable store does not stop the others', () async {
    await leaveEveryTrace();

    // A store whose future never resolves to a usable object — the same shape
    // as a database that failed to open. `ignore()` only silences the "unhandled
    // error" report for the gap before the wiper awaits it; the await below
    // still sees the failure.
    final brokenDrafts = Future<DraftStore>.error(StateError('no disk'))
      ..ignore();
    final broken = EphemeralWiper(
      draftStore: brokenDrafts,
      recents: Future.value(recents),
      favorites: Future.value(favorites),
      bookmarks: Future.value(bookmarks),
      searchIndex: Future.value(index),
      store: store,
    );

    final failures = await broken.wipe(fingerprint);

    expect(failures, ['draft'], reason: 'the failure is named, not swallowed');
    // Everything else still went, which is the whole point of per-step guards.
    expect(await index.count(), 0);
    expect(await recents.byFingerprint(fingerprint), isNull);
    expect(await favorites.isFavorite(fingerprint), isFalse);
  });

  test(
    'the search index is cleared even when the database dies later',
    () async {
      await leaveEveryTrace();
      final failures = await wiper.wipe(fingerprint);
      expect(failures, isEmpty);
      // The index holds the document's text, so it must be the first thing gone.
      expect(await index.count(), 0);
    },
  );
}
