import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/ephemeral/ephemeral_controller.dart';
import 'package:text_data/core/ephemeral/ephemeral_models.dart';
import 'package:text_data/core/index/index_providers.dart';
import 'package:text_data/core/index/search_index_repository.dart';
import 'package:text_data/core/index/search_index_service.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/bookmarks_repository.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';
import 'package:text_data/core/storage/favorites_repository.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/recents_repository.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/storage/storage_models.dart';
import 'package:text_data/core/storage/storage_providers.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/shell/tabs/tabs_persistence.dart';

import '../../support/test_support.dart';

SafFile file(String id) => SafFile(
  uri: 'content://$id',
  displayName: '$id.txt',
  mimeType: 'text/plain',
  size: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late Directory tempDir;
  late KeyValueStore store;
  late DraftStore drafts;
  late RecentsRepository recents;
  late SearchIndexService index;
  late ProviderContainer container;

  /// A movable clock, so expiry is driven by the test rather than real time.
  var now = 1_000_000;

  setUp(() async {
    now = 1_000_000;
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    tempDir = await Directory.systemTemp.createTemp('ephemeral_controller');
    store = await inMemoryKeyValueStore();
    drafts = DraftStore(
      baseDir: tempDir,
      index: DraftsIndexRepository(database.db),
    );
    recents = RecentsRepository(database.db);
    index = SearchIndexService(
      SearchIndexRepository(database.db, ftsAvailable: database.ftsAvailable),
    );

    container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(store),
        safServiceProvider.overrideWithValue(FakeSafService()),
        deviceMemoryProvider.overrideWithValue(
          const FakeDeviceMemory(4 * 1024 * 1024 * 1024),
        ),
        draftStoreProvider.overrideWith((ref) async => drafts),
        recentsRepositoryProvider.overrideWith((ref) async => recents),
        favoritesRepositoryProvider.overrideWith(
          (ref) async => FavoritesRepository(database.db),
        ),
        bookmarksRepositoryProvider.overrideWith(
          (ref) async => BookmarksRepository(database.db),
        ),
        searchIndexServiceProvider.overrideWith((ref) async => index),
      ],
    );
    addTearDown(container.dispose);

    container.read(ephemeralControllerProvider.notifier).setClock(() => now);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  EphemeralController ephemeralOf() =>
      container.read(ephemeralControllerProvider.notifier);
  TabsController tabsOf() => container.read(tabsControllerProvider.notifier);

  /// Opens a tab and returns it.
  DocumentTab openTab(String id, String fingerprint) {
    tabsOf().openFile(file(id), fingerprint);
    return container.read(tabsControllerProvider).activeTab!;
  }

  group('marking', () {
    test('mark records a timer and cancel removes it', () {
      final tab = openTab('a', '10-aaa');

      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.fifteenMinutes),
      );

      expect(ephemeralOf().isEphemeral(tab.id), isTrue);
      expect(
        ephemeralOf().markFor(tab.id)!.expiresAtMillis,
        now + 15 * 60 * 1000,
      );
      expect(ephemeralOf().remainingFor(tab.id), const Duration(minutes: 15));

      ephemeralOf().cancel(tab.id);
      expect(ephemeralOf().isEphemeral(tab.id), isFalse);
    });

    test('a no-op option is ignored', () {
      final tab = openTab('a', '10-aaa');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(
          duration: EphemeralDuration.none,
          burnAfterOutput: false,
        ),
      );
      expect(ephemeralOf().isEphemeral(tab.id), isFalse);
    });

    test('burn-after-output alone is a valid mark with no timer', () {
      final tab = openTab('a', '10-aaa');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(
          duration: EphemeralDuration.none,
          burnAfterOutput: true,
        ),
      );
      expect(ephemeralOf().isEphemeral(tab.id), isTrue);
      expect(ephemeralOf().markFor(tab.id)!.hasTimer, isFalse);
      expect(ephemeralOf().remainingFor(tab.id), isNull);
    });
  });

  group('expiry', () {
    test('a tick before the expiry changes nothing', () async {
      final tab = openTab('a', '10-aaa');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.oneHour),
      );

      now += 59 * 60 * 1000;
      await ephemeralOf().tick();

      expect(ephemeralOf().isEphemeral(tab.id), isTrue);
      expect(container.read(tabsControllerProvider).tabs, hasLength(1));
    });

    test('a tick past the expiry burns the tab and wipes its traces', () async {
      final tab = openTab('a', '10-aaa');
      await drafts.save(tab.fingerprint, 'private notes');
      await recents.upsert(
        RecentFile(
          fingerprint: tab.fingerprint,
          uri: tab.uri,
          displayName: 'a.txt',
          lastOpenedAt: 1,
        ),
      );
      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.fifteenMinutes),
      );

      now += 15 * 60 * 1000;
      await ephemeralOf().tick();

      expect(container.read(tabsControllerProvider).tabs, isEmpty);
      expect(ephemeralOf().isEphemeral(tab.id), isFalse);
      expect(await drafts.hasDraft(tab.fingerprint), isFalse);
      expect(await recents.byFingerprint(tab.fingerprint), isNull);
    });

    test('a burn closes the tab even with unsaved edits', () async {
      final tab = openTab('a', '10-aaa');
      tabsOf().setDirty(tab.id, true);
      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.fifteenMinutes),
      );

      now += 15 * 60 * 1000;
      await ephemeralOf().tick();

      // Marking the tab ephemeral was the user's decision to discard it, so the
      // unsaved-changes guard does not apply here.
      expect(container.read(tabsControllerProvider).tabs, isEmpty);
    });
  });

  group('burn after output', () {
    test('fires once the output completes', () async {
      final tab = openTab('a', '10-aaa');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(
          duration: EphemeralDuration.none,
          burnAfterOutput: true,
        ),
      );

      await ephemeralOf().notifyOutputCompleted(tab.id);

      expect(container.read(tabsControllerProvider).tabs, isEmpty);
    });

    test('does nothing for a tab that only has a timer', () async {
      final tab = openTab('a', '10-aaa');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.oneHour),
      );

      await ephemeralOf().notifyOutputCompleted(tab.id);

      expect(ephemeralOf().isEphemeral(tab.id), isTrue);
      expect(container.read(tabsControllerProvider).tabs, hasLength(1));
    });

    test('does nothing for a tab that is not ephemeral', () async {
      final tab = openTab('a', '10-aaa');
      await ephemeralOf().notifyOutputCompleted(tab.id);
      expect(container.read(tabsControllerProvider).tabs, hasLength(1));
    });
  });

  group('closing by other routes', () {
    test('a tab closed by hand still has its traces wiped', () async {
      final tab = openTab('a', '10-aaa');
      final fingerprint = tab.fingerprint;
      await drafts.save(fingerprint, 'private notes');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.oneHour),
      );

      tabsOf().closeTab(tab.id);
      await ephemeralOf().syncOpenTabs(
        container.read(tabsControllerProvider).tabs.map((t) => t.id).toSet(),
      );

      expect(ephemeralOf().isEphemeral(tab.id), isFalse);
      expect(await drafts.hasDraft(fingerprint), isFalse);
    });

    test('syncOpenTabs leaves marks for tabs that are still open', () {
      final tab = openTab('a', '10-aaa');
      ephemeralOf().mark(
        tab,
        const EphemeralOption(duration: EphemeralDuration.oneHour),
      );
      ephemeralOf().syncOpenTabs({tab.id});
      expect(ephemeralOf().isEphemeral(tab.id), isTrue);
    });
  });

  group('persistence', () {
    test('an ephemeral tab is never written to the saved tab set', () async {
      await tabsOf().setRestoreOnRelaunch(true);
      final keep = openTab('keep', '10-keep');
      final secret = openTab('secret', '20-secret');

      ephemeralOf().mark(
        secret,
        const EphemeralOption(duration: EphemeralDuration.oneHour),
      );
      // Any tab change re-saves the set; opening a third tab is the trigger.
      openTab('another', '30-another');

      final saved = store.getPlainString(TabsPersistence.openTabsKey) ?? '';
      expect(saved, contains('content://keep'));
      expect(saved, contains('content://another'));
      expect(
        saved,
        isNot(contains('content://secret')),
        reason: 'an ephemeral tab must not survive a relaunch',
      );
      expect(keep.id, isNotNull);
    });
  });

  group('burnAll', () {
    test('burns every ephemeral tab and leaves the rest', () async {
      final normal = openTab('normal', '10-normal');
      final one = openTab('one', '20-one');
      final two = openTab('two', '30-two');

      ephemeralOf().mark(
        one,
        const EphemeralOption(duration: EphemeralDuration.oneHour),
      );
      ephemeralOf().mark(
        two,
        const EphemeralOption(
          duration: EphemeralDuration.none,
          burnAfterOutput: true,
        ),
      );

      await ephemeralOf().burnAll();

      final left = container.read(tabsControllerProvider).tabs;
      expect(left, hasLength(1));
      expect(left.single.id, normal.id);
      expect(ephemeralOf().ephemeralTabIds, isEmpty);
    });
  });
}
