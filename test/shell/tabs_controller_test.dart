import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/over_limit_behavior.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/shell/tabs/tabs_persistence.dart';

import '../support/test_support.dart';

SafFile file(String id) => SafFile(
      uri: 'content://$id',
      displayName: '$id.txt',
      mimeType: 'text/plain',
      size: 10,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer({
    KeyValueStore? store,
    FakeSafService? saf,
  }) async {
    final kv = store ?? await inMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(kv),
        safServiceProvider.overrideWithValue(saf ?? FakeSafService()),
        deviceMemoryProvider
            .overrideWithValue(const FakeDeviceMemory(4 * 1024 * 1024 * 1024)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('opening two files yields two independent tab states (2.5)', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);

    expect(tabs.openFile(file('a'), '10-a'), OpenOutcome.opened);
    expect(tabs.openFile(file('b'), '20-b'), OpenOutcome.opened);

    var state = container.read(tabsControllerProvider);
    expect(state.tabs.length, 2);
    expect(state.activeTab?.fingerprint, '20-b'); // newest is active

    // Dirtying one tab must not touch the other.
    final first = state.tabs.first;
    tabs.setDirty(first.id, true);
    state = container.read(tabsControllerProvider);
    expect(state.tabs.firstWhere((t) => t.id == first.id).isDirty, isTrue);
    expect(state.tabs.last.isDirty, isFalse);
  });

  test('re-opening the same file focuses the existing tab', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.openFile(file('a'), '10-a');
    tabs.openFile(file('b'), '20-b');
    tabs.openFile(file('a'), '10-a'); // same fingerprint as the first

    final state = container.read(tabsControllerProvider);
    expect(state.tabs.length, 2);
    expect(state.activeTab?.fingerprint, '10-a');
  });

  test('over-limit closes the least-recently-used tab (2.6)', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.applyCap(2);

    tabs.openFile(file('a'), '10-a');
    tabs.openFile(file('b'), '20-b');
    // Make 'b' most recent, so 'a' is the LRU.
    final bId = container
        .read(tabsControllerProvider)
        .tabs
        .firstWhere((t) => t.fingerprint == '20-b')
        .id;
    tabs.setActive(bId);

    expect(tabs.openFile(file('c'), '30-c'), OpenOutcome.opened);

    final state = container.read(tabsControllerProvider);
    expect(state.tabs.length, 2);
    expect(state.tabs.any((t) => t.fingerprint == '10-a'), isFalse); // LRU gone
    expect(state.tabs.any((t) => t.fingerprint == '30-c'), isTrue);
  });

  test('an unsaved tab is never closed silently at the cap (2.6)', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.applyCap(2);

    tabs.openFile(file('a'), '10-a');
    tabs.openFile(file('b'), '20-b');
    // Mark both dirty — nothing can be auto-closed.
    for (final t in container.read(tabsControllerProvider).tabs) {
      tabs.setDirty(t.id, true);
    }

    expect(
      tabs.openFile(file('c'), '30-c'),
      OpenOutcome.cappedNeedsChoice,
    );
    final state = container.read(tabsControllerProvider);
    expect(state.tabs.length, 2); // unchanged; nothing closed
    expect(state.tabs.any((t) => t.fingerprint == '30-c'), isFalse);
  });

  test('closeTab refuses a dirty tab unless forced', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.openFile(file('a'), '10-a');
    final id = container.read(tabsControllerProvider).tabs.first.id;
    tabs.setDirty(id, true);

    expect(tabs.closeTab(id), isFalse); // blocked
    expect(container.read(tabsControllerProvider).tabs.length, 1);
    expect(tabs.closeTab(id, force: true), isTrue);
    expect(container.read(tabsControllerProvider).tabs, isEmpty);
  });

  test('next/prev cycle through tabs', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.applyCap(5);
    tabs.openFile(file('a'), '10-a');
    tabs.openFile(file('b'), '20-b');
    tabs.openFile(file('c'), '30-c'); // active = c (index 2)

    tabs.next(); // wraps to index 0
    expect(container.read(tabsControllerProvider).activeTab?.fingerprint,
        '10-a');
    tabs.prev(); // back to index 2
    expect(container.read(tabsControllerProvider).activeTab?.fingerprint,
        '30-c');
  });

  test('restore brings back accessible tabs and skips stale ones (2.8)',
      () async {
    final store = await inMemoryKeyValueStore();
    final saf = FakeSafService(accessibleUris: {'content://a'});

    // Seed a saved set: 'a' is reachable, 'gone' is not.
    final persistence = TabsPersistence(store, saf);
    await persistence.setRestoreEnabled(true);
    await persistence.save([
      DocumentTab(
        id: 'a#1',
        fingerprint: '10-a',
        uri: 'content://a',
        displayName: 'a.txt',
        lastActiveAt: 1,
      ),
      DocumentTab(
        id: 'gone#1',
        fingerprint: '20-gone',
        uri: 'content://gone',
        displayName: 'gone.txt',
        lastActiveAt: 2,
      ),
    ]);

    final container = await makeContainer(store: store, saf: saf);
    final tabs = container.read(tabsControllerProvider.notifier);

    final skipped = await tabs.restore();
    expect(skipped, 1);

    final state = container.read(tabsControllerProvider);
    expect(state.tabs.length, 1);
    expect(state.tabs.single.uri, 'content://a');
  });

  test('restore is a no-op when the toggle is off', () async {
    final store = await inMemoryKeyValueStore();
    final saf = FakeSafService(accessibleUris: {'content://a'});
    await TabsPersistence(store, saf).save([
      DocumentTab(
        id: 'a#1',
        fingerprint: '10-a',
        uri: 'content://a',
        displayName: 'a.txt',
        lastActiveAt: 1,
      ),
    ]);
    // restoreEnabled defaults to false.

    final container = await makeContainer(store: store, saf: saf);
    final skipped =
        await container.read(tabsControllerProvider.notifier).restore();
    expect(skipped, 0);
    expect(container.read(tabsControllerProvider).tabs, isEmpty);
  });

  test('over-limit behavior "ask" blocks auto-close', () async {
    final container = await makeContainer();
    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.applyCap(1);
    tabs.setOverLimitBehavior(OverLimitBehavior.ask);

    tabs.openFile(file('a'), '10-a');
    expect(tabs.openFile(file('b'), '20-b'), OpenOutcome.cappedNeedsChoice);
    expect(container.read(tabsControllerProvider).tabs.length, 1);
  });
}
