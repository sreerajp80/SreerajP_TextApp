import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/ephemeral/ephemeral_models.dart';
import 'package:text_data/core/storage/key_value_store.dart';

/// Remembers what the self-destruct sheet should offer first (Feature 9).
///
/// These are **defaults for the sheet only**. Changing one never makes an open
/// tab ephemeral and never changes a tab that already is — a setting that
/// quietly started destroying documents would be a trap.
///
/// Follows the same shape as `EditorSettingsController`: hydrate synchronously
/// from the non-sensitive settings store, update memory first, then
/// fire-and-forget the write.
class EphemeralSettingsController extends Notifier<EphemeralOption> {
  static const String durationKey = 'ephemeral.default_duration';
  static const String customMinutesKey = 'ephemeral.custom_minutes';
  static const String burnAfterOutputKey = 'ephemeral.burn_after_output';

  /// Minutes offered when the user first picks a custom timer.
  static const int defaultCustomMinutes = 30;

  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  EphemeralOption build() {
    final store = _store;
    return EphemeralOption(
      duration: EphemeralDuration.fromPrefValue(
        store.getPlainString(durationKey),
      ),
      customMinutes: store.getInt(customMinutesKey) ?? defaultCustomMinutes,
      burnAfterOutput: store.getBool(burnAfterOutputKey) ?? false,
    );
  }

  void setDuration(EphemeralDuration value) {
    state = state.copyWith(duration: value);
    _store.setPlainString(durationKey, value.prefValue);
  }

  void setCustomMinutes(int minutes) {
    final value = minutes < 1 ? 1 : minutes;
    state = state.copyWith(customMinutes: value);
    _store.setInt(customMinutesKey, value);
  }

  void setBurnAfterOutput(bool value) {
    state = state.copyWith(burnAfterOutput: value);
    _store.setBool(burnAfterOutputKey, value);
  }
}

/// The pre-filled choice the self-destruct sheet opens with.
final ephemeralSettingsProvider =
    NotifierProvider<EphemeralSettingsController, EphemeralOption>(
      EphemeralSettingsController.new,
    );
