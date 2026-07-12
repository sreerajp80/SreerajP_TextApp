import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/editor_settings.dart';
import 'package:text_data/core/editor/editor_settings_controller.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/core/storage/key_value_store.dart';

import '../../support/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(KeyValueStore store) {
    final container = ProviderContainer(
      overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults when nothing is stored', () async {
    final store = await inMemoryKeyValueStore();
    final settings = containerWith(store).read(editorSettingsProvider);

    expect(settings.lineEndingDefault, LineEndingDefault.preserve);
    expect(settings.encodingDefault, EncodingDefault.preserve);
    expect(settings.confirmOverwrite, isTrue);
    expect(settings.autoSaveSeconds, EditorSettings.defaultAutoSaveSeconds);
    expect(settings.openReadOnlyByDefault, isFalse);
  });

  test('resolve() maps defaults to concrete values, preserve -> null', () {
    expect(LineEndingDefault.preserve.resolve(), isNull);
    expect(LineEndingDefault.lf.resolve(), LineEndingStyle.lf);
    expect(LineEndingDefault.crlf.resolve(), LineEndingStyle.crlf);
    expect(EncodingDefault.preserve.resolve(), isNull);
    expect(EncodingDefault.utf8.resolve(), TextEncodingType.utf8);
    expect(EncodingDefault.utf8Bom.resolve(), TextEncodingType.utf8Bom);
  });

  test('setters update state and persist', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(editorSettingsProvider.notifier);

    controller.setLineEndingDefault(LineEndingDefault.crlf);
    controller.setEncodingDefault(EncodingDefault.utf8Bom);
    controller.setConfirmOverwrite(false);
    controller.setAutoSaveSeconds(30);
    controller.setOpenReadOnlyByDefault(true);

    final s = container.read(editorSettingsProvider);
    expect(s.lineEndingDefault, LineEndingDefault.crlf);
    expect(s.encodingDefault, EncodingDefault.utf8Bom);
    expect(s.confirmOverwrite, isFalse);
    expect(s.autoSaveSeconds, 30);
    expect(s.openReadOnlyByDefault, isTrue);

    // Persisted: a fresh controller re-hydrates the same values.
    final reread = containerWith(store).read(editorSettingsProvider);
    expect(reread.lineEndingDefault, LineEndingDefault.crlf);
    expect(reread.autoSaveSeconds, 30);
    expect(reread.openReadOnlyByDefault, isTrue);
  });

  test('auto-save interval reflects seconds; zero means off', () async {
    final store = await inMemoryKeyValueStore();
    final container = containerWith(store);
    final controller = container.read(editorSettingsProvider.notifier);

    controller.setAutoSaveSeconds(0);
    final s = container.read(editorSettingsProvider);
    expect(s.autoSaveEnabled, isFalse);
    expect(s.autoSaveInterval, Duration.zero);

    controller.setAutoSaveSeconds(10);
    expect(container.read(editorSettingsProvider).autoSaveInterval,
        const Duration(seconds: 10));
  });

  test('auto-save seconds is clamped to a sane range', () {
    expect(
      const EditorSettings().copyWith(autoSaveSeconds: -5).autoSaveSeconds,
      0,
    );
    expect(
      const EditorSettings().copyWith(autoSaveSeconds: 99999).autoSaveSeconds,
      600,
    );
  });

  test('corrupt stored enum falls back to preserve', () async {
    final store = await inMemoryKeyValueStore();
    await store.setPlainString(EditorSettings.lineEndingKey, 'nonsense');
    await store.setPlainString(EditorSettings.encodingKey, 'nonsense');
    final s = containerWith(store).read(editorSettingsProvider);
    expect(s.lineEndingDefault, LineEndingDefault.preserve);
    expect(s.encodingDefault, EncodingDefault.preserve);
  });
}
