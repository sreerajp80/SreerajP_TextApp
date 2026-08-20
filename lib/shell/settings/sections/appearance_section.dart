import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/locale/app_locale.dart';
import 'package:sreerajp_textapp/core/locale/locale_controller.dart';
import 'package:sreerajp_textapp/core/theme/app_fonts.dart';
import 'package:sreerajp_textapp/core/theme/app_theme_mode.dart';
import 'package:sreerajp_textapp/core/theme/theme_controller.dart';
import 'package:sreerajp_textapp/core/theme/theme_settings.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/settings/sections/settings_widgets.dart';

/// Appearance settings (task 11.1): theme mode, language, visual font tiles,
/// font scale, line spacing, and default word-wrap.
class AppearanceSection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const AppearanceSection({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final currentLocale = ref.watch(localeControllerProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          SettingsSectionHeader(title: l10n.appearSectionTitle),
          const SizedBox(height: 8),
        ],

        // 1. Theme Mode
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.appearTheme,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: AppThemeMode.sepia,
                label: Text('Sepia'),
                icon: Icon(Icons.menu_book_outlined),
              ),
              ButtonSegment(
                value: AppThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
            ],
            selected: {settings.mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildThemeInfoCard(context, settings.mode, l10n),
        ),
        const SizedBox(height: 24),

        // 2. Language
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.appearLanguage,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<AppLocale>(
            segments: [
              for (final locale in AppLocale.values)
                ButtonSegment(
                  value: locale,
                  label: Text(_localeLabel(l10n, locale)),
                ),
            ],
            selected: {currentLocale},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(localeControllerProvider.notifier).setLocale(s.first),
          ),
        ),
        const SizedBox(height: 24),

        // 3. English Typography
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.appearFontFamily.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in AppFonts.english.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FontSelectionCard(
              label: entry.key,
              family: entry.value,
              sampleText: l10n.appearEnglishFontSample,
              selected: settings.fontFamily == entry.value,
              onTap: () => controller.setFontFamily(entry.value),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),

        // 4. Malayalam Typography
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.appearMalayalamFontFamily.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in AppFonts.malayalam.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FontSelectionCard(
              label: entry.key,
              family: entry.value,
              sampleText: l10n.appearMalayalamFontSample,
              selected: settings.malayalamFontFamily == entry.value,
              onTap: () => controller.setMalayalamFontFamily(entry.value),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),

        // 5. Reading Comfort & Text Scaling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'READING COMFORT & SCALE',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  SettingsSliderTile(
                    label: l10n.appearFontSize,
                    value: settings.fontScale,
                    min: ThemeSettings.minFontScale,
                    max: ThemeSettings.maxFontScale,
                    divisions: 25,
                    valueLabel: '${(settings.fontScale * 100).round()}%',
                    onChanged: controller.setFontScale,
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
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
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  SwitchListTile(
                    title: Text(
                      l10n.appearWordWrapTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      l10n.appearWordWrapSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: settings.wordWrap,
                    onChanged: controller.setWordWrap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeInfoCard(
    BuildContext context,
    AppThemeMode mode,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final String infoText;
    switch (mode) {
      case AppThemeMode.sepia:
        infoText = l10n.appearThemeSepiaInfo;
        break;
      case AppThemeMode.system:
        infoText = l10n.appearThemeSystemInfo;
        break;
      case AppThemeMode.light:
        infoText =
            'Light mode uses a high-contrast crisp theme for daytime reading.';
        break;
      case AppThemeMode.dark:
        infoText =
            'Dark mode saves battery and reduces eye strain in low-light environments.';
        break;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                infoText,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}

/// A card for picking a font family with a live preview sample.
class _FontSelectionCard extends StatelessWidget {
  final String label;
  final String? family;
  final String sampleText;
  final bool selected;
  final VoidCallback onTap;

  const _FontSelectionCard({
    required this.label,
    required this.family,
    required this.sampleText,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: family,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sampleText,
                      style: TextStyle(
                        fontFamily: family,
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? primary : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
