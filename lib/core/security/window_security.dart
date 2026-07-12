import 'package:flutter/services.dart';

/// Toggles Android's FLAG_SECURE (screenshot / screen-record / recents-thumbnail
/// protection) on the app window. Behind an interface so widgets and tests can
/// inject a fake without a real platform channel (task 13.2).
abstract class WindowSecurity {
  /// Turns screenshot protection on ([secure] true) or off. Best-effort — a
  /// platform failure must never crash the UI.
  Future<void> setSecure(bool secure);
}

/// Real implementation over the `app/window_security` method channel
/// (WindowSecurityChannel.kt).
class PlatformWindowSecurity implements WindowSecurity {
  static const MethodChannel _channel = MethodChannel('app/window_security');

  const PlatformWindowSecurity();

  @override
  Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<bool>('setSecure', {'secure': secure});
    } catch (_) {
      // A missing channel (e.g. non-Android host, tests) is not fatal.
    }
  }
}

/// No-op used on hosts without the channel and as a safe default in tests.
class NoopWindowSecurity implements WindowSecurity {
  const NoopWindowSecurity();

  @override
  Future<void> setSecure(bool secure) async {}
}
