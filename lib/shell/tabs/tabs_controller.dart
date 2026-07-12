import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/editor_settings_controller.dart';
import '../../core/storage/device_memory.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/saf_service.dart';
import 'document_tab.dart';
import 'over_limit_behavior.dart';
import 'tabs_persistence.dart';

/// Result of trying to open a file into a tab.
enum OpenOutcome {
  /// The file is now open (a tab was added, possibly after closing an LRU tab).
  opened,

  /// The cap is reached and the app cannot make room on its own — either the
  /// behavior is "ask", or every other tab has unsaved edits and must not be
  /// closed silently. The UI must ask the user to close something first.
  cappedNeedsChoice,
}

/// Immutable snapshot of the open workspace.
class TabsState {
  final List<DocumentTab> tabs;
  final String? activeId;
  final int cap;
  final OverLimitBehavior overLimitBehavior;

  const TabsState({
    this.tabs = const [],
    this.activeId,
    this.cap = _defaultCap,
    this.overLimitBehavior = OverLimitBehavior.closeLeastRecentlyUsed,
  });

  /// A safe cap used before the device-memory value has resolved.
  static const int _defaultCap = 5;

  DocumentTab? get activeTab {
    for (final tab in tabs) {
      if (tab.id == activeId) return tab;
    }
    return null;
  }

  int get activeIndex => tabs.indexWhere((t) => t.id == activeId);

  bool get isEmpty => tabs.isEmpty;

  TabsState copyWith({
    List<DocumentTab>? tabs,
    Object? activeId = _noChange,
    int? cap,
    OverLimitBehavior? overLimitBehavior,
  }) {
    return TabsState(
      tabs: tabs ?? this.tabs,
      activeId: identical(activeId, _noChange)
          ? this.activeId
          : activeId as String?,
      cap: cap ?? this.cap,
      overLimitBehavior: overLimitBehavior ?? this.overLimitBehavior,
    );
  }
}

const Object _noChange = Object();

/// Holds the open document tabs and enforces the workspace rules (tasks
/// 2.5–2.8): independent per-tab state, a memory-aware cap with over-limit
/// handling, and never closing a tab with unsaved edits silently.
class TabsController extends Notifier<TabsState> {
  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);
  SafService get _saf => ref.read(safServiceProvider);
  DeviceMemory get _memory => ref.read(deviceMemoryProvider);
  TabsPersistence get _persistence => TabsPersistence(_store, _saf);

  // Monotonic tick used for tab ids and last-active ordering, so recency is
  // deterministic and independent of the wall clock (helps tests too).
  int _tick = 0;
  int _nextTick() => ++_tick;

  // Settings keys for the cap and over-limit rule.
  static const String capModeKey = 'tabs.cap_mode'; // 'auto' | 'fixed'
  static const String fixedCapKey = 'tabs.fixed_cap';
  static const String overLimitKey = 'tabs.over_limit';

  @override
  TabsState build() {
    return TabsState(
      overLimitBehavior: OverLimitBehavior.fromPrefValue(
        _store.getPlainString(overLimitKey),
      ),
    );
  }

  /// Computes and applies the active cap from settings: a fixed value if set,
  /// otherwise the automatic value from device RAM (Phase 1.6). Call once at
  /// startup.
  Future<void> resolveCap() async {
    final mode = _store.getPlainString(capModeKey) ?? 'auto';
    int cap;
    if (mode == 'fixed') {
      cap = _store.getInt(fixedCapKey) ?? TabsState._defaultCap;
    } else {
      cap = await _memory.autoTabCapForDevice();
    }
    if (cap < 1) cap = 1;
    applyCap(cap);
  }

  /// Sets the cap directly (also used by Settings and tests). Lowering it does
  /// not force-close tabs here; the over-limit rule only runs on the next open.
  void applyCap(int cap) {
    state = state.copyWith(cap: cap < 1 ? 1 : cap);
  }

  void setOverLimitBehavior(OverLimitBehavior behavior) {
    state = state.copyWith(overLimitBehavior: behavior);
    _store.setPlainString(overLimitKey, behavior.prefValue);
  }

  /// Whether the cap follows device RAM (`'auto'`) or a fixed number
  /// (`'fixed'`). Read by the Settings UI (task 11.3).
  String get capMode => _store.getPlainString(capModeKey) ?? 'auto';

  /// The stored fixed cap, if one was set.
  int? get fixedCap => _store.getInt(fixedCapKey);

  /// Switches the cap back to the automatic, RAM-based value (task 11.3).
  Future<void> setCapModeAuto() async {
    await _store.setPlainString(capModeKey, 'auto');
    await resolveCap();
  }

  /// Fixes the cap to [cap] tabs (task 11.3). Persists the choice and applies it
  /// live. Lowering it does not force-close tabs here; the over-limit rule runs
  /// on the next open.
  Future<void> setFixedCap(int cap) async {
    final value = cap < 1 ? 1 : cap;
    await _store.setPlainString(capModeKey, 'fixed');
    await _store.setInt(fixedCapKey, value);
    applyCap(value);
  }

  /// Whether previously open tabs are restored on the next launch (task 2.8 /
  /// 11.3).
  bool get restoreOnRelaunch => _persistence.restoreEnabled;

  /// Turns tab restore on relaunch on or off (task 11.3).
  Future<void> setRestoreOnRelaunch(bool enabled) =>
      _persistence.setRestoreEnabled(enabled);

  /// Opens [file] (already fingerprinted) as a new active tab, honoring the cap.
  ///
  /// Returns [OpenOutcome.opened] on success, or [OpenOutcome.cappedNeedsChoice]
  /// when the app must ask the user to close a tab first (see [OpenOutcome]).
  OpenOutcome openFile(
    SafFile file,
    String fingerprint, {
    TabViewMode initialViewMode = TabViewMode.view,
  }) {
    final tabs = List<DocumentTab>.of(state.tabs);

    // Already open? Just focus it.
    final existing = tabs.indexWhere((t) => t.fingerprint == fingerprint);
    if (existing >= 0) {
      setActive(tabs[existing].id);
      return OpenOutcome.opened;
    }

    if (tabs.length >= state.cap) {
      if (state.overLimitBehavior == OverLimitBehavior.ask) {
        return OpenOutcome.cappedNeedsChoice;
      }
      final victim = pickLruClosable(tabs, state.cap);
      if (victim == null) {
        // Everything is unsaved — do not close anything silently.
        return OpenOutcome.cappedNeedsChoice;
      }
      tabs.removeWhere((t) => t.id == victim.id);
    }

    final tick = _nextTick();
    final tab = DocumentTab(
      id: '$fingerprint#$tick',
      fingerprint: fingerprint,
      uri: file.uri,
      displayName: file.displayName,
      mimeType: file.mimeType,
      size: file.size,
      // Honor the "open files read-only by default" editor setting (task 11.2).
      isReadOnly: ref.read(editorSettingsProvider).openReadOnlyByDefault,
      viewMode: initialViewMode,
      lastActiveAt: tick,
    );
    tabs.add(tab);
    state = state.copyWith(tabs: tabs, activeId: tab.id);
    _save();
    return OpenOutcome.opened;
  }

  /// Makes [id] the active tab and bumps its recency.
  void setActive(String id) {
    final tabs = state.tabs
        .map((t) => t.id == id ? t.copyWith(lastActiveAt: _nextTick()) : t)
        .toList(growable: false);
    state = state.copyWith(tabs: tabs, activeId: id);
  }

  /// Moves to the next tab (wraps around). No-op with fewer than two tabs.
  void next() => _step(1);

  /// Moves to the previous tab (wraps around). No-op with fewer than two tabs.
  void prev() => _step(-1);

  void _step(int delta) {
    if (state.tabs.length < 2) return;
    final i = state.activeIndex;
    if (i < 0) return;
    final j = (i + delta) % state.tabs.length;
    final wrapped = j < 0 ? j + state.tabs.length : j;
    setActive(state.tabs[wrapped].id);
  }

  /// Marks a tab dirty/clean (Phase 3 editor will drive this; exposed now so the
  /// close guards can be exercised).
  void setDirty(String id, bool dirty) {
    final tabs = state.tabs
        .map((t) => t.id == id ? t.copyWith(isDirty: dirty) : t)
        .toList(growable: false);
    state = state.copyWith(tabs: tabs);
  }

  /// Turns the per-file read-only lock on or off (task 3.8). A locked tab shows
  /// a clear "locked" state and its editor rejects edits until the user unlocks
  /// (architecture.md §6).
  void setReadOnly(String id, bool readOnly) {
    final tabs = state.tabs
        .map((t) => t.id == id ? t.copyWith(isReadOnly: readOnly) : t)
        .toList(growable: false);
    state = state.copyWith(tabs: tabs);
  }

  /// Flips the read-only lock on [id].
  void toggleReadOnly(String id) {
    for (final t in state.tabs) {
      if (t.id == id) {
        setReadOnly(id, !t.isReadOnly);
        return;
      }
    }
  }

  /// Closes one tab. Refuses to close a tab with unsaved edits unless [force] is
  /// set — the UI must prompt Save / Save-as-copy / Discard first (CLAUDE.md
  /// §3.6). Returns true if the tab was closed.
  bool closeTab(String id, {bool force = false}) {
    DocumentTab? tab;
    for (final t in state.tabs) {
      if (t.id == id) {
        tab = t;
        break;
      }
    }
    if (tab == null) return false;
    if (tab.isDirty && !force) return false;
    _removeTabs({id});
    return true;
  }

  /// Closes every other **saved** tab. Unsaved tabs are kept (never closed
  /// silently). Returns the ids left unclosed because they were dirty.
  List<String> closeOthers(String keepId, {bool force = false}) {
    final toClose = <String>{};
    final blocked = <String>[];
    for (final t in state.tabs) {
      if (t.id == keepId) continue;
      if (t.isDirty && !force) {
        blocked.add(t.id);
      } else {
        toClose.add(t.id);
      }
    }
    _removeTabs(toClose, preferActive: keepId);
    return blocked;
  }

  /// Closes every **saved** tab. Returns the ids left unclosed because they were
  /// dirty.
  List<String> closeAll({bool force = false}) {
    final toClose = <String>{};
    final blocked = <String>[];
    for (final t in state.tabs) {
      if (t.isDirty && !force) {
        blocked.add(t.id);
      } else {
        toClose.add(t.id);
      }
    }
    _removeTabs(toClose);
    return blocked;
  }

  void _removeTabs(Set<String> ids, {String? preferActive}) {
    if (ids.isEmpty) return;
    final remaining = state.tabs
        .where((t) => !ids.contains(t.id))
        .toList(growable: false);

    String? newActive = state.activeId;
    if (newActive == null || ids.contains(newActive)) {
      if (preferActive != null && remaining.any((t) => t.id == preferActive)) {
        newActive = preferActive;
      } else {
        newActive = remaining.isEmpty ? null : remaining.last.id;
      }
    }
    state = state.copyWith(tabs: remaining, activeId: newActive);
    _save();
  }

  /// Restores the saved tab set (task 2.8). Skips URIs that are no longer
  /// accessible and returns how many were skipped so the shell can show a
  /// non-blocking notice.
  Future<int> restore() async {
    final result = await _persistence.restore();
    if (result.tabs.isEmpty) return result.skippedCount;

    // Give restored tabs increasing recency in stored order.
    final restored = <DocumentTab>[];
    for (final t in result.tabs) {
      restored.add(t.copyWith(lastActiveAt: _nextTick()));
    }
    state = state.copyWith(tabs: restored, activeId: restored.last.id);
    return result.skippedCount;
  }

  void _save() {
    // Fire-and-forget; persistence failures must never break the workspace.
    _persistence.save(state.tabs);
  }
}

final tabsControllerProvider = NotifierProvider<TabsController, TabsState>(
  TabsController.new,
);
