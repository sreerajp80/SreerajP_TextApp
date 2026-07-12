import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/settings/security_settings.dart';
import 'app_lock_hasher.dart';
import 'app_lock_repository.dart';
import 'biometric_service.dart';
import 'security_providers.dart';

/// Runtime app-lock state for this app session (task 13.2).
///
/// [locked] means the user must unlock before using the app. It is separate from
/// the *setting* [SecuritySettings.appLockEnabled] (whether the feature is on).
class AppLockState {
  /// Whether the app is currently locked and awaiting unlock.
  final bool locked;

  const AppLockState({required this.locked});

  AppLockState copyWith({bool? locked}) =>
      AppLockState(locked: locked ?? this.locked);
}

/// Orchestrates enabling/disabling app-lock, unlocking (PIN / biometric /
/// recovery code), and changing the PIN. Never stores or logs a plaintext PIN or
/// recovery code — only their salted hashes via [AppLockRepository].
class AppLockController extends Notifier<AppLockState> {
  AppLockRepository get _repo => ref.read(appLockRepositoryProvider);
  BiometricService get _biometric => ref.read(biometricServiceProvider);
  SecuritySettingsController get _settings =>
      ref.read(securitySettingsProvider.notifier);

  @override
  AppLockState build() {
    // Read once at start (not watch) so this controller owns the lock state and
    // is not reset when the setting is toggled through it. If app-lock is on,
    // start locked; the gate then shows the unlock screen.
    final enabled = ref.read(securitySettingsProvider).appLockEnabled;
    return AppLockState(locked: enabled);
  }

  /// Turns app-lock on with a freshly chosen [pin]. Generates and stores a
  /// recovery code (hashed) and returns its plaintext **once** so the caller can
  /// show it to the user to save. Leaves the app unlocked (the user just set it
  /// up).
  Future<String> enableWithNewPin(String pin) async {
    await _repo.setPin(pin);
    final recovery = AppLockHasher.generateRecoveryCode();
    await _repo.setRecovery(recovery);
    _settings.setAppLockEnabled(true);
    state = const AppLockState(locked: false);
    return recovery;
  }

  /// Turns app-lock off and clears the stored PIN and recovery hashes.
  Future<void> disableAppLock() async {
    await _repo.clearAll();
    _settings.setAppLockEnabled(false);
    state = const AppLockState(locked: false);
  }

  /// Changes the PIN (app-lock stays on). Does not change the recovery code.
  Future<void> changePin(String newPin) => _repo.setPin(newPin);

  /// Regenerates the recovery code and returns the new plaintext **once**.
  Future<String> regenerateRecoveryCode() async {
    final recovery = AppLockHasher.generateRecoveryCode();
    await _repo.setRecovery(recovery);
    return recovery;
  }

  /// Whether biometric unlock can be offered on this device.
  Future<bool> biometricAvailable() => _biometric.isAvailable();

  /// Tries to unlock with [pin]. Returns true on success.
  Future<bool> unlockWithPin(String pin) async {
    final ok = await _repo.verifyPin(pin);
    if (ok) state = const AppLockState(locked: false);
    return ok;
  }

  /// Tries to unlock with biometrics. Returns the outcome; unlocks on success.
  Future<BiometricResult> unlockWithBiometric(String reason) async {
    final result = await _biometric.authenticate(reason);
    if (result == BiometricResult.success) {
      state = const AppLockState(locked: false);
    }
    return result;
  }

  /// Step 1 of the forgot-PIN flow: checks [code] without unlocking yet. The
  /// caller must then collect a new PIN and call [completeRecovery].
  Future<bool> verifyRecoveryCode(String code) => _repo.verifyRecovery(code);

  /// Step 2 of the forgot-PIN flow: sets a new PIN, regenerates the recovery
  /// code, unlocks, and returns the new recovery code plaintext **once**.
  Future<String> completeRecovery(String newPin) async {
    await _repo.setPin(newPin);
    final recovery = AppLockHasher.generateRecoveryCode();
    await _repo.setRecovery(recovery);
    state = const AppLockState(locked: false);
    return recovery;
  }

  /// Re-locks the app (called when it goes to the background, if enabled).
  void lock() {
    if (ref.read(securitySettingsProvider).appLockEnabled) {
      state = const AppLockState(locked: true);
    }
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);
