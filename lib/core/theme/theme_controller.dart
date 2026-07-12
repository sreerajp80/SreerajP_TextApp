import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';
import 'app_theme_mode.dart';
import 'theme_settings.dart';

/// The one place the app changes and remembers its appearance
/// (architecture.md §5). Wraps [ThemeSettings], hydrating from and saving to the
/// settings store.
///
/// Hydration is synchronous (all appearance values are non-sensitive prefs) so
/// the correct theme is on screen from the first frame — no flash from a default
/// look. Writes are fire-and-forget; the in-memory state updates immediately.
class ThemeController extends Notifier<ThemeSettings> {
  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  ThemeSettings build() => _load();

  ThemeSettings _load() {
    final store = _store;
    return ThemeSettings(
      mode: AppThemeMode.fromPrefValue(
        store.getPlainString(ThemeSettings.modeKey),
      ),
      fontScale: store.getDouble(ThemeSettings.fontScaleKey) ??
          ThemeSettings.defaults.fontScale,
      lineSpacing: store.getDouble(ThemeSettings.lineSpacingKey) ??
          ThemeSettings.defaults.lineSpacing,
      fontFamily: store.getPlainString(ThemeSettings.fontFamilyKey),
      malayalamFontFamily: store.getPlainString(
        ThemeSettings.malayalamFontFamilyKey,
      ),
      wordWrap: store.getBool(ThemeSettings.wordWrapKey) ??
          ThemeSettings.defaults.wordWrap,
    );
  }

  void setMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
    _store.setPlainString(ThemeSettings.modeKey, mode.prefValue);
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
    _store.setDouble(ThemeSettings.fontScaleKey, state.fontScale);
  }

  void setLineSpacing(double spacing) {
    state = state.copyWith(lineSpacing: spacing);
    _store.setDouble(ThemeSettings.lineSpacingKey, state.lineSpacing);
  }

  /// Sets a custom English font family, or clears it (platform default) when
  /// [family] is null or empty.
  void setFontFamily(String? family) {
    final value = (family == null || family.isEmpty) ? null : family;
    state = state.copyWith(fontFamily: value);
    if (value == null) {
      _store.remove(ThemeSettings.fontFamilyKey);
    } else {
      _store.setPlainString(ThemeSettings.fontFamilyKey, value);
    }
  }

  /// Sets the Malayalam font family (applied as a fallback so Malayalam text
  /// renders in it), or clears it (platform default) when [family] is null or
  /// empty.
  void setMalayalamFontFamily(String? family) {
    final value = (family == null || family.isEmpty) ? null : family;
    state = state.copyWith(malayalamFontFamily: value);
    if (value == null) {
      _store.remove(ThemeSettings.malayalamFontFamilyKey);
    } else {
      _store.setPlainString(ThemeSettings.malayalamFontFamilyKey, value);
    }
  }

  /// Sets whether text formats start with word wrap on (task 11.1).
  void setWordWrap(bool wrap) {
    state = state.copyWith(wordWrap: wrap);
    _store.setBool(ThemeSettings.wordWrapKey, wrap);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
