import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/security/app_lock_controller.dart';
import 'package:text_data/core/security/biometric_service.dart';
import 'package:text_data/core/security/security_providers.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/shell/settings/security_settings.dart';

import '../../support/test_support.dart';

/// A biometric service whose outcome the test controls.
class FakeBiometric implements BiometricService {
  bool available;
  BiometricResult result;
  FakeBiometric({this.available = true, this.result = BiometricResult.success});

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate(String reason) async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(
    KeyValueStore store, {
    BiometricService? biometric,
  }) {
    final container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(store),
        if (biometric != null)
          biometricServiceProvider.overrideWithValue(biometric),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('enable sets a PIN, returns a recovery code, and stays unlocked',
      () async {
    final store = await inMemoryKeyValueStore();
    final c = containerWith(store);
    final controller = c.read(appLockControllerProvider.notifier);

    final recovery = await controller.enableWithNewPin('1234');

    expect(recovery, isNotEmpty);
    expect(c.read(securitySettingsProvider).appLockEnabled, isTrue);
    expect(c.read(appLockControllerProvider).locked, isFalse);
  });

  test('unlock with the right PIN works; a wrong PIN is rejected', () async {
    final store = await inMemoryKeyValueStore();
    final c = containerWith(store);
    final controller = c.read(appLockControllerProvider.notifier);

    await controller.enableWithNewPin('1234');
    controller.lock();
    expect(c.read(appLockControllerProvider).locked, isTrue);

    expect(await controller.unlockWithPin('0000'), isFalse);
    expect(c.read(appLockControllerProvider).locked, isTrue);

    expect(await controller.unlockWithPin('1234'), isTrue);
    expect(c.read(appLockControllerProvider).locked, isFalse);
  });

  test('the app starts locked after a relaunch when app-lock is on', () async {
    final store = await inMemoryKeyValueStore();
    // First run: enable app-lock.
    final c1 = containerWith(store);
    await c1.read(appLockControllerProvider.notifier).enableWithNewPin('1234');

    // Second run over the same store (secrets + flag persisted).
    final c2 = containerWith(store);
    expect(c2.read(appLockControllerProvider).locked, isTrue);
    expect(
      await c2.read(appLockControllerProvider.notifier).unlockWithPin('1234'),
      isTrue,
    );
  });

  test('biometric success unlocks; failure keeps it locked', () async {
    final store = await inMemoryKeyValueStore();
    final bio = FakeBiometric(result: BiometricResult.success);
    final c = containerWith(store, biometric: bio);
    final controller = c.read(appLockControllerProvider.notifier);

    await controller.enableWithNewPin('1234');
    controller.lock();

    bio.result = BiometricResult.failed;
    expect(await controller.unlockWithBiometric('x'), BiometricResult.failed);
    expect(c.read(appLockControllerProvider).locked, isTrue);

    bio.result = BiometricResult.success;
    expect(await controller.unlockWithBiometric('x'), BiometricResult.success);
    expect(c.read(appLockControllerProvider).locked, isFalse);
  });

  test('recovery code unlocks and forces a new PIN + a new recovery code',
      () async {
    final store = await inMemoryKeyValueStore();
    final c = containerWith(store);
    final controller = c.read(appLockControllerProvider.notifier);

    final firstRecovery = await controller.enableWithNewPin('1234');
    controller.lock();

    // Wrong recovery code is rejected.
    expect(await controller.verifyRecoveryCode('WRONGCODE'), isFalse);
    // Right recovery code is accepted (does not unlock yet).
    expect(await controller.verifyRecoveryCode(firstRecovery), isTrue);
    expect(c.read(appLockControllerProvider).locked, isTrue);

    // Completing recovery sets a new PIN, unlocks, and rotates the recovery code.
    final newRecovery = await controller.completeRecovery('5678');
    expect(newRecovery, isNot(firstRecovery));
    expect(c.read(appLockControllerProvider).locked, isFalse);

    // The old PIN no longer works; the new one does.
    controller.lock();
    expect(await controller.unlockWithPin('1234'), isFalse);
    expect(await controller.unlockWithPin('5678'), isTrue);

    // The old recovery code no longer works; the new one does.
    controller.lock();
    expect(await controller.verifyRecoveryCode(firstRecovery), isFalse);
    expect(await controller.verifyRecoveryCode(newRecovery), isTrue);
  });

  test('changePin replaces the PIN but keeps the recovery code', () async {
    final store = await inMemoryKeyValueStore();
    final c = containerWith(store);
    final controller = c.read(appLockControllerProvider.notifier);

    final recovery = await controller.enableWithNewPin('1234');
    await controller.changePin('9999');
    controller.lock();

    expect(await controller.unlockWithPin('1234'), isFalse);
    expect(await controller.unlockWithPin('9999'), isTrue);
    // Recovery code unchanged.
    expect(await controller.verifyRecoveryCode(recovery), isTrue);
  });

  test('disable clears the stored PIN and recovery secrets', () async {
    final store = await inMemoryKeyValueStore();
    final c = containerWith(store);
    final controller = c.read(appLockControllerProvider.notifier);

    final recovery = await controller.enableWithNewPin('1234');
    await controller.disableAppLock();

    expect(c.read(securitySettingsProvider).appLockEnabled, isFalse);
    expect(await controller.unlockWithPin('1234'), isFalse);
    expect(await controller.verifyRecoveryCode(recovery), isFalse);
    expect(await store.containsKey('app_lock_pin'), isFalse);
    expect(await store.containsKey('app_lock_recovery'), isFalse);
  });
}
