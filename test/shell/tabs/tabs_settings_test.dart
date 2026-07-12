import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/editor_settings.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
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

  Future<ProviderContainer> makeContainer(KeyValueStore kv) async {
    final container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(kv),
        safServiceProvider.overrideWithValue(FakeSafService()),
        deviceMemoryProvider
            .overrideWithValue(const FakeDeviceMemory(4 * 1024 * 1024 * 1024)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('setFixedCap persists the mode and cap and applies it live', () async {
    final store = await inMemoryKeyValueStore();
    final container = await makeContainer(store);
    final tabs = container.read(tabsControllerProvider.notifier);

    await tabs.setFixedCap(3);

    expect(store.getPlainString(TabsController.capModeKey), 'fixed');
    expect(store.getInt(TabsController.fixedCapKey), 3);
    expect(container.read(tabsControllerProvider).cap, 3);
    expect(tabs.capMode, 'fixed');
    expect(tabs.fixedCap, 3);
  });

  test('setCapModeAuto switches back to the RAM-based value', () async {
    final store = await inMemoryKeyValueStore();
    final container = await makeContainer(store);
    final tabs = container.read(tabsControllerProvider.notifier);

    await tabs.setFixedCap(2);
    await tabs.setCapModeAuto();

    expect(store.getPlainString(TabsController.capModeKey), 'auto');
    // 4 GB device maps to a cap of 5 (see autoTabCap bands).
    expect(container.read(tabsControllerProvider).cap, 5);
  });

  test('setRestoreOnRelaunch persists the toggle', () async {
    final store = await inMemoryKeyValueStore();
    final container = await makeContainer(store);
    final tabs = container.read(tabsControllerProvider.notifier);

    expect(tabs.restoreOnRelaunch, isFalse);
    await tabs.setRestoreOnRelaunch(true);
    expect(tabs.restoreOnRelaunch, isTrue);
    expect(store.getBool(TabsPersistence.restoreEnabledKey), isTrue);
  });

  test('a new tab opens read-only when the editor setting is on', () async {
    final store = await inMemoryKeyValueStore();
    await store.setBool(EditorSettings.readOnlyDefaultKey, true);
    final container = await makeContainer(store);
    final tabs = container.read(tabsControllerProvider.notifier);

    tabs.openFile(file('a'), '10-a');
    expect(container.read(tabsControllerProvider).tabs.single.isReadOnly, isTrue);
  });
}
