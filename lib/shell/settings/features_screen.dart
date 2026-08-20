import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// One feature item displayed on the Features screen.
class _AppFeature {
  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;

  const _AppFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
  });
}

/// A category grouping related features.
class _FeatureCategory {
  final String name;
  final String subtitle;
  final IconData icon;
  final List<_AppFeature> features;

  const _FeatureCategory({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.features,
  });
}

/// Lists all features of SreerajP Text App (TextData), grouped by category with visual cards.
class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  static const List<_FeatureCategory> _categories = [
    _FeatureCategory(
      name: 'Multi-Format Document Engine',
      subtitle:
          'Open, inspect, edit, and save plain-text and structured data formats',
      icon: Icons.folder_open_outlined,
      features: [
        _AppFeature(
          title: '5 Core Formats Supported',
          description:
              'Native viewing and editing for Plain Text (TXT), Markdown (MD), Tabular CSV, JSON Data trees, and XML structures.',
          icon: Icons.description_outlined,
          highlights: [
            'TXT & Markdown',
            'CSV Tables',
            'JSON & XML',
            'Format Detection',
          ],
        ),
        _AppFeature(
          title: 'Multi-Tab Document Workspace',
          description:
              'Open multiple files at the same time in independent tabs. Each tab retains its own scroll position, search queries, and edit history.',
          icon: Icons.tab_outlined,
          highlights: [
            'Simultaneous tabs',
            'Per-tab state',
            'Quick tab switcher',
          ],
        ),
        _AppFeature(
          title: 'Scoped Storage SAF Integration',
          description:
              'Seamlessly open and save files using Android Storage Access Framework with persistable URI permissions without asking for broad disk access.',
          icon: Icons.storage_outlined,
          highlights: [
            'Zero broad storage permission',
            'Atomic replace saves',
            'SAF URIs',
          ],
        ),
        _AppFeature(
          title: 'Recent Files & Bookmarks',
          description:
              'Instant access to recently edited files, pinned favorites, and bookmarks with encoding and timestamp indicators.',
          icon: Icons.history_toggle_off_outlined,
          highlights: [
            'Recent documents',
            'Favorites index',
            'Missing file detection',
          ],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'Smart Code & Text Editor',
      subtitle:
          'Professional text editing tools, multi-cursor, and safety safeguards',
      icon: Icons.edit_note_outlined,
      features: [
        _AppFeature(
          title: 'Multi-Cursor Editing & Precision Carets',
          description:
              'Insert multiple cursors to edit, append, and format code across multiple lines simultaneously with keyboard shortcuts or tap gestures.',
          icon: Icons.view_column_outlined,
          highlights: [
            'Multiple carets',
            'Column editing',
            'Simultaneous typing',
          ],
        ),
        _AppFeature(
          title: 'Advanced Find & Replace with Regex',
          description:
              'Full regular expression search with capture group support (\$1), case-sensitivity toggles, whole-word matching, and live match counts.',
          icon: Icons.find_replace_outlined,
          highlights: [
            'Regex & capture groups',
            'Match highlighting',
            'Replace all preview',
          ],
        ),
        _AppFeature(
          title: 'Scoped Replacement',
          description:
              'Limit search and replace operations to the entire document, the active selection, a specific CSV column, or a JSON/XML subtree.',
          icon: Icons.tune_outlined,
          highlights: [
            'Column-scoped replace',
            'Subtree scope',
            'Selection only',
          ],
        ),
        _AppFeature(
          title: 'Draft Auto-Save & Crash Recovery',
          description:
              'Edits are automatically stored in an encrypted draft space. If the app is closed or killed, your unsaved draft is safely recovered on next open.',
          icon: Icons.restore_page_outlined,
          highlights: [
            'Periodic auto-drafts',
            '1-tap draft restore',
            'Zero edit loss',
          ],
        ),
        _AppFeature(
          title: 'Read-Only Safety Lock',
          description:
              'Lock documents in read-only mode to prevent accidental keystrokes and gestures while browsing critical files.',
          icon: Icons.lock_clock_outlined,
          highlights: [
            'Accidental touch guard',
            'Visual lock indicator',
            '1-tap toggle',
          ],
        ),
        _AppFeature(
          title: 'Line Numbering & Code Folding',
          description:
              'Gutter line numbering, soft line wrapping, code folding for structured blocks, and indent guides.',
          icon: Icons.format_list_numbered_outlined,
          highlights: ['Line gutters', 'Block folding', 'Indentation guides'],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'Data Analysis & SQL Querying',
      subtitle:
          'Run relational queries and structural filters directly on your files',
      icon: Icons.query_stats_outlined,
      features: [
        _AppFeature(
          title: 'In-Memory SQLite SQL Queries',
          description:
              'Execute standard SQL SELECT queries with WHERE, GROUP BY, ORDER BY, and JOIN on your CSV and JSON files without an external server.',
          icon: Icons.dataset_outlined,
          highlights: [
            'Full SQL syntax',
            'Instant table load',
            'Export query results',
          ],
        ),
        _AppFeature(
          title: 'Interactive CSV Table Grid',
          description:
              'View CSV files in a responsive spreadsheet table with column sorting, column filtering, search highlights, and quick cell editing.',
          icon: Icons.table_chart_outlined,
          highlights: [
            'Spreadsheet view',
            'Column sort & filter',
            'Cell edit mode',
          ],
        ),
        _AppFeature(
          title: 'JMESPath & JSONPath Query Engine',
          description:
              'Extract, filter, and reshape complex nested JSON payloads using expressive JMESPath queries and interactive tree folding.',
          icon: Icons.account_tree_outlined,
          highlights: [
            'JMESPath filtering',
            'Collapsible JSON tree',
            'Syntax validation',
          ],
        ),
        _AppFeature(
          title: 'XML DOM Tree & XPath Extraction',
          description:
              'Navigate XML tags hierarchically, validate schema well-formedness, query elements with XPath, and format tag indentation.',
          icon: Icons.code_outlined,
          highlights: [
            'XPath queries',
            'XML tree explorer',
            'Well-formedness check',
          ],
        ),
        _AppFeature(
          title: 'Split Array Transformations',
          description:
              'Extract nested arrays in JSON/CSV and pivot or unnest rows cleanly for easier tabular analysis.',
          icon: Icons.call_split_outlined,
          highlights: [
            'Array unnesting',
            'Row transformation',
            'Table conversion',
          ],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'P2P LAN Sync & Optical AirQR',
      subtitle:
          'Zero-cloud offline transfer between devices over Wi-Fi and optical QR',
      icon: Icons.sync_alt_outlined,
      features: [
        _AppFeature(
          title: 'Local Wi-Fi P2P Device Sync',
          description:
              'Transfer documents directly between two Android devices on the same Wi-Fi network with AES-256-GCM encryption and zero internet.',
          icon: Icons.wifi_tethering_outlined,
          highlights: [
            '100% offline LAN',
            'End-to-end encrypted',
            'QR & PIN pairing',
          ],
        ),
        _AppFeature(
          title: 'Optical AirQR Air-Gap Data Beam',
          description:
              'Transmit documents across physically isolated (air-gapped) devices using high-speed animated multi-frame QR codes with Reed-Solomon error correction.',
          icon: Icons.qr_code_2_outlined,
          highlights: [
            'Air-gapped transfer',
            'Animated QR sequence',
            'Forward error correction',
          ],
        ),
        _AppFeature(
          title: 'Live Document Diff & Delta Sync',
          description:
              'Compare two document versions side-by-side with visual addition/deletion highlights and selectively merge changes.',
          icon: Icons.difference_outlined,
          highlights: [
            'Side-by-side diff',
            'Selective merge',
            'Conflict resolution',
          ],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'Privacy, Security & Vault',
      subtitle:
          'Protect sensitive documents with biometric locks and tamper-proof audits',
      icon: Icons.shield_outlined,
      features: [
        _AppFeature(
          title: 'Biometric & App PIN Lock',
          description:
              'Lock the entire app or private documents with fingerprint, face unlock, or a custom app security PIN with recovery codes.',
          icon: Icons.fingerprint_outlined,
          highlights: [
            'Fingerprint & Face unlock',
            'App PIN safeguard',
            'Recovery passkey',
          ],
        ),
        _AppFeature(
          title: 'Screenshot Guard Defense',
          description:
              'Enforces FLAG_SECURE to prevent other apps, screen recorders, or recent-apps previews from capturing confidential text.',
          icon: Icons.screenshot_outlined,
          highlights: [
            'Screenshot blocking',
            'Recents preview blackout',
            'Recording defense',
          ],
        ),
        _AppFeature(
          title: 'Tamper-Proof Security Audit Log',
          description:
              'Maintains a cryptographic SHA-256 chained audit log of all document access, saves, exports, and security setting modifications.',
          icon: Icons.history_edu_outlined,
          highlights: [
            'Cryptographic chaining',
            'Event timestamps',
            'Verification badge',
          ],
        ),
        _AppFeature(
          title: 'Encrypted Vault Backups (.txbak)',
          description:
              'Create AES-256 encrypted archive backups of all app settings, recents, and bookmarks to restore on another phone.',
          icon: Icons.archive_outlined,
          highlights: [
            'Encrypted backup file',
            'Password protection',
            '1-tap restore',
          ],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'Voice & Text-to-Speech (TTS)',
      subtitle:
          'Listen to your documents read aloud in natural voices with speed control',
      icon: Icons.record_voice_over_outlined,
      features: [
        _AppFeature(
          title: 'Bilingual English & Malayalam TTS',
          description:
              'Full on-device speech engine supporting natural English and Malayalam reading with intelligent sentence parsing.',
          icon: Icons.volume_up_outlined,
          highlights: [
            'English & Malayalam',
            'Sentence highlighting',
            'Zero cloud audio',
          ],
        ),
        _AppFeature(
          title: 'Playback & Voice Tuning',
          description:
              'Fine-tune speech rate, pitch, and voice selection, with pause, resume, and jump-to-paragraph controls.',
          icon: Icons.speed_outlined,
          highlights: [
            'Speed & pitch sliders',
            'Play/Pause controls',
            'Voice selector',
          ],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'Export, Conversion & Printing',
      subtitle:
          'Convert documents to other formats or print with custom layout rules',
      icon: Icons.output_outlined,
      features: [
        _AppFeature(
          title: 'Multi-Format Conversion',
          description:
              'Export documents to PDF, rendered HTML, Markdown, CSV, JSON, XML, or plain text with customizable output formatting.',
          icon: Icons.transform_outlined,
          highlights: [
            'Export to PDF & HTML',
            'Inter-format conversion',
            'Custom indentation',
          ],
        ),
        _AppFeature(
          title: 'Direct Printing Service',
          description:
              'Send documents directly to any connected Wi-Fi or Bluetooth printer with clean pagination and formatting.',
          icon: Icons.print_outlined,
          highlights: [
            'AirPrint / Mopria support',
            'Custom paper sizing',
            'Print preview',
          ],
        ),
        _AppFeature(
          title: 'Zip Bundling & Quick Share',
          description:
              'Compress active documents into password-safe ZIP archives before sharing via the Android share sheet.',
          icon: Icons.folder_zip_outlined,
          highlights: [
            'Instant zip archive',
            'Android share sheet',
            'Attachment packaging',
          ],
        ),
      ],
    ),
    _FeatureCategory(
      name: 'Personalization & Accessibility',
      subtitle:
          'Comfortable reading themes, bespoke fonts, and flexible text scales',
      icon: Icons.palette_outlined,
      features: [
        _AppFeature(
          title: 'Light, Dark & Sepia Themes',
          description:
              'Switch between sleek Dark mode, crisp Light mode, or eye-friendly Sepia mode for extended reading sessions.',
          icon: Icons.dark_mode_outlined,
          highlights: [
            'Sepia reading look',
            'System auto mode',
            'Contrast optimization',
          ],
        ),
        _AppFeature(
          title: 'Bespoke English & Malayalam Typography',
          description:
              'Select from curated open-source typefaces including Inter, Lora, JetBrains Mono, Manjari, Rachana, and Noto Sans Malayalam.',
          icon: Icons.font_download_outlined,
          highlights: [
            'Inter & JetBrains Mono',
            'Manjari & Rachana',
            'Monospace code view',
          ],
        ),
        _AppFeature(
          title: 'Text Scale & Line Spacing',
          description:
              'Adjust text font size from 50% to 300% and line height from compact to relaxed spacing with live visual previews.',
          icon: Icons.format_size_outlined,
          highlights: [
            '50% - 300% scaling',
            'Adjustable line height',
            'Soft word-wrap toggle',
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featuresSectionTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeaderCard(context, l10n),
          const SizedBox(height: 20),
          for (final category in _categories) ...[
            _buildCategoryHeader(context, category),
            const SizedBox(height: 10),
            _buildCategoryCard(context, category),
            const SizedBox(height: 24),
          ],
        ],
      ),
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
                Icons.stars_rounded,
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
                    l10n.featuresHeaderTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.featuresHeaderSubtitle,
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

  Widget _buildCategoryHeader(BuildContext context, _FeatureCategory category) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(
                category.name.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            category.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _FeatureCategory category) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < category.features.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            _buildFeatureTile(context, category.features[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, _AppFeature feature) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final mutedText = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (feature.highlights.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: feature.highlights.map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          h,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
