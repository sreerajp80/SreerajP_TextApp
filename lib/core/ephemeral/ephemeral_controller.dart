import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/audit/audit_providers.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/ephemeral/ephemeral_models.dart';
import 'package:text_data/core/ephemeral/ephemeral_policy.dart';
import 'package:text_data/core/ephemeral/ephemeral_wiper.dart';
import 'package:text_data/core/index/index_providers.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/storage_providers.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';

/// Immutable snapshot of the ephemeral marks (Feature 9).
class EphemeralState {
  /// Marks by tab id.
  final Map<String, EphemeralMark> marks;

  /// The clock reading of the last tick. Countdown badges read this instead of
  /// each running their own timer.
  final int nowMillis;

  const EphemeralState({this.marks = const {}, this.nowMillis = 0});

  bool get isEmpty => marks.isEmpty;

  EphemeralMark? operator [](String tabId) => marks[tabId];

  EphemeralState copyWith({Map<String, EphemeralMark>? marks, int? nowMillis}) {
    return EphemeralState(
      marks: marks ?? this.marks,
      nowMillis: nowMillis ?? this.nowMillis,
    );
  }
}

/// Holds which open tabs are ephemeral and burns them when they are due
/// (Feature 9).
///
/// The marks live **only in memory** and are never written to disk. A mark that
/// survived a restart would itself be a record of the document the user asked
/// the app to forget.
///
/// One shared 1-second ticker drives every countdown badge and every expiry
/// check. It runs only while a timed mark exists, so an app with no ephemeral
/// tabs has no timer at all.
class EphemeralController extends Notifier<EphemeralState> {
  Timer? _ticker;

  /// Tabs whose burn is already running, so a burn that closes a tab (which in
  /// turn re-runs the open-tab sweep) cannot start a second burn of the same
  /// document.
  final Set<String> _burning = {};

  /// Wall clock, injectable for tests.
  int Function() _now = _wallClockMillis;

  static int _wallClockMillis() => DateTime.now().millisecondsSinceEpoch;

  /// How often the countdown ticks. One second: fine enough for the `m:ss`
  /// badge, cheap enough to leave running while a tab is ephemeral.
  static const Duration tickInterval = Duration(seconds: 1);

  KeyValueStore get _store => ref.read(keyValueStoreSyncProvider);

  @override
  EphemeralState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });
    return EphemeralState(nowMillis: _now());
  }

  /// Replaces the wall clock. Tests only — production never calls this.
  @visibleForTesting
  void setClock(int Function() now) {
    _now = now;
    state = state.copyWith(nowMillis: _now());
  }

  // --- queries ---------------------------------------------------------------

  bool isEphemeral(String tabId) => state.marks.containsKey(tabId);

  EphemeralMark? markFor(String tabId) => state.marks[tabId];

  Set<String> get ephemeralTabIds => state.marks.keys.toSet();

  /// Time left on [tabId], or null when it has no timer (or is not ephemeral).
  Duration? remainingFor(String tabId) {
    final mark = state.marks[tabId];
    if (mark == null) return null;
    return EphemeralPolicy.remaining(mark, state.nowMillis);
  }

  // --- marking ---------------------------------------------------------------

  /// Marks [tab] ephemeral with [option]. A no-op option (no timer and no
  /// burn-after-output) is ignored — that combination would promise the user
  /// something the app would never act on.
  void mark(DocumentTab tab, EphemeralOption option) {
    if (option.isNoOp) return;
    final marks = Map<String, EphemeralMark>.of(state.marks);
    marks[tab.id] = EphemeralMark(
      tabId: tab.id,
      fingerprint: tab.fingerprint,
      displayName: tab.displayName,
      expiresAtMillis: EphemeralPolicy.expiryFor(option, _now()),
      burnAfterOutput: option.burnAfterOutput,
    );
    state = state.copyWith(marks: marks, nowMillis: _now());
    _syncTicker();
  }

  /// Drops the ephemeral mark on [tabId] without burning anything.
  ///
  /// This does **not** put back the recents entry or the search-index rows that
  /// were skipped while the tab was ephemeral. Re-opening or re-saving the file
  /// records it again in the normal way.
  void cancel(String tabId) {
    if (!state.marks.containsKey(tabId)) return;
    final marks = Map<String, EphemeralMark>.of(state.marks)..remove(tabId);
    state = state.copyWith(marks: marks);
    _syncTicker();
  }

  // --- burning ---------------------------------------------------------------

  /// Burns [tabId] now: wipes every app-owned trace of the document, then
  /// force-closes its tab.
  ///
  /// Returns the names of any wipe steps that failed, so the caller can warn the
  /// user that the burn was not complete. An empty list means everything went.
  Future<List<String>> burn(String tabId) async {
    final mark = state.marks[tabId];
    if (mark == null || _burning.contains(tabId)) return const [];
    _burning.add(tabId);
    try {
      final failures = await _wiper().wipe(mark.fingerprint);
      // Drop the mark before closing, so the open-tab sweep the close triggers
      // sees nothing left to do for this tab.
      final marks = Map<String, EphemeralMark>.of(state.marks)..remove(tabId);
      state = state.copyWith(marks: marks);
      _syncTicker();
      ref.read(tabsControllerProvider.notifier).burnTab(tabId);
      return failures;
    } finally {
      _burning.remove(tabId);
    }
  }

  /// Burns every ephemeral tab (the Settings "burn all now" action, and the
  /// natural thing to do when the user wants a clean workspace immediately).
  Future<void> burnAll() async {
    for (final tabId in state.marks.keys.toList(growable: false)) {
      await burn(tabId);
    }
  }

  /// Called after a **successful** export, share, or print of [tabId]. Burns the
  /// tab when it was marked "burn after export". A cancelled or failed output
  /// never reaches here, so a failed share cannot destroy the document.
  Future<void> notifyOutputCompleted(String tabId) async {
    final mark = state.marks[tabId];
    if (mark == null || !mark.burnAfterOutput) return;
    await burn(tabId);
  }

  /// Keeps the marks in step with the open tabs.
  ///
  /// A tab that left the workspace by any other route — the × button, "close
  /// all", the tab cap closing the least recently used one — still has to be
  /// burned: the user asked for this document to leave no trace, and how the tab
  /// closed does not change that.
  /// Returns a future that completes when the wipes are done. Callers in the
  /// widget tree ignore it (a build must not await); tests await it so they do
  /// not have to guess how long disk work takes.
  Future<void> syncOpenTabs(Set<String> openTabIds) async {
    final orphans = state.marks.keys
        .where((id) => !openTabIds.contains(id) && !_burning.contains(id))
        .toList(growable: false);
    if (orphans.isEmpty) return;
    for (final tabId in orphans) {
      await _burnClosed(tabId);
    }
  }

  /// Wipes the traces of a tab that is already gone from the workspace. Same as
  /// [burn] without the close step.
  Future<void> _burnClosed(String tabId) async {
    final mark = state.marks[tabId];
    if (mark == null || _burning.contains(tabId)) return;
    _burning.add(tabId);
    try {
      final marks = Map<String, EphemeralMark>.of(state.marks)..remove(tabId);
      state = state.copyWith(marks: marks);
      _syncTicker();
      await _wiper().wipe(mark.fingerprint);
    } finally {
      _burning.remove(tabId);
    }
  }

  // --- the ticker ------------------------------------------------------------

  /// Runs one countdown step: publishes the new clock reading (so badges
  /// redraw) and burns anything that is due. Exposed so tests drive it directly
  /// instead of waiting on real time.
  @visibleForTesting
  Future<void> tick() async {
    final now = _now();
    state = state.copyWith(nowMillis: now);
    final due = EphemeralPolicy.expired(state.marks.values, now);
    for (final mark in due) {
      await burn(mark.tabId);
    }
  }

  /// Starts the ticker when at least one mark has a timer, stops it otherwise.
  void _syncTicker() {
    final needsTicker = state.marks.values.any((m) => m.hasTimer);
    if (needsTicker && _ticker == null) {
      _ticker = Timer.periodic(tickInterval, (_) => unawaited(tick()));
    } else if (!needsTicker && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  EphemeralWiper _wiper() => EphemeralWiper(
    draftStore: ref.read(draftStoreProvider.future),
    recents: ref.read(recentsRepositoryProvider.future),
    favorites: ref.read(favoritesRepositoryProvider.future),
    bookmarks: ref.read(bookmarksRepositoryProvider.future),
    searchIndex: ref.read(searchIndexServiceProvider.future),
    store: _store,
    auditService: ref.read(auditServiceProvider.future),
  );
}

final ephemeralControllerProvider =
    NotifierProvider<EphemeralController, EphemeralState>(
      EphemeralController.new,
    );
