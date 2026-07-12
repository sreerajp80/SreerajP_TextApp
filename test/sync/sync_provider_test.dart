import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/bookmarks_repository.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/preferences_store.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/secure_store.dart';
import 'package:text_data/core/storage/storage_models.dart';
import 'package:text_data/sync/sync_constants.dart';
import 'package:text_data/sync/sync_data_access.dart';
import 'package:text_data/sync/sync_provider.dart';

Future<KeyValueStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PreferencesStore.open();
  return KeyValueStore(
    prefs: prefs,
    secure: InMemorySecureStore(),
    sensitiveKeys: const {'device_key', 'app_lock_pin'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  late AppDatabase hostDb;
  late AppDatabase clientDb;
  late Directory tempDir;

  setUp(() async {
    // Two DISTINCT on-disk DBs. (Two `inMemoryDatabasePath` opens would share
    // one FFI instance, so the client would already "have" the host's data.)
    tempDir = await Directory.systemTemp.createTemp('sync_test_');
    hostDb = await AppDatabase.open(
      path: '${tempDir.path}/host.db',
      factory: databaseFactoryFfi,
    );
    clientDb = await AppDatabase.open(
      path: '${tempDir.path}/client.db',
      factory: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await hostDb.close();
    await clientDb.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('full loopback flow: connect -> push -> import summary + DB writes',
      () async {
    // Seed the host with data to share.
    final hostFav = FavoritesRepository(hostDb.db);
    final hostBook = BookmarksRepository(hostDb.db);
    await hostFav.add(const Favorite(
      fingerprint: 'fp1',
      uri: 'content://1',
      displayName: 'one.txt',
      addedAt: 100,
    ));
    await hostBook.add(const Bookmark(
      fingerprint: 'fp1',
      label: 'Chapter 1',
      position: 42,
      createdAt: 200,
    ));

    final hostStore = await _store();
    // Use the real namespaced storage keys the app actually writes, across two
    // namespaces (appearance.* and tabs.*), so the round-trip proves settings
    // sync with the true key names — not a bare test-only key.
    await hostStore.setPlainString('appearance.theme_mode', 'dark');
    await hostStore.setPlainString('tabs.over_limit', 'close_lru');

    final hostAccess = RepositorySyncDataAccess(
      favorites: hostFav,
      bookmarks: hostBook,
      recents: RecentsRepository(hostDb.db),
      store: hostStore,
    );

    // Client starts empty.
    final clientFav = FavoritesRepository(clientDb.db);
    final clientBook = BookmarksRepository(clientDb.db);
    final clientStore = await _store();
    final clientAccess = RepositorySyncDataAccess(
      favorites: clientFav,
      bookmarks: clientBook,
      recents: RecentsRepository(clientDb.db),
      store: clientStore,
    );

    final host = SyncController(dataAccess: hostAccess, store: hostStore);
    final client = SyncController(dataAccess: clientAccess, store: clientStore);
    addTearDown(host.dispose);
    addTearDown(client.dispose);

    await host.startHost();
    expect(host.pairingCode, isNotNull);
    final code = host.pairingCode!;
    final port = host.port!;

    // Client connects; when the host sees the client, it pushes a full sync.
    final clientFuture =
        client.connectManual(host: '127.0.0.1', port: port, code: code);

    // Wait until the host reports a connected client, then push.
    await _until(() => host.hostConnected);
    await host.pushFullSync();

    await clientFuture;

    expect(client.clientPhase, ClientPhase.done);
    final summary = client.summary!;
    expect(summary.records[SyncConstants.categoryFavorites]!.added, 1);
    expect(summary.records[SyncConstants.categoryBookmarks]!.added, 1);
    expect(summary.settings.applied, greaterThanOrEqualTo(1));

    // The data really landed in the client DB / store.
    expect((await clientFav.all()).single.fingerprint, 'fp1');
    expect((await clientBook.all()).single.label, 'Chapter 1');
    expect(clientStore.getPlainString('appearance.theme_mode'), 'dark');
    expect(clientStore.getPlainString('tabs.over_limit'), 'close_lru');
  });

  test('onApplied fires once with the summary after a successful receive',
      () async {
    // Seed the host with a recent so the payload has records to import.
    final hostRecents = RecentsRepository(hostDb.db);
    await hostRecents.upsert(const RecentFile(
      fingerprint: 'rfp1',
      uri: 'content://recent/1',
      displayName: 'backup.json',
      mimeType: 'application/json',
      size: 12,
      lastOpenedAt: 500,
    ));

    final hostStore = await _store();
    final hostAccess = RepositorySyncDataAccess(
      favorites: FavoritesRepository(hostDb.db),
      bookmarks: BookmarksRepository(hostDb.db),
      recents: hostRecents,
      store: hostStore,
    );
    final clientStore = await _store();
    final clientAccess = RepositorySyncDataAccess(
      favorites: FavoritesRepository(clientDb.db),
      bookmarks: BookmarksRepository(clientDb.db),
      recents: RecentsRepository(clientDb.db),
      store: clientStore,
    );

    var callCount = 0;
    SyncSummary? applied;
    final host = SyncController(dataAccess: hostAccess, store: hostStore);
    final client = SyncController(
      dataAccess: clientAccess,
      store: clientStore,
      onApplied: (summary) {
        callCount++;
        applied = summary;
      },
    );
    addTearDown(host.dispose);
    addTearDown(client.dispose);

    await host.startHost();
    final clientFuture = client.connectManual(
        host: '127.0.0.1', port: host.port!, code: host.pairingCode!);
    await _until(() => host.hostConnected);
    await host.pushFullSync();
    await clientFuture;

    expect(client.clientPhase, ClientPhase.done);
    expect(callCount, 1);
    // The callback gets the same summary the UI shows, with the imported recent.
    expect(identical(applied, client.summary), isTrue);
    expect(applied!.records[SyncConstants.categoryRecents]!.added, 1);
  });

  test('onApplied does not fire when the receive fails (wrong code)', () async {
    final hostStore = await _store();
    final hostAccess = RepositorySyncDataAccess(
      favorites: FavoritesRepository(hostDb.db),
      bookmarks: BookmarksRepository(hostDb.db),
      recents: RecentsRepository(hostDb.db),
      store: hostStore,
    );
    final clientStore = await _store();
    final clientAccess = RepositorySyncDataAccess(
      favorites: FavoritesRepository(clientDb.db),
      bookmarks: BookmarksRepository(clientDb.db),
      recents: RecentsRepository(clientDb.db),
      store: clientStore,
    );

    var callCount = 0;
    final host = SyncController(dataAccess: hostAccess, store: hostStore);
    final client = SyncController(
      dataAccess: clientAccess,
      store: clientStore,
      onApplied: (_) => callCount++,
    );
    addTearDown(host.dispose);
    addTearDown(client.dispose);

    await host.startHost();
    final wrong = 'A' * SyncConstants.codeLength;
    await client.connectManual(host: '127.0.0.1', port: host.port!, code: wrong);

    expect(client.clientPhase, ClientPhase.error);
    expect(callCount, 0);
  });

  test('a wrong code fails the client and connects nothing', () async {
    final hostStore = await _store();
    final hostAccess = RepositorySyncDataAccess(
      favorites: FavoritesRepository(hostDb.db),
      bookmarks: BookmarksRepository(hostDb.db),
      recents: RecentsRepository(hostDb.db),
      store: hostStore,
    );
    final clientStore = await _store();
    final clientAccess = RepositorySyncDataAccess(
      favorites: FavoritesRepository(clientDb.db),
      bookmarks: BookmarksRepository(clientDb.db),
      recents: RecentsRepository(clientDb.db),
      store: clientStore,
    );

    final host = SyncController(dataAccess: hostAccess, store: hostStore);
    final client = SyncController(dataAccess: clientAccess, store: clientStore);
    addTearDown(host.dispose);
    addTearDown(client.dispose);

    await host.startHost();
    // Type a valid-shaped but wrong code.
    final wrong = 'A' * SyncConstants.codeLength;
    await client.connectManual(host: '127.0.0.1', port: host.port!, code: wrong);
    expect(client.clientPhase, ClientPhase.error);
    expect(host.hostConnected, isFalse);
  });
}

/// Polls [predicate] until true or a short timeout.
Future<void> _until(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('condition not met in time');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
