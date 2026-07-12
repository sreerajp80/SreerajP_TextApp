/// The theme choices the app offers (architecture.md §5, §8).
///
/// Flutter's own [ThemeMode] has only light / dark / system, so we define our
/// own enum to add **sepia** (a warm, low-contrast light scheme for long
/// reading). The mapping from this enum to real [ThemeData] lives in
/// `app_themes.dart`.
enum AppThemeMode {
  light,
  dark,
  sepia,
  system;

  /// Short, human-friendly label for the settings UI.
  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.sepia:
        return 'Sepia';
      case AppThemeMode.system:
        return 'System';
    }
  }

  /// Stable string used when saving to preferences. Kept separate from [name]
  /// only so a future rename of the enum cannot silently change stored values.
  String get prefValue => name;

  /// Parses a saved [prefValue] back to a mode, falling back to [system] for
  /// anything unknown (a corrupt or old pref never crashes — CLAUDE.md §3.4).
  static AppThemeMode fromPrefValue(String? value) {
    for (final mode in AppThemeMode.values) {
      if (mode.prefValue == value) return mode;
    }
    return AppThemeMode.system;
  }
}
