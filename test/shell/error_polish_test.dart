import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/theme/app_themes.dart';
import 'package:text_data/core/theme/theme_settings.dart';

/// Guards task 13.5: notices are non-blocking. Every theme floats its snackbars
/// so a message never covers the content or traps the user behind a modal bar.
void main() {
  const settings = ThemeSettings();

  for (final entry in <String, ThemeData>{
    'light': AppThemes.light(settings),
    'dark': AppThemes.dark(settings),
    'sepia': AppThemes.sepia(settings),
  }.entries) {
    test('${entry.key} theme uses floating, non-blocking snackbars', () {
      expect(entry.value.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(entry.value.snackBarTheme.showCloseIcon, isTrue);
    });
  }
}
