import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';
import 'app_locale.dart';

/// The one place the app changes and remembers its language choice.
///
/// Mirrors `ThemeController`: hydration is synchronous (the language is a
/// non-sensitive pref) so the correct language is on screen from the first
/// frame — no flash from a default language. Writes are fire-and-forget; the
/// in-memory state updates immediately.
class LocaleController extends Notifier<AppLocale> {
  /// Preference key (non-sensitive; lives in shared_preferences).
  static const String languageKey = 'appearance.language';

  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  AppLocale build() =>
      AppLocale.fromPrefValue(_store.getPlainString(languageKey));

  void setLocale(AppLocale locale) {
    state = locale;
    _store.setPlainString(languageKey, locale.prefValue);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);
