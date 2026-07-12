import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/tts/tts_service.dart';
import 'package:text_data/core/tts/tts_state.dart';

/// A controllable fake engine: [available] holds the set of installed language
/// codes; an empty [installed] list means "no engine".
class _FakeEngine implements TtsEngine {
  List<String> installed;
  Set<String> available;
  String? spokenText;
  String? spokenLang;
  bool stopped = false;

  _FakeEngine({required this.installed, required this.available});

  @override
  Future<List<String>> languages() async => installed;

  @override
  Future<bool> isLanguageAvailable(String code) async =>
      available.contains(code);

  @override
  Future<void> setLanguage(String code) async {
    spokenLang = code;
  }

  @override
  Future<void> speak(String text) async {
    spokenText = text;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  void onComplete(void Function() handler) {}
}

void main() {
  group('TtsService state machine', () {
    test('ready when the language voice is installed', () async {
      final engine = _FakeEngine(
        installed: const ['en-US', 'ml-IN'],
        available: {'en-US', 'ml-IN'},
      );
      final service = TtsService(engine);
      expect(
        await service.availability(TtsLanguage.malayalam),
        TtsAvailability.ready,
      );
    });

    test('needsInstall when the engine is present but the voice is missing',
        () async {
      final engine = _FakeEngine(
        installed: const ['en-US'],
        available: {'en-US'},
      );
      final service = TtsService(engine);
      expect(
        await service.availability(TtsLanguage.malayalam),
        TtsAvailability.needsInstall,
      );
    });

    test('unavailable when there is no usable engine', () async {
      final engine = _FakeEngine(installed: const [], available: {});
      final service = TtsService(engine);
      expect(
        await service.availability(TtsLanguage.english),
        TtsAvailability.unavailable,
      );
    });

    test('speak reads aloud when ready', () async {
      final engine = _FakeEngine(
        installed: const ['en-US'],
        available: {'en-US'},
      );
      final service = TtsService(engine);
      final result = await service.speak('hello', TtsLanguage.english);
      expect(result, TtsAvailability.ready);
      expect(engine.spokenText, 'hello');
      expect(engine.spokenLang, 'en-US');
      expect(service.isSpeaking, isTrue);
    });

    test('speak auto-disables when a ready voice has gone missing', () async {
      final engine = _FakeEngine(
        installed: const ['en-US'],
        available: {'en-US'},
      );
      final service = TtsService(engine);

      // The voice disappears between checks.
      engine.available = {};
      final result = await service.speak('hello', TtsLanguage.english);

      expect(result, TtsAvailability.needsInstall);
      expect(engine.spokenText, isNull);
      expect(service.isSpeaking, isFalse);
    });
  });
}
