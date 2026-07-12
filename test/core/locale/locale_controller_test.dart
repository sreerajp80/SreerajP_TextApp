import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/locale/app_locale.dart';
import 'package:text_data/core/locale/locale_controller.dart';
import 'package:text_data/core/storage/key_value_store.dart';

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

  test('defaults to system when nothing is stored', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    expect(container.read(localeControllerProvider), AppLocale.system);
  });

  test('hydrates from a stored value', () async {
    final store = await inMemoryKeyValueStore();
    await store.setPlainString(
        LocaleController.languageKey, AppLocale.malayalam.prefValue);
    final container = containerWith(store);
    expect(container.read(localeControllerProvider), AppLocale.malayalam);
  });

  test('setLocale updates state and persists', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(localeControllerProvider.notifier);

    controller.setLocale(AppLocale.english);
    expect(container.read(localeControllerProvider), AppLocale.english);
    expect(store.getPlainString(LocaleController.languageKey),
        AppLocale.english.prefValue);
  });

  test('a corrupt stored value falls back to system', () async {
    final store = await inMemoryKeyValueStore();
    await store.setPlainString(LocaleController.languageKey, 'not-a-locale');
    final container = containerWith(store);
    expect(container.read(localeControllerProvider), AppLocale.system);
  });

  test('toLocale maps choices correctly', () {
    expect(AppLocale.system.toLocale(), isNull);
    expect(AppLocale.english.toLocale()?.languageCode, 'en');
    expect(AppLocale.malayalam.toLocale()?.languageCode, 'ml');
  });
}
