import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/app_locale.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

/// Appearance settings (task 11.1): theme, font size, font family, line spacing,
/// and the default word-wrap for text formats.
class AppearanceSection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const AppearanceSection({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SettingsSectionHeader(title: l10n.appearSectionTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.appearTheme, style: theme.textTheme.labelLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<AppThemeMode>(
            segments: [
              for (final mode in AppThemeMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {settings.mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.appearLanguage, style: theme.textTheme.labelLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<AppLocale>(
            segments: [
              for (final locale in AppLocale.values)
                ButtonSegment(
                  value: locale,
                  label: Text(_localeLabel(l10n, locale)),
                ),
            ],
            selected: {ref.watch(localeControllerProvider)},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(localeControllerProvider.notifier).setLocale(s.first),
          ),
        ),
        SettingsSliderTile(
          label: l10n.appearFontSize,
          value: settings.fontScale,
          min: ThemeSettings.minFontScale,
          max: ThemeSettings.maxFontScale,
          divisions: 8,
          valueLabel: '${(settings.fontScale * 100).round()}%',
          onChanged: controller.setFontScale,
        ),
        _fontRow(
          label: l10n.appearFontFamily,
          choices: AppFonts.english,
          selected: settings.fontFamily,
          onChanged: controller.setFontFamily,
          labelStyle: theme.textTheme.labelLarge,
        ),
        _fontRow(
          label: l10n.appearMalayalamFontFamily,
          choices: AppFonts.malayalam,
          selected: settings.malayalamFontFamily,
          onChanged: controller.setMalayalamFontFamily,
          labelStyle: theme.textTheme.labelLarge,
        ),
        SettingsSliderTile(
          label: l10n.appearLineSpacing,
          value: settings.lineSpacing,
          min: ThemeSettings.minLineSpacing,
          max: ThemeSettings.maxLineSpacing,
          divisions: 10,
          valueLabel: settings.lineSpacing.toStringAsFixed(1),
          onChanged: controller.setLineSpacing,
        ),
        SwitchListTile(
          title: Text(l10n.appearWordWrapTitle),
          subtitle: Text(l10n.appearWordWrapSubtitle),
          value: settings.wordWrap,
          onChanged: controller.setWordWrap,
        ),
      ],
    );
  }

  /// The localized label for a language choice, so the picker reads in the
  /// current language.
  String _localeLabel(AppLocalizations l10n, AppLocale locale) {
    switch (locale) {
      case AppLocale.system:
        return l10n.languageSystem;
      case AppLocale.english:
        return l10n.languageEnglish;
      case AppLocale.malayalam:
        return l10n.languageMalayalam;
    }
  }

  /// A label + dropdown row for a font family setting. [choices] maps each menu
  /// label to its family string (`null` = platform default); [selected] is the
  /// stored family, mapped back to its label so the right item shows.
  Widget _fontRow({
    required String label,
    required Map<String, String?> choices,
    required String? selected,
    required void Function(String?) onChanged,
    required TextStyle? labelStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          DropdownButton<String>(
            value: AppFonts.labelFor(choices, selected),
            items: [
              for (final entry in choices.keys)
                DropdownMenuItem(value: entry, child: Text(entry)),
            ],
            onChanged: (menuLabel) {
              if (menuLabel != null) onChanged(choices[menuLabel]);
            },
          ),
        ],
      ),
    );
  }
}
