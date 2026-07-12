import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/output/output_providers.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/tts/tts_installer.dart';
import 'package:text_data/core/tts/tts_service.dart';
import 'package:text_data/core/tts/tts_settings.dart';
import 'package:text_data/shell/settings/sections/speech_section.dart';

import '../../support/test_support.dart';

/// Engine with a controllable set of installed languages and available voices.
class _FakeEngine implements TtsEngine {
  final List<String> installed;
  final Set<String> available;
  _FakeEngine({required this.installed, required this.available});

  @override
  Future<List<String>> languages() async => installed;
  @override
  Future<bool> isLanguageAvailable(String code) async =>
      available.contains(code);
  @override
  Future<void> setLanguage(String code) async {}
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
  @override
  void onComplete(void Function() handler) {}
}

class _FakeInstaller implements TtsInstaller {
  int installCalls = 0;
  int settingsCalls = 0;
  @override
  Future<bool> openInstallVoiceData() async {
    installCalls++;
    return true;
  }

  @override
  Future<bool> openTtsSettings() async {
    settingsCalls++;
    return true;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required KeyValueStore store,
    required TtsEngine engine,
    required TtsInstaller installer,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
          ttsServiceProvider.overrideWithValue(TtsService(engine)),
          ttsInstallerProvider.overrideWithValue(installer),
        ],
        child: localizedApp(home: const Scaffold(body: SpeechSection())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('turning Malayalam on with a missing voice offers the install',
      (tester) async {
    final store = await inMemoryKeyValueStore();
    final installer = _FakeInstaller();
    // An engine exists (English installed) but the Malayalam voice is missing.
    await pump(
      tester,
      store: store,
      engine: _FakeEngine(installed: ['en-US'], available: {'en-US'}),
      installer: installer,
    );

    await tester.tap(find.text('Malayalam'));
    await tester.pumpAndSettle();

    expect(find.text('Install voice data'), findsOneWidget);
    await tester.tap(find.text('Install voice data'));
    await tester.pumpAndSettle();
    expect(installer.installCalls, 1);
  });

  testWidgets('turning Malayalam on with no engine auto-disables the toggle',
      (tester) async {
    final store = await inMemoryKeyValueStore();
    await pump(
      tester,
      store: store,
      engine: _FakeEngine(installed: const [], available: const {}),
      installer: _FakeInstaller(),
    );

    await tester.tap(find.text('Malayalam'));
    await tester.pumpAndSettle();

    // Auto-disabled: the stored flag is back to false.
    expect(store.getBool(TtsSettings.malayalamKey), isFalse);
  });
}
