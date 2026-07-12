import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';

/// Speech (TTS) preferences (task 11.4).
///
/// [englishEnabled] gates the English read-aloud controls (on by default —
/// English works out of the box). [malayalamEnabled] turns on the Malayalam
/// (`ml-IN`) voice, which usually needs a guided install first.
class TtsSettings {
  final bool englishEnabled;
  final bool malayalamEnabled;

  const TtsSettings({
    this.englishEnabled = true,
    this.malayalamEnabled = false,
  });

  static const TtsSettings defaults = TtsSettings();

  // Preference keys (non-sensitive).
  static const String englishKey = 'tts.english_enabled';
  static const String malayalamKey = 'tts.malayalam_enabled';

  TtsSettings copyWith({bool? englishEnabled, bool? malayalamEnabled}) {
    return TtsSettings(
      englishEnabled: englishEnabled ?? this.englishEnabled,
      malayalamEnabled: malayalamEnabled ?? this.malayalamEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TtsSettings &&
      other.englishEnabled == englishEnabled &&
      other.malayalamEnabled == malayalamEnabled;

  @override
  int get hashCode => Object.hash(englishEnabled, malayalamEnabled);
}

/// Remembers the speech preferences (task 11.4), following the `ThemeController`
/// pattern: hydrate synchronously, update state first, persist fire-and-forget.
class TtsSettingsController extends Notifier<TtsSettings> {
  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  TtsSettings build() {
    final store = _store;
    return TtsSettings(
      englishEnabled: store.getBool(TtsSettings.englishKey) ??
          TtsSettings.defaults.englishEnabled,
      malayalamEnabled: store.getBool(TtsSettings.malayalamKey) ??
          TtsSettings.defaults.malayalamEnabled,
    );
  }

  void setEnglishEnabled(bool value) {
    state = state.copyWith(englishEnabled: value);
    _store.setBool(TtsSettings.englishKey, value);
  }

  void setMalayalamEnabled(bool value) {
    state = state.copyWith(malayalamEnabled: value);
    _store.setBool(TtsSettings.malayalamKey, value);
  }
}

final ttsSettingsProvider =
    NotifierProvider<TtsSettingsController, TtsSettings>(
  TtsSettingsController.new,
);
