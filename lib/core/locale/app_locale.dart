import 'package:flutter/widgets.dart';

/// The language choices the app offers in Settings › Appearance.
///
/// [system] follows the device language (Flutter picks the best match from the
/// supported locales, falling back to English). [english] and [malayalam] force
/// that language regardless of the device setting.
enum AppLocale {
  system,
  english,
  malayalam;

  /// Short label used only as an English fallback; the settings UI shows the
  /// localized labels (`languageSystem` / `languageEnglish` / `languageMalayalam`).
  String get label {
    switch (this) {
      case AppLocale.system:
        return 'System';
      case AppLocale.english:
        return 'English';
      case AppLocale.malayalam:
        return 'Malayalam';
    }
  }

  /// The [Locale] to force on `MaterialApp`, or `null` for [system] (follow the
  /// device language).
  Locale? toLocale() {
    switch (this) {
      case AppLocale.system:
        return null;
      case AppLocale.english:
        return const Locale('en');
      case AppLocale.malayalam:
        return const Locale('ml');
    }
  }

  /// Stable string used when saving to preferences. Kept separate from [name]
  /// only so a future rename of the enum cannot silently change stored values.
  String get prefValue => name;

  /// Parses a saved [prefValue] back to a choice, falling back to [system] for
  /// anything unknown (a corrupt or old pref never crashes — CLAUDE.md §3.4).
  static AppLocale fromPrefValue(String? value) {
    for (final locale in AppLocale.values) {
      if (locale.prefValue == value) return locale;
    }
    return AppLocale.system;
  }
}
