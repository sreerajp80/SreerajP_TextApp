import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'sections/about_section.dart';
import 'sections/appearance_section.dart';
import 'sections/editor_section.dart';
import 'sections/files_tabs_section.dart';
import 'sections/help_section.dart';
import 'sections/security_section.dart';
import 'sections/speech_section.dart';
import 'sections/sync_section.dart';
import 'settings_detail_screen.dart';

/// The Settings screen (Phase 11; card layout).
///
/// Instead of one long scroll, the screen is a menu of cards — one per section
/// (Appearance, Editor, Files & Tabs, Speech, Sync, Security, Help, About). Tapping a
/// card opens that section on its own page ([SettingsDetailScreen]). The section
/// widgets are unchanged; each is built with `showHeader: false` on its page
/// because the app bar already shows the title.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cards = <_SettingsCardData>[
      _SettingsCardData(
        icon: Icons.palette_outlined,
        title: l10n.appearSectionTitle,
        subtitle: l10n.appearCardSubtitle,
        builder: () => const AppearanceSection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.edit_outlined,
        title: l10n.editorSectionTitle,
        subtitle: l10n.editorCardSubtitle,
        builder: () => const EditorSection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.tab_outlined,
        title: l10n.filesTabsSectionTitle,
        subtitle: l10n.filesTabsCardSubtitle,
        builder: () => const FilesTabsSection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.record_voice_over_outlined,
        title: l10n.speechSectionTitle,
        subtitle: l10n.speechCardSubtitle,
        builder: () => const SpeechSection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.sync,
        title: l10n.syncSectionTitle,
        subtitle: l10n.syncCardSubtitle,
        builder: () => const SyncSection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.lock_outline,
        title: l10n.securitySectionTitle,
        subtitle: l10n.securityCardSubtitle,
        builder: () => const SecuritySection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.help_outline,
        title: l10n.helpSectionTitle,
        subtitle: l10n.helpCardSubtitle,
        builder: () => const HelpSection(),
      ),
      _SettingsCardData(
        icon: Icons.info_outline,
        title: l10n.aboutSectionTitle,
        subtitle: l10n.aboutCardSubtitle,
        builder: () => const AboutSection(showHeader: false),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [for (final card in cards) _SettingsCard(data: card)],
      ),
    );
  }
}

/// Data for one settings card and the page it opens.
class _SettingsCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() builder;

  const _SettingsCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });
}

/// A tappable card that opens its section on its own page.
class _SettingsCard extends StatelessWidget {
  final _SettingsCardData data;

  const _SettingsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(data.icon, color: theme.colorScheme.primary),
        title: Text(data.title),
        subtitle: Text(data.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SettingsDetailScreen(title: data.title, child: data.builder()),
          ),
        ),
      ),
    );
  }
}
