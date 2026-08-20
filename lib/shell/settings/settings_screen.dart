import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/settings/features_screen.dart';
import 'package:sreerajp_textapp/shell/settings/sections/about_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/appearance_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/audit_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/backup_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/editor_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/files_tabs_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/help_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/security_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/speech_section.dart';
import 'package:sreerajp_textapp/shell/settings/sections/sync_section.dart';
import 'package:sreerajp_textapp/shell/settings/settings_detail_screen.dart';

/// The Settings screen (card layout).
///
/// Instead of one long scroll, the screen is a menu of cards — one per section
/// (Appearance, Features, Editor, Files & Tabs, Speech, Sync, Security, Audit,
/// Backup, Help, About). Tapping a card opens that section on its own page
/// ([SettingsDetailScreen]).
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
        icon: Icons.stars_outlined,
        title: l10n.featuresSectionTitle,
        subtitle: l10n.featuresCardSubtitle,
        builder: () => const FeaturesScreen(),
        isFullScreen: true,
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
        icon: Icons.verified_user_outlined,
        title: l10n.auditSectionTitle,
        subtitle: l10n.auditCardSubtitle,
        builder: () => const AuditSection(showHeader: false),
      ),
      _SettingsCardData(
        icon: Icons.archive_outlined,
        title: l10n.backupSectionTitle,
        subtitle: l10n.backupCardSubtitle,
        builder: () => const BackupSection(showHeader: false),
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
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [for (final card in cards) _SettingsCard(data: card)],
        ),
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
  final bool isFullScreen;

  const _SettingsCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
    this.isFullScreen = false,
  });
}

/// A styled card with a tinted icon badge that opens its section on its own page.
class _SettingsCard extends StatelessWidget {
  final _SettingsCardData data;

  const _SettingsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final mutedText = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => data.isFullScreen
                  ? data.builder()
                  : SettingsDetailScreen(
                      title: data.title,
                      child: data.builder(),
                    ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(data.icon, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
