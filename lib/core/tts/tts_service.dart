import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_state.dart';

/// The platform side of text-to-speech, behind an interface so the
/// [TtsService] state machine stays host-testable (arch §12). The real
/// implementation wraps `flutter_tts`; tests inject a fake with controlled
/// voice states.
abstract class TtsEngine {
  /// The language codes the engine reports. Empty when there is no usable
  /// engine (so the service reports [TtsAvailability.unavailable]).
  Future<List<String>> languages();

  /// Whether [code]'s voice is installed and usable.
  Future<bool> isLanguageAvailable(String code);

  Future<void> setLanguage(String code);
  Future<void> speak(String text);
  Future<void> stop();

  /// Registers the callback fired when speaking finishes (or is stopped).
  void onComplete(void Function() handler);
}

/// Default [TtsEngine] backed by `flutter_tts` (task 5.5).
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _tts;

  FlutterTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  @override
  Future<List<String>> languages() async {
    try {
      final result = await _tts.getLanguages;
      if (result is List) {
        return result.map((e) => e.toString()).toList(growable: false);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> isLanguageAvailable(String code) async {
    try {
      final ok = await _tts.isLanguageAvailable(code);
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setLanguage(String code) => _tts.setLanguage(code);

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();

  @override
  void onComplete(void Function() handler) {
    _tts.setCompletionHandler(handler);
    _tts.setCancelHandler(handler);
  }
}

/// Read-content-aloud module (task 5.5).
///
/// Holds a small state machine that tells the UI whether a language is
/// `ready` / `needsInstall` / `unavailable`, so reader screens never show a
/// dead button. English works now; Malayalam is checked the same way and the
/// UI drives the guided install (finished in Phase 11.4). If a voice that was
/// ready goes missing, [speak] auto-disables and reports it via a re-check.
class TtsService extends ChangeNotifier {
  final TtsEngine _engine;
  bool _speaking = false;
  bool _handlerBound = false;

  TtsService(this._engine);

  bool get isSpeaking => _speaking;

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    notifyListeners();
  }

  /// Reports whether [language] can be spoken right now.
  Future<TtsAvailability> availability(TtsLanguage language) async {
    final langs = await _engine.languages();
    if (langs.isEmpty) return TtsAvailability.unavailable;
    final ok = await _engine.isLanguageAvailable(language.code);
    return ok ? TtsAvailability.ready : TtsAvailability.needsInstall;
  }

  /// Speaks [text] in [language]. Re-checks availability first, so a voice that
  /// disappeared since the last check does not throw — it returns the current
  /// [TtsAvailability] instead (auto-disable). On success returns
  /// [TtsAvailability.ready].
  Future<TtsAvailability> speak(String text, TtsLanguage language) async {
    final state = await availability(language);
    if (state != TtsAvailability.ready) return state;

    if (!_handlerBound) {
      _engine.onComplete(() => _setSpeaking(false));
      _handlerBound = true;
    }
    await _engine.setLanguage(language.code);
    _setSpeaking(true);
    await _engine.speak(text);
    return TtsAvailability.ready;
  }

  Future<void> stop() async {
    _setSpeaking(false);
    await _engine.stop();
  }
}
