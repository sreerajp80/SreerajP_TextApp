import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/sync/sync_constants.dart';
import 'package:text_data/sync/sync_share_prefs.dart';

import '../support/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(KeyValueStore store) {
    final container = ProviderContainer(
      overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults: every category enabled', () async {
    final store = await inMemoryKeyValueStore();
    final prefs = containerWith(store).read(syncSharePrefsProvider);
    for (final c in SyncConstants.allCategories) {
      expect(prefs.isEnabled(c), isTrue);
    }
  });

  test('disabling a category persists and narrows the set', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(syncSharePrefsProvider.notifier);

    controller.setEnabled(SyncConstants.categoryRecents, false);

    final prefs = container.read(syncSharePrefsProvider);
    expect(prefs.isEnabled(SyncConstants.categoryRecents), isFalse);
    expect(prefs.isEnabled(SyncConstants.categoryFavorites), isTrue);

    final reread = containerWith(store).read(syncSharePrefsProvider);
    expect(reread.isEnabled(SyncConstants.categoryRecents), isFalse);
  });

  test('unknown category is ignored', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(syncSharePrefsProvider.notifier);

    controller.setEnabled('not-a-category', true);
    final prefs = container.read(syncSharePrefsProvider);
    expect(prefs.enabledCategories.contains('not-a-category'), isFalse);
  });
}
