import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/output/output_providers.dart';
import '../../core/tts/tts_service.dart';
import '../../core/tts/tts_state.dart';
import '../../l10n/app_localizations.dart';
import 'md_document_session.dart';

/// A "Read aloud" toggle for a Markdown document (task 5.5, English).
///
/// Mirrors the TXT button: it asks the [TtsService] whether English can be
/// spoken and never shows a dead button — while the engine is `unavailable` it
/// renders nothing. When ready it speaks the document body and flips to a "Stop"
/// icon.
class MdReadAloudButton extends ConsumerStatefulWidget {
  final MdDocumentSession session;
  const MdReadAloudButton({super.key, required this.session});

  @override
  ConsumerState<MdReadAloudButton> createState() => _MdReadAloudButtonState();
}

class _MdReadAloudButtonState extends ConsumerState<MdReadAloudButton> {
  TtsAvailability? _availability;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final tts = ref.read(ttsServiceProvider);
    final state = await tts.availability(TtsLanguage.english);
    if (mounted) setState(() => _availability = state);
  }

  Future<void> _toggle() async {
    final tts = ref.read(ttsServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (tts.isSpeaking) {
      await tts.stop();
      return;
    }
    // Read the body text (front matter stripped) rather than the raw markup.
    final result = await tts.speak(
      widget.session.frontMatter.body,
      TtsLanguage.english,
    );
    if (result != TtsAvailability.ready) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.readAloudUnavailable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_availability == null || _availability == TtsAvailability.unavailable) {
      return const SizedBox.shrink();
    }
    final tts = ref.watch(ttsServiceProvider);
    return ListenableBuilder(
      listenable: tts,
      builder: (context, _) {
        final speaking = tts.isSpeaking;
        return IconButton(
          key: const Key('md-read-aloud'),
          tooltip: speaking
              ? AppLocalizations.of(context).readAloudStop
              : AppLocalizations.of(context).readAloud,
          isSelected: speaking,
          icon: const Icon(Icons.volume_up_outlined),
          selectedIcon: const Icon(Icons.stop_circle_outlined),
          onPressed: _toggle,
        );
      },
    );
  }
}
