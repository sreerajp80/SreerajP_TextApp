import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/tts/tts_settings.dart';

import '../../support/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(KeyValueStore store) {
    final container = ProviderContainer(
      overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults: English on, Malayalam off', () async {
    final store = await inMemoryKeyValueStore();
    final s = containerWith(store).read(ttsSettingsProvider);
    expect(s.englishEnabled, isTrue);
    expect(s.malayalamEnabled, isFalse);
  });

  test('setters update state and persist', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(ttsSettingsProvider.notifier);

    controller.setEnglishEnabled(false);
    controller.setMalayalamEnabled(true);

    final s = container.read(ttsSettingsProvider);
    expect(s.englishEnabled, isFalse);
    expect(s.malayalamEnabled, isTrue);

    final reread = containerWith(store).read(ttsSettingsProvider);
    expect(reread.englishEnabled, isFalse);
    expect(reread.malayalamEnabled, isTrue);
  });
}
