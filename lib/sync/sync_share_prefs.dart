import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/key_value_store.dart';
import 'sync_constants.dart';

/// Which record categories are **pre-checked** when the user starts a share
/// (task 11.5).
///
/// This is a convenience default only — the host screen still lets the user
/// change the selection before sending, and the receiver never has anything
/// overridden. No sensitive or identity data is involved (security-rules); these
/// are just the three record categories the app can sync.
class SyncSharePrefs {
  /// The categories that should start selected. Always a subset of
  /// [SyncConstants.allCategories].
  final Set<String> enabledCategories;

  const SyncSharePrefs({required this.enabledCategories});

  /// The default: every category pre-selected.
  static final SyncSharePrefs defaults =
      SyncSharePrefs(enabledCategories: {...SyncConstants.allCategories});

  /// Preference key for one category (`sync.share.<category>`).
  static String keyFor(String category) => 'sync.share.$category';

  bool isEnabled(String category) => enabledCategories.contains(category);

  @override
  bool operator ==(Object other) =>
      other is SyncSharePrefs &&
      other.enabledCategories.length == enabledCategories.length &&
      other.enabledCategories.containsAll(enabledCategories);

  @override
  int get hashCode =>
      Object.hashAllUnordered(enabledCategories);
}

/// Remembers the default share selection (task 11.5). Follows the settings
/// controller pattern: hydrate synchronously, update state first, persist
/// fire-and-forget.
class SyncSharePrefsController extends Notifier<SyncSharePrefs> {
  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  SyncSharePrefs build() {
    final enabled = <String>{};
    for (final category in SyncConstants.allCategories) {
      // Default each category to on when nothing is stored yet.
      final value = _store.getBool(SyncSharePrefs.keyFor(category)) ?? true;
      if (value) enabled.add(category);
    }
    return SyncSharePrefs(enabledCategories: enabled);
  }

  void setEnabled(String category, bool enabled) {
    if (!SyncConstants.allCategories.contains(category)) return;
    final next = {...state.enabledCategories};
    if (enabled) {
      next.add(category);
    } else {
      next.remove(category);
    }
    state = SyncSharePrefs(enabledCategories: next);
    _store.setBool(SyncSharePrefs.keyFor(category), enabled);
  }
}

final syncSharePrefsProvider =
    NotifierProvider<SyncSharePrefsController, SyncSharePrefs>(
  SyncSharePrefsController.new,
);
