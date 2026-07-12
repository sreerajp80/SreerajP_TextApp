import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/preferences_store.dart';
import 'package:text_data/core/storage/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyValueStore store;
  late InMemorySecureStore secure;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesStore.open();
    secure = InMemorySecureStore();
    store = KeyValueStore(
      prefs: prefs,
      secure: secure,
      sensitiveKeys: const {'device_key'},
    );
  });

  test('non-sensitive value round-trips through preferences', () async {
    await store.setString('theme', 'dark');
    expect(await store.getString('theme'), 'dark');
    expect(store.isSensitive('theme'), isFalse);
  });

  test('sensitive value round-trips through secure storage', () async {
    await store.setString('device_key', 'secret-key-material');
    expect(await store.getString('device_key'), 'secret-key-material');
    expect(store.isSensitive('device_key'), isTrue);
    // It landed in secure storage, not preferences.
    expect(await secure.read('device_key'), 'secret-key-material');
  });

  test('a sensitive key is never written to preferences', () async {
    SharedPreferences.setMockInitialValues({});
    await store.setString('device_key', 'top-secret');
    final rawPrefs = await SharedPreferences.getInstance();
    expect(rawPrefs.getString('device_key'), isNull);
  });

  test('remove deletes from the owning store', () async {
    await store.setString('theme', 'sepia');
    await store.setString('device_key', 'k');
    await store.remove('theme');
    await store.remove('device_key');
    expect(await store.getString('theme'), isNull);
    expect(await store.getString('device_key'), isNull);
  });

  test('typed helpers work for non-sensitive keys', () async {
    await store.setBool('wrap', true);
    await store.setInt('tabCap', 5);
    await store.setDouble('lineSpacing', 1.4);
    expect(store.getBool('wrap'), true);
    expect(store.getInt('tabCap'), 5);
    expect(store.getDouble('lineSpacing'), 1.4);
  });
}
