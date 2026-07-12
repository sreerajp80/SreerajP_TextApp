import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/shell/settings/security_settings.dart';

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

  test('defaults: app-lock off, screenshot + biometric on', () async {
    final store = await inMemoryKeyValueStore();
    final s = containerWith(store).read(securitySettingsProvider);
    expect(s.appLockEnabled, isFalse);
    expect(s.screenshotProtection, isTrue);
    expect(s.biometricUnlockEnabled, isTrue);
  });

  test('setters update state and persist', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(securitySettingsProvider.notifier);

    controller.setAppLockEnabled(true);
    controller.setScreenshotProtection(false);
    controller.setBiometricUnlockEnabled(false);

    final s = container.read(securitySettingsProvider);
    expect(s.appLockEnabled, isTrue);
    expect(s.screenshotProtection, isFalse);
    expect(s.biometricUnlockEnabled, isFalse);

    final reread = containerWith(store).read(securitySettingsProvider);
    expect(reread.appLockEnabled, isTrue);
    expect(reread.screenshotProtection, isFalse);
    expect(reread.biometricUnlockEnabled, isFalse);
  });
}
