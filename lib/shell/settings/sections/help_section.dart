import 'package:flutter/material.dart';

import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/shell/settings/settings_detail_screen.dart';

/// Help topics shown from the Help card on the Settings screen.
///
/// Each topic is a tappable card (icon + title + subtitle + chevron) that
/// opens a detail page with the full help text. Includes an in-page search
/// bar for quick keyword filtering across all topics.
class HelpSection extends StatefulWidget {
  const HelpSection({super.key});

  @override
  State<HelpSection> createState() => _HelpSectionState();
}

class _HelpSectionState extends State<HelpSection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_HelpTopicData> _buildTopics(AppLocalizations l10n) {
    return <_HelpTopicData>[
      _HelpTopicData(
        icon: Icons.sync_alt,
        title: l10n.helpP2pSyncTitle,
        subtitle: l10n.helpP2pSyncSubtitle,
        body: l10n.helpP2pSyncBody,
      ),
      _HelpTopicData(
        icon: Icons.qr_code_2,
        title: l10n.helpQrSharingTitle,
        subtitle: l10n.helpQrSharingSubtitle,
        body: l10n.helpQrSharingBody,
      ),
      _HelpTopicData(
        icon: Icons.shield_outlined,
        title: l10n.helpPrivacyShieldTitle,
        subtitle: l10n.helpPrivacyShieldSubtitle,
        body: l10n.helpPrivacyShieldBody,
      ),
      _HelpTopicData(
        icon: Icons.lock_outline,
        title: l10n.helpVaultBackupTitle,
        subtitle: l10n.helpVaultBackupSubtitle,
        body: l10n.helpVaultBackupBody,
      ),
      _HelpTopicData(
        icon: Icons.query_stats,
        title: l10n.helpSqlQueryTitle,
        subtitle: l10n.helpSqlQuerySubtitle,
        body: l10n.helpSqlQueryBody,
      ),
      _HelpTopicData(
        icon: Icons.view_column_outlined,
        title: l10n.helpMultiCursorTitle,
        subtitle: l10n.helpMultiCursorSubtitle,
        body: l10n.helpMultiCursorBody,
      ),
      _HelpTopicData(
        icon: Icons.search,
        title: l10n.helpSearchTitle,
        subtitle: l10n.helpSearchSubtitle,
        body: l10n.helpSearchBody,
      ),
      _HelpTopicData(
        icon: Icons.verified_outlined,
        title: l10n.helpAuditLogTitle,
        subtitle: l10n.helpAuditLogSubtitle,
        body: l10n.helpAuditLogBody,
      ),
      _HelpTopicData(
        icon: Icons.dashboard_customize_outlined,
        title: l10n.helpFormatToolsTitle,
        subtitle: l10n.helpFormatToolsSubtitle,
        body: l10n.helpFormatToolsBody,
      ),
      _HelpTopicData(
        icon: Icons.record_voice_over_outlined,
        title: l10n.helpSpeechTitle,
        subtitle: l10n.helpSpeechSubtitle,
        body: l10n.helpSpeechBody,
      ),
      _HelpTopicData(
        icon: Icons.call_split,
        title: l10n.helpSplitArrayTitle,
        subtitle: l10n.helpSplitArraySubtitle,
        body: l10n.helpSplitArrayBody,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allTopics = _buildTopics(l10n);

    final filteredTopics = _query.trim().isEmpty
        ? allTopics
        : allTopics.where((topic) {
            final q = _query.trim().toLowerCase();
            return topic.title.toLowerCase().contains(q) ||
                topic.subtitle.toLowerCase().contains(q) ||
                topic.body.toLowerCase().contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: l10n.helpSearchFilterHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (filteredTopics.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.helpNoTopicsFound,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          for (final topic in filteredTopics) _HelpTopicCard(data: topic),
      ],
    );
  }
}

/// Data for one help topic card.
class _HelpTopicData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  const _HelpTopicData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

/// A tappable card that opens the full help text on a detail page.
class _HelpTopicCard extends StatelessWidget {
  final _HelpTopicData data;

  const _HelpTopicCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            data.icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        title: Text(
          data.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            data.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SettingsDetailScreen(
              title: data.title,
              child: _HelpTopicDetail(data: data),
            ),
          ),
        ),
      ),
    );
  }
}

/// The detail page content for a single help topic.
class _HelpTopicDetail extends StatelessWidget {
  final _HelpTopicData data;

  const _HelpTopicDetail({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              data.body,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
