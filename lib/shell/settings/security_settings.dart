import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/key_value_store.dart';

/// Security preferences.
///
/// These are the non-sensitive **flags** only. Enforcement lives in Phase 13.2:
/// the app-lock gate (`AppLockController` / `AppLockGate`) and screenshot
/// protection (`FLAG_SECURE` via `WindowSecurity`) both read these flags.
///
/// The app-lock PIN and recovery code are **not** stored here — they use the
/// reserved Keystore-backed secure keys `app_lock_pin` / `app_lock_recovery`
/// (salted hashes only), handled by `AppLockRepository`.
class SecuritySettings {
  final bool appLockEnabled;
  final bool screenshotProtection;

  /// Whether biometric unlock may be offered (only takes effect when the device
  /// actually has enrolled biometrics). PIN stays the fallback either way.
  final bool biometricUnlockEnabled;

  const SecuritySettings({
    this.appLockEnabled = false,
    this.screenshotProtection = true,
    this.biometricUnlockEnabled = true,
  });

  static const SecuritySettings defaults = SecuritySettings();

  // Preference keys (non-sensitive flags; the PIN/recovery are separate secure
  // keys handled by AppLockRepository).
  static const String appLockKey = 'security.app_lock_enabled';
  static const String screenshotKey = 'security.screenshot_protection';
  static const String biometricKey = 'security.biometric_unlock';

  SecuritySettings copyWith({
    bool? appLockEnabled,
    bool? screenshotProtection,
    bool? biometricUnlockEnabled,
  }) {
    return SecuritySettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      screenshotProtection: screenshotProtection ?? this.screenshotProtection,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SecuritySettings &&
      other.appLockEnabled == appLockEnabled &&
      other.screenshotProtection == screenshotProtection &&
      other.biometricUnlockEnabled == biometricUnlockEnabled;

  @override
  int get hashCode =>
      Object.hash(appLockEnabled, screenshotProtection, biometricUnlockEnabled);
}

/// Remembers the security preferences (task 11.6). Same pattern as the other
/// settings controllers: hydrate synchronously, update state first, persist
/// fire-and-forget.
class SecuritySettingsController extends Notifier<SecuritySettings> {
  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  SecuritySettings build() {
    final store = _store;
    return SecuritySettings(
      appLockEnabled:
          store.getBool(SecuritySettings.appLockKey) ??
          SecuritySettings.defaults.appLockEnabled,
      screenshotProtection:
          store.getBool(SecuritySettings.screenshotKey) ??
          SecuritySettings.defaults.screenshotProtection,
      biometricUnlockEnabled:
          store.getBool(SecuritySettings.biometricKey) ??
          SecuritySettings.defaults.biometricUnlockEnabled,
    );
  }

  void setAppLockEnabled(bool value) {
    state = state.copyWith(appLockEnabled: value);
    _store.setBool(SecuritySettings.appLockKey, value);
  }

  void setScreenshotProtection(bool value) {
    state = state.copyWith(screenshotProtection: value);
    _store.setBool(SecuritySettings.screenshotKey, value);
  }

  void setBiometricUnlockEnabled(bool value) {
    state = state.copyWith(biometricUnlockEnabled: value);
    _store.setBool(SecuritySettings.biometricKey, value);
  }
}

final securitySettingsProvider =
    NotifierProvider<SecuritySettingsController, SecuritySettings>(
      SecuritySettingsController.new,
    );
