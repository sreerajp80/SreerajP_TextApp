# Change log: received recent files now show after sync

Implements plan
[plans/20260712_114815_sync-recents-not-showing.md](../plans/20260712_114815_sync-recents-not-showing.md).

## Problem

After a receive, the sync summary said "Recent files — 1 added", but the Recent
files (Home) screen stayed blank ("No recent files") until the app was
restarted. The record was saved to the database; the Home screen's
`RecentsController` (a non-`autoDispose` `AsyncNotifierProvider`) kept its
cached list and was never told to reload.

## What changed

### `lib/sync/sync_provider.dart`
- Added an optional `onApplied` callback to `SyncController`
  (`void Function(SyncSummary summary)?`), set through the constructor. It stays
  null in tests that do not need it, so the controller remains testable without
  Riverpod.
- In `connectManual(...)`, after a receive successfully applies a payload and
  the phase becomes `ClientPhase.done`, the controller now calls
  `onApplied(summary)`. The call is wrapped in a guard so a listener error
  cannot turn a successful sync into a failure.
- Wired the callback in `syncControllerProvider` (which has `ref`) to reload the
  UI that reads the data a receive may have written:
  - invalidates `recentsControllerProvider` when the payload included the
    recents category, so the Home screen reloads and shows the added file;
  - invalidates `themeControllerProvider` and `tabsControllerProvider` when any
    allow-listed settings were applied, so synced display settings take effect
    without a restart.
- Added imports for `recents_controller.dart`, `theme_controller.dart`, and
  `tabs_controller.dart`.

### `test/sync/sync_provider_test.dart`
- Added a loopback test asserting `onApplied` fires exactly once after a
  successful receive, receives the same summary the UI shows, and that the
  summary reports the imported recent.
- Added a test asserting `onApplied` does not fire when the receive fails
  (wrong code).

## Verification

- `flutter test test/sync/sync_provider_test.dart` — all 4 tests pass.
- `flutter analyze lib/sync/sync_provider.dart test/sync/sync_provider_test.dart`
  — no issues.
- Manual two-device check (send a recent A → B, confirm it appears in B's Recent
  files immediately, marked "Unavailable" if B has no access to A's URI) still
  to be done before release, per the project testing rules.

## Notes / follow-up (separate bug, not fixed here)

While investigating, found that settings sync has a key-namespace mismatch: the
allow-list in `SyncConstants.syncableSettingKeys` uses bare keys (e.g.
`theme_mode`, `font_scale`), but the app stores those under an `appearance.`
prefix (e.g. `appearance.theme_mode`) — and tab/tts settings use `tabs.` /
`tts.` prefixes. So display-settings sync currently transfers nothing, which
matches the "Display settings — 0 applied · 0 kept" seen in the screenshot. The
settings-controller invalidation added here is correct and harmless, but it will
only have a visible effect once that key mapping is fixed. This should be handled
in its own plan.
