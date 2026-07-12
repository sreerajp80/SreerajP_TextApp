import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/config_service.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

/// About settings (task 11.7). Every value comes from `app_config.json` via
/// [appConfigProvider] — editing the config changes this screen with no code
/// change (arch §8.1). A friendly line shows while it loads or if it fails.
class AboutSection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const AboutSection({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SettingsSectionHeader(title: l10n.aboutSectionTitle),
        config.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.aboutLoading),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.aboutUnavailable),
          ),
          data: (c) => _details(context, c),
        ),
      ],
    );
  }

  Widget _details(BuildContext context, AppConfig c) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(c.appName, style: theme.textTheme.titleMedium),
          subtitle: Text(c.description),
        ),
        ListTile(
          title: Text(l10n.aboutVersion),
          subtitle: Text(l10n.aboutVersionValue(c.version, c.build)),
        ),
        for (final entry in c.details.entries)
          if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value),
              onTap: entry.key.trim().toLowerCase() == 'email'
                  ? () => _open('mailto:${entry.value}', context)
                  : null,
            ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Center(child: Text('Made with ❤ from India')),
        ),
      ],
    );
  }

  Future<void> _open(String url, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.linkCouldNotOpen)));
    }
  }
}
