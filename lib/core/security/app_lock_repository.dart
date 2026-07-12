import '../storage/key_value_store.dart';
import 'app_lock_hasher.dart';

/// Reads and writes the app-lock secrets — the PIN hash and the recovery-code
/// hash — through [KeyValueStore], which routes both keys to Keystore-backed
/// secure storage (they are on the sensitive-key allow-list). Only salted hashes
/// are ever stored; the plaintext PIN / recovery code never touch disk
/// (security-rules).
class AppLockRepository {
  final KeyValueStore _store;

  AppLockRepository(this._store);

  /// Secure-storage key for the PIN hash. On the never-sync list.
  static const String pinKey = 'app_lock_pin';

  /// Secure-storage key for the recovery-code hash. On the never-sync list.
  static const String recoveryKey = 'app_lock_recovery';

  Future<bool> hasPin() => _store.containsKey(pinKey);

  Future<void> setPin(String pin) =>
      _store.setString(pinKey, AppLockHasher.hash(pin));

  Future<bool> verifyPin(String pin) async {
    final stored = await _store.getString(pinKey);
    if (stored == null) return false;
    return AppLockHasher.verify(pin, stored);
  }

  Future<void> setRecovery(String code) =>
      _store.setString(recoveryKey, AppLockHasher.hash(code));

  Future<bool> verifyRecovery(String code) async {
    final stored = await _store.getString(recoveryKey);
    if (stored == null) return false;
    return AppLockHasher.verify(code, stored);
  }

  /// Removes both secrets (called when app-lock is turned off).
  Future<void> clearAll() async {
    await _store.remove(pinKey);
    await _store.remove(recoveryKey);
  }
}
