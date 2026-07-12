import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage for **sensitive** values (device keys, secrets). Kept behind an
/// interface so tests can inject an in-memory fake without a device Keystore.
///
/// Security: values here are the only ones that hold secret material. Nothing
/// in this layer logs its keys or values (security-rules: never log secrets).
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
}

/// Real implementation backed by the Android Keystore via
/// `flutter_secure_storage` (architecture.md §10).
class FlutterSecureStore implements SecureStore {
  final FlutterSecureStorage _storage;

  FlutterSecureStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}

/// In-memory [SecureStore] for tests. Never use in production — it is not
/// encrypted and does not persist.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _map = {};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);
}
