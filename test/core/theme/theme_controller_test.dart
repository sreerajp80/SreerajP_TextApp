import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/theme/app_theme_mode.dart';
import 'package:text_data/core/theme/theme_controller.dart';
import 'package:text_data/core/theme/theme_settings.dart';

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

  test('defaults when nothing is stored', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);

    final settings = container.read(themeControllerProvider);
    expect(settings.mode, AppThemeMode.system);
    expect(settings.fontScale, ThemeSettings.defaults.fontScale);
    expect(settings.lineSpacing, ThemeSettings.defaults.lineSpacing);
    expect(settings.fontFamily, isNull);
    expect(settings.malayalamFontFamily, isNull);
  });

  test('hydrates from stored values', () async {
    final store = await inMemoryKeyValueStore();
    await store.setPlainString(
        ThemeSettings.modeKey, AppThemeMode.sepia.prefValue);
    await store.setDouble(ThemeSettings.fontScaleKey, 1.3);
    await store.setDouble(ThemeSettings.lineSpacingKey, 1.8);

    final container = containerWith(store);
    final settings = container.read(themeControllerProvider);
    expect(settings.mode, AppThemeMode.sepia);
    expect(settings.fontScale, 1.3);
    expect(settings.lineSpacing, 1.8);
  });

  test('setMode updates state and persists', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(themeControllerProvider.notifier);

    controller.setMode(AppThemeMode.dark);
    expect(container.read(themeControllerProvider).mode, AppThemeMode.dark);
    expect(store.getPlainString(ThemeSettings.modeKey),
        AppThemeMode.dark.prefValue);
  });

  test('font scale is clamped to a safe range', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(themeControllerProvider.notifier);

    controller.setFontScale(99);
    expect(container.read(themeControllerProvider).fontScale,
        ThemeSettings.maxFontScale);

    controller.setFontScale(0.01);
    expect(container.read(themeControllerProvider).fontScale,
        ThemeSettings.minFontScale);
  });

  test('setMalayalamFontFamily updates state and persists', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(themeControllerProvider.notifier);

    controller.setMalayalamFontFamily('Rachana');
    expect(
      container.read(themeControllerProvider).malayalamFontFamily,
      'Rachana',
    );
    expect(
      store.getPlainString(ThemeSettings.malayalamFontFamilyKey),
      'Rachana',
    );
  });

  test('setMalayalamFontFamily(null) clears state and removes the key',
      () async {
    final store = await inMemoryKeyValueStore();
    await store.setPlainString(
        ThemeSettings.malayalamFontFamilyKey, 'Manjari');
    final container = containerWith(store);
    final controller = container.read(themeControllerProvider.notifier);

    expect(
      container.read(themeControllerProvider).malayalamFontFamily,
      'Manjari',
    );

    controller.setMalayalamFontFamily(null);
    expect(
      container.read(themeControllerProvider).malayalamFontFamily,
      isNull,
    );
    expect(
      store.getPlainString(ThemeSettings.malayalamFontFamilyKey),
      isNull,
    );
  });

  test('a corrupt stored mode falls back to system', () async {
    final store = await inMemoryKeyValueStore();
    await store.setPlainString(ThemeSettings.modeKey, 'not-a-mode');
    final container = containerWith(store);
    expect(
        container.read(themeControllerProvider).mode, AppThemeMode.system);
  });
}
