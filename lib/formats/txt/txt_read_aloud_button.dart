import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/output/output_providers.dart';
import '../../core/tts/tts_service.dart';
import '../../core/tts/tts_state.dart';
import '../../l10n/app_localizations.dart';
import 'txt_document_session.dart';

/// A "Read aloud" toggle for a TXT document (task 5.5, English).
///
/// It asks the [TtsService] whether English can be spoken and never shows a
/// dead button: while the engine is `unavailable` it renders nothing. When
/// ready it speaks the current text and flips to a "Stop" icon; a voice that
/// went missing since the check surfaces a friendly notice instead of failing.
class TxtReadAloudButton extends ConsumerStatefulWidget {
  final TxtDocumentSession session;
  const TxtReadAloudButton({super.key, required this.session});

  @override
  ConsumerState<TxtReadAloudButton> createState() => _TxtReadAloudButtonState();
}

class _TxtReadAloudButtonState extends ConsumerState<TxtReadAloudButton> {
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
    final result = await tts.speak(
      widget.session.textContent.text,
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
    // Hidden until the check runs, and while the engine is unavailable.
    if (_availability == null || _availability == TtsAvailability.unavailable) {
      return const SizedBox.shrink();
    }
    final tts = ref.watch(ttsServiceProvider);
    return ListenableBuilder(
      listenable: tts,
      builder: (context, _) {
        final speaking = tts.isSpeaking;
        return IconButton(
          key: const Key('txt-read-aloud'),
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
