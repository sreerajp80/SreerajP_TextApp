import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';
import 'editor_settings.dart';

/// The one place the app changes and remembers editor behavior (task 11.2).
///
/// Follows the same pattern as `ThemeController`: hydrate synchronously in
/// [build] from the non-sensitive settings store, update in-memory state first,
/// then fire-and-forget the write. Sessions and save actions read this so a
/// changed setting takes effect on the next open/save.
class EditorSettingsController extends Notifier<EditorSettings> {
  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  EditorSettings build() => _load();

  EditorSettings _load() {
    final store = _store;
    return EditorSettings(
      lineEndingDefault: LineEndingDefault.fromPrefValue(
        store.getPlainString(EditorSettings.lineEndingKey),
      ),
      encodingDefault: EncodingDefault.fromPrefValue(
        store.getPlainString(EditorSettings.encodingKey),
      ),
      confirmOverwrite: store.getBool(EditorSettings.confirmOverwriteKey) ??
          EditorSettings.defaults.confirmOverwrite,
      autoSaveSeconds: store.getInt(EditorSettings.autoSaveSecondsKey) ??
          EditorSettings.defaults.autoSaveSeconds,
      openReadOnlyByDefault:
          store.getBool(EditorSettings.readOnlyDefaultKey) ??
              EditorSettings.defaults.openReadOnlyByDefault,
    );
  }

  void setLineEndingDefault(LineEndingDefault value) {
    state = state.copyWith(lineEndingDefault: value);
    _store.setPlainString(EditorSettings.lineEndingKey, value.prefValue);
  }

  void setEncodingDefault(EncodingDefault value) {
    state = state.copyWith(encodingDefault: value);
    _store.setPlainString(EditorSettings.encodingKey, value.prefValue);
  }

  void setConfirmOverwrite(bool value) {
    state = state.copyWith(confirmOverwrite: value);
    _store.setBool(EditorSettings.confirmOverwriteKey, value);
  }

  void setAutoSaveSeconds(int seconds) {
    state = state.copyWith(autoSaveSeconds: seconds);
    _store.setInt(EditorSettings.autoSaveSecondsKey, state.autoSaveSeconds);
  }

  void setOpenReadOnlyByDefault(bool value) {
    state = state.copyWith(openReadOnlyByDefault: value);
    _store.setBool(EditorSettings.readOnlyDefaultKey, value);
  }
}

final editorSettingsProvider =
    NotifierProvider<EditorSettingsController, EditorSettings>(
  EditorSettingsController.new,
);
