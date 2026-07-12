import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/key_value_store.dart';

/// Tracks whether the first-run intro has been finished or skipped (task 2.4).
///
/// The flag is a non-sensitive bool in the settings store, read synchronously so
/// the app can decide on the first frame whether to show onboarding. Once set it
/// is never cleared by the app, so the intro is shown at most once.
class OnboardingController extends Notifier<bool> {
  static const String completeKey = 'onboarding.complete';

  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  /// State is `true` when onboarding is complete.
  @override
  bool build() => _store.getBool(completeKey) ?? false;

  /// Marks the intro finished (or skipped). Persists so it never shows again.
  void complete() {
    if (state) return;
    state = true;
    _store.setBool(completeKey, true);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
