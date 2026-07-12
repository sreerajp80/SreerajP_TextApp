import 'app_theme_mode.dart';

/// All appearance preferences, in one immutable value (architecture.md §5, §8.1).
///
/// Held by the `ThemeController`, hydrated from and saved to the settings store.
/// [fontScale] multiplies the base text size; [lineSpacing] is the text
/// `height` multiplier; [fontFamily] is the English (Latin) face and
/// [malayalamFontFamily] the Malayalam face applied as a fallback — both
/// `null` for the platform default.
class ThemeSettings {
  final AppThemeMode mode;
  final double fontScale;
  final double lineSpacing;
  final String? fontFamily;
  final String? malayalamFontFamily;

  /// Whether text formats start with word wrap on (task 11.1). Structured
  /// formats (CSV/JSON/XML) keep their own format-appropriate default.
  final bool wordWrap;

  const ThemeSettings({
    this.mode = AppThemeMode.system,
    this.fontScale = 1.0,
    this.lineSpacing = 1.4,
    this.fontFamily,
    this.malayalamFontFamily,
    this.wordWrap = true,
  });

  /// The default appearance used before anything is saved and as a safe
  /// fallback if stored values are missing or out of range.
  static const ThemeSettings defaults = ThemeSettings();

  // Guard rails so a bad stored value can never make text unreadable.
  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.6;
  static const double minLineSpacing = 1.0;
  static const double maxLineSpacing = 2.0;

  // Preference keys (non-sensitive; live in shared_preferences).
  static const String modeKey = 'appearance.theme_mode';
  static const String fontScaleKey = 'appearance.font_scale';
  static const String lineSpacingKey = 'appearance.line_spacing';
  static const String fontFamilyKey = 'appearance.font_family';
  static const String malayalamFontFamilyKey = 'appearance.malayalam_font_family';
  static const String wordWrapKey = 'appearance.word_wrap';

  ThemeSettings copyWith({
    AppThemeMode? mode,
    double? fontScale,
    double? lineSpacing,
    Object? fontFamily = _noChange,
    Object? malayalamFontFamily = _noChange,
    bool? wordWrap,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      fontScale: _clampFontScale(fontScale ?? this.fontScale),
      lineSpacing: _clampLineSpacing(lineSpacing ?? this.lineSpacing),
      fontFamily: identical(fontFamily, _noChange)
          ? this.fontFamily
          : fontFamily as String?,
      malayalamFontFamily: identical(malayalamFontFamily, _noChange)
          ? this.malayalamFontFamily
          : malayalamFontFamily as String?,
      wordWrap: wordWrap ?? this.wordWrap,
    );
  }

  static double _clampFontScale(double v) =>
      v.clamp(minFontScale, maxFontScale).toDouble();

  static double _clampLineSpacing(double v) =>
      v.clamp(minLineSpacing, maxLineSpacing).toDouble();

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.mode == mode &&
      other.fontScale == fontScale &&
      other.lineSpacing == lineSpacing &&
      other.fontFamily == fontFamily &&
      other.malayalamFontFamily == malayalamFontFamily &&
      other.wordWrap == wordWrap;

  @override
  int get hashCode => Object.hash(
    mode,
    fontScale,
    lineSpacing,
    fontFamily,
    malayalamFontFamily,
    wordWrap,
  );
}

/// Sentinel so `copyWith(fontFamily: null)` can clear the family while an
/// omitted argument leaves it unchanged.
const Object _noChange = Object();
