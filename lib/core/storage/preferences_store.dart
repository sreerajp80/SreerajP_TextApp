import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over `shared_preferences` for **non-sensitive** settings
/// (theme, word-wrap, tab cap, etc.). Sensitive values go to [SecureStore]
/// instead; [KeyValueStore] hides the split.
class PreferencesStore {
  final SharedPreferences _prefs;

  PreferencesStore(this._prefs);

  /// Opens the shared preferences and returns a ready store.
  static Future<PreferencesStore> open() async {
    return PreferencesStore(await SharedPreferences.getInstance());
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  bool contains(String key) => _prefs.containsKey(key);
  Future<void> remove(String key) => _prefs.remove(key);

  /// Returns all stored non-sensitive preferences, strictly excluding any key
  /// present in [sensitiveKeys].
  Map<String, Object?> getAllNonSensitive(Set<String> sensitiveKeys) {
    final result = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      if (!sensitiveKeys.contains(key)) {
        result[key] = _prefs.get(key);
      }
    }
    return result;
  }

  /// Restores preferences from [values], ignoring any key in [sensitiveKeys].
  Future<void> restoreAll(
    Map<String, Object?> values,
    Set<String> sensitiveKeys,
  ) async {
    for (final entry in values.entries) {
      if (sensitiveKeys.contains(entry.key)) continue;
      final val = entry.value;
      if (val is bool) {
        await _prefs.setBool(entry.key, val);
      } else if (val is int) {
        await _prefs.setInt(entry.key, val);
      } else if (val is double) {
        await _prefs.setDouble(entry.key, val);
      } else if (val is String) {
        await _prefs.setString(entry.key, val);
      } else if (val is List<Object?>) {
        await _prefs.setStringList(
          entry.key,
          val.map((e) => e?.toString() ?? '').toList(),
        );
      }
    }
  }
}
