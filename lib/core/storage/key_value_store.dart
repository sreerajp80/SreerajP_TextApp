import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_store.dart';
import 'secure_store.dart';

/// One place the rest of the app reads and writes simple settings.
///
/// It hides the split between non-sensitive settings (kept in
/// `shared_preferences`) and sensitive secrets (kept in `flutter_secure_storage`,
/// Keystore-backed). A fixed allow-list of **sensitive keys** decides where each
/// value goes, so a secret can never accidentally land in plain preferences
/// (architecture.md §10; security-rules).
class KeyValueStore {
  final PreferencesStore _prefs;
  final SecureStore _secure;

  /// Keys whose values are secret and must live in secure storage only.
  /// Anything not in this set is treated as non-sensitive.
  final Set<String> _sensitiveKeys;

  KeyValueStore({
    required PreferencesStore prefs,
    required SecureStore secure,
    Set<String> sensitiveKeys = defaultSensitiveKeys,
  })  : _prefs = prefs,
        _secure = secure,
        _sensitiveKeys = sensitiveKeys;

  /// Opens preferences and builds a ready store backed by the real Keystore.
  ///
  /// Called once at app boot (see `main.dart`) so the store can be handed to the
  /// UI synchronously via [keyValueStoreSyncProvider].
  static Future<KeyValueStore> open() async {
    final prefs = await PreferencesStore.open();
    return KeyValueStore(prefs: prefs, secure: FlutterSecureStore());
  }

  /// Sensitive keys known so far. Grows as later phases add secrets (e.g. the
  /// P2P device key in Phase 12). App-lock PINs and per-device keys never sync
  /// (security-rules).
  static const Set<String> defaultSensitiveKeys = {
    'device_key', // Phase 12: this device's P2P encryption key.
    'app_lock_pin', // Phase 11/13: app-lock PIN hash (salted, never plaintext).
    'app_lock_recovery', // Phase 13: app-lock recovery-code hash (salted).
  };

  bool isSensitive(String key) => _sensitiveKeys.contains(key);

  /// Reads a string from whichever store owns [key].
  Future<String?> getString(String key) async {
    if (isSensitive(key)) return _secure.read(key);
    return _prefs.getString(key);
  }

  /// Writes a string to whichever store owns [key].
  Future<void> setString(String key, String value) async {
    if (isSensitive(key)) {
      await _secure.write(key, value);
    } else {
      await _prefs.setString(key, value);
    }
  }

  /// Removes [key] from whichever store owns it.
  Future<void> remove(String key) async {
    if (isSensitive(key)) {
      await _secure.delete(key);
    } else {
      await _prefs.remove(key);
    }
  }

  Future<bool> containsKey(String key) async {
    if (isSensitive(key)) return _secure.containsKey(key);
    return _prefs.contains(key);
  }

  // Non-sensitive typed helpers (never routed to secure storage). These are
  // synchronous so the UI (e.g. the theme on the first frame) can read settings
  // without awaiting. Never use them for a sensitive key.

  /// Synchronous read of a non-sensitive string.
  String? getPlainString(String key) => _prefs.getString(key);

  /// Synchronous-style write of a non-sensitive string.
  Future<void> setPlainString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
}

/// Async provider that opens preferences and builds the facade. Later phases
/// override or read this; secure storage uses the real Keystore implementation.
final keyValueStoreProvider = FutureProvider<KeyValueStore>((ref) async {
  return KeyValueStore.open();
});

/// Synchronous access to the settings store.
///
/// The UI (theme, tabs, onboarding) needs the store on the first frame, so
/// `main()` opens it once at boot and overrides this provider with the ready
/// instance. Tests override it with an in-memory store. Reading it without an
/// override is a programming error.
final keyValueStoreSyncProvider = Provider<KeyValueStore>(
  (ref) => throw StateError(
    'keyValueStoreSyncProvider must be overridden at app start '
    '(see main.dart) or in tests.',
  ),
);
