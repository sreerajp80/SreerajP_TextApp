import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'theme_settings.dart';

/// Builds the Material 3 [ThemeData] for each look from the app's appearance
/// settings (architecture.md §5).
///
/// Dynamic color from the device wallpaper is not wired in this phase (it needs
/// an extra package). We use [ColorScheme.fromSeed] as the safe fallback the
/// design allows; a dynamic-color layer can wrap these builders later.
class AppThemes {
  /// The brand seed used to derive the light and dark schemes.
  static const Color seed = Colors.indigo;

  /// A warm brown seed plus a paper-like background for the sepia reading look.
  static const Color _sepiaSeed = Color(0xFF7A5C3E);
  static const Color _sepiaBackground = Color(0xFFF4ECD8);
  static const Color _sepiaSurface = Color(0xFFEFE6CF);

  static ThemeData light(ThemeSettings settings) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _build(scheme, settings);
  }

  static ThemeData dark(ThemeSettings settings) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _build(scheme, settings);
  }

  static ThemeData sepia(ThemeSettings settings) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _sepiaSeed,
      brightness: Brightness.light,
    ).copyWith(
      surface: _sepiaSurface,
    );
    return _build(scheme, settings).copyWith(
      scaffoldBackgroundColor: _sepiaBackground,
    );
  }

  /// Applies the shared shape, and the user's font scale / line spacing to the
  /// text theme, on top of a colour [scheme].
  static ThemeData _build(ColorScheme scheme, ThemeSettings settings) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: settings.fontFamily,
      // Render Malayalam text in the chosen Malayalam face app-wide; leaves the
      // platform fallback chain untouched when none is selected.
      fontFamilyFallback: AppFonts.malayalamFallback(
        settings.malayalamFontFamily,
      ),
    );
    return base.copyWith(
      textTheme: _scaleTextTheme(base.textTheme, settings),
      // Every snackbar floats so it never blocks the content underneath and
      // dismisses on its own (task 13.5 — non-blocking notices).
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
    );
  }

  /// Multiplies every text style's size by [ThemeSettings.fontScale] and sets a
  /// consistent line `height` from [ThemeSettings.lineSpacing].
  static TextTheme _scaleTextTheme(TextTheme theme, ThemeSettings settings) {
    TextStyle? scale(TextStyle? style) {
      if (style == null) return null;
      final size = style.fontSize;
      return style.copyWith(
        fontSize: size == null ? null : size * settings.fontScale,
        height: settings.lineSpacing,
      );
    }

    return TextTheme(
      displayLarge: scale(theme.displayLarge),
      displayMedium: scale(theme.displayMedium),
      displaySmall: scale(theme.displaySmall),
      headlineLarge: scale(theme.headlineLarge),
      headlineMedium: scale(theme.headlineMedium),
      headlineSmall: scale(theme.headlineSmall),
      titleLarge: scale(theme.titleLarge),
      titleMedium: scale(theme.titleMedium),
      titleSmall: scale(theme.titleSmall),
      bodyLarge: scale(theme.bodyLarge),
      bodyMedium: scale(theme.bodyMedium),
      bodySmall: scale(theme.bodySmall),
      labelLarge: scale(theme.labelLarge),
      labelMedium: scale(theme.labelMedium),
      labelSmall: scale(theme.labelSmall),
    );
  }
}
