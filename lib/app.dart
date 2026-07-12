import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale/locale_controller.dart';
import 'core/security/app_lock_gate.dart';
import 'core/theme/app_theme_mode.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_settings.dart';
import 'l10n/app_localizations.dart';
import 'shell/app_shell.dart';
import 'shell/onboarding/onboarding_controller.dart';
import 'shell/onboarding/onboarding_screen.dart';

/// Root of the TextData app.
///
/// Builds the Material 3 [MaterialApp] with the user's chosen theme, and shows
/// the first-run onboarding until it is completed, then the app shell
/// (Home / Recent, tabs, settings).
class TextDataApp extends ConsumerWidget {
  const TextDataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final onboardingComplete = ref.watch(onboardingControllerProvider);
    final appLocale = ref.watch(localeControllerProvider);
    final themes = _resolveThemes(settings);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: appLocale.toLocale(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themes.light,
      darkTheme: themes.dark,
      themeMode: themes.mode,
      home: ScreenshotProtector(
        child: AppLockGate(
          child:
              onboardingComplete ? const AppShell() : const OnboardingScreen(),
        ),
      ),
    );
  }

  /// Maps the app's four-way theme choice onto Material's light/dark/mode trio.
  ///
  /// Sepia has no Material equivalent, so it is served as the "light" theme with
  /// the mode forced to light.
  _ResolvedThemes _resolveThemes(ThemeSettings settings) {
    switch (settings.mode) {
      case AppThemeMode.light:
        return _ResolvedThemes(
          light: AppThemes.light(settings),
          dark: AppThemes.dark(settings),
          mode: ThemeMode.light,
        );
      case AppThemeMode.dark:
        return _ResolvedThemes(
          light: AppThemes.light(settings),
          dark: AppThemes.dark(settings),
          mode: ThemeMode.dark,
        );
      case AppThemeMode.sepia:
        return _ResolvedThemes(
          light: AppThemes.sepia(settings),
          dark: AppThemes.dark(settings),
          mode: ThemeMode.light,
        );
      case AppThemeMode.system:
        return _ResolvedThemes(
          light: AppThemes.light(settings),
          dark: AppThemes.dark(settings),
          mode: ThemeMode.system,
        );
    }
  }
}

class _ResolvedThemes {
  final ThemeData light;
  final ThemeData dark;
  final ThemeMode mode;

  const _ResolvedThemes({
    required this.light,
    required this.dark,
    required this.mode,
  });
}
