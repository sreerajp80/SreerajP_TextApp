import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/settings/settings_detail_screen.dart';

/// Data for one help topic.
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

/// A category grouping related help topics.
class _HelpCategory {
  final String title;
  final IconData icon;
  final List<_HelpTopicData> topics;

  const _HelpCategory({
    required this.title,
    required this.icon,
    required this.topics,
  });
}

/// Help Center shown from the Help card on the Settings screen.
///
/// Features a gradient header, categorized guide sections, topic cards,
/// and live search filtering across all topics.
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

  List<_HelpCategory> _buildCategories(AppLocalizations l10n) {
    return [
      _HelpCategory(
        title: l10n.helpCategoryEditing,
        icon: Icons.edit_note_outlined,
        topics: [
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
            icon: Icons.dashboard_customize_outlined,
            title: l10n.helpFormatToolsTitle,
            subtitle: l10n.helpFormatToolsSubtitle,
            body: l10n.helpFormatToolsBody,
          ),
          _HelpTopicData(
            icon: Icons.call_split,
            title: l10n.helpSplitArrayTitle,
            subtitle: l10n.helpSplitArraySubtitle,
            body: l10n.helpSplitArrayBody,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryData,
        icon: Icons.query_stats_outlined,
        topics: [
          _HelpTopicData(
            icon: Icons.query_stats,
            title: l10n.helpSqlQueryTitle,
            subtitle: l10n.helpSqlQuerySubtitle,
            body: l10n.helpSqlQueryBody,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryPrivacy,
        icon: Icons.shield_outlined,
        topics: [
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
            icon: Icons.verified_outlined,
            title: l10n.helpAuditLogTitle,
            subtitle: l10n.helpAuditLogSubtitle,
            body: l10n.helpAuditLogBody,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategorySync,
        icon: Icons.sync_alt_outlined,
        topics: [
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
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryVoice,
        icon: Icons.record_voice_over_outlined,
        topics: [
          _HelpTopicData(
            icon: Icons.record_voice_over_outlined,
            title: l10n.helpSpeechTitle,
            subtitle: l10n.helpSpeechSubtitle,
            body: l10n.helpSpeechBody,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categories = _buildCategories(l10n);

    final allTopics = [for (final c in categories) ...c.topics];

    final isSearching = _query.trim().isNotEmpty;
    final filteredTopics = !isSearching
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isSearching) ...[
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
            for (final topic in filteredTopics) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HelpTopicCard(data: topic),
              ),
              const SizedBox(height: 8),
            ],
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeaderCard(context, l10n),
          ),
          const SizedBox(height: 20),
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategoryHeader(context, category),
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
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < category.topics.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      _HelpTopicTile(data: category.topics[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.12),
              theme.colorScheme.secondary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.help_center_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.helpSectionHeader,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.helpSectionSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, _HelpCategory category) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Icon(category.icon, size: 18, color: primary),
        const SizedBox(width: 8),
        Text(
          category.title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// A list tile for a help topic inside a category card.
class _HelpTopicTile extends StatelessWidget {
  final _HelpTopicData data;

  const _HelpTopicTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsDetailScreen(
            title: data.title,
            child: _HelpTopicDetail(data: data),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// A standalone card for search-filtered help topic items.
class _HelpTopicCard extends StatelessWidget {
  final _HelpTopicData data;

  const _HelpTopicCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SettingsDetailScreen(
              title: data.title,
              child: _HelpTopicDetail(data: data),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
