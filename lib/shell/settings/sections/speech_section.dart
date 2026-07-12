import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/output/output_providers.dart';
import '../../../core/tts/tts_installer.dart';
import '../../../core/tts/tts_settings.dart';
import '../../../core/tts/tts_state.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

/// Speech (TTS) settings (task 11.4): English on/off and a Malayalam toggle with
/// the guided-install / auto-disable flow. Never shows a dead button — when the
/// Malayalam voice is missing it offers the install path; when no engine exists
/// at all it turns the toggle off with a notice.
class SpeechSection extends ConsumerStatefulWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const SpeechSection({super.key, this.showHeader = true});

  @override
  ConsumerState<SpeechSection> createState() => _SpeechSectionState();
}

class _SpeechSectionState extends ConsumerState<SpeechSection> {
  TtsAvailability? _malayalam;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(ttsSettingsProvider).malayalamEnabled) {
      _checkMalayalam();
    }
  }

  Future<void> _checkMalayalam() async {
    setState(() => _checking = true);
    final state = await ref
        .read(ttsServiceProvider)
        .availability(TtsLanguage.malayalam);
    if (!mounted) return;
    setState(() {
      _malayalam = state;
      _checking = false;
    });
    // No engine at all → turn the toggle off so nothing pretends to work.
    if (state == TtsAvailability.unavailable) {
      ref.read(ttsSettingsProvider.notifier).setMalayalamEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(ttsSettingsProvider);
    final controller = ref.read(ttsSettingsProvider.notifier);
    final installer = ref.read(ttsInstallerProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          SettingsSectionHeader(title: l10n.speechSectionTitle),
        SwitchListTile(
          title: Text(l10n.speechEnglish),
          subtitle: Text(l10n.speechEnglishSub),
          value: settings.englishEnabled,
          onChanged: controller.setEnglishEnabled,
        ),
        SwitchListTile(
          title: Text(l10n.speechMalayalam),
          subtitle: Text(l10n.speechMalayalamSub),
          value: settings.malayalamEnabled,
          onChanged: (v) {
            controller.setMalayalamEnabled(v);
            if (v) {
              _checkMalayalam();
            } else {
              setState(() => _malayalam = null);
            }
          },
        ),
        if (settings.malayalamEnabled) _malayalamStatus(context, installer),
      ],
    );
  }

  Widget _malayalamStatus(BuildContext context, TtsInstaller installer) {
    final l10n = AppLocalizations.of(context);
    if (_checking) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(l10n.speechChecking),
      );
    }
    switch (_malayalam) {
      case TtsAvailability.ready:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l10n.speechMlReady),
        );
      case TtsAvailability.needsInstall:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.speechMlNeedsInstall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        _launch(context, installer.openInstallVoiceData),
                    child: Text(l10n.speechInstallVoice),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _launch(context, installer.openTtsSettings),
                    child: Text(l10n.speechOpenTtsSettings),
                  ),
                  TextButton(
                    onPressed: _checkMalayalam,
                    child: Text(l10n.speechCheckAgain),
                  ),
                ],
              ),
            ],
          ),
        );
      case TtsAvailability.unavailable:
      case null:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l10n.speechNoEngine),
        );
    }
  }

  Future<void> _launch(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = await action();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.speechCouldNotOpen)));
    }
  }
}
