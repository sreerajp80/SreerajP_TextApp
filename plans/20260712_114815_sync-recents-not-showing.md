# Fix: received recent files do not show after sync

**Status:** completed

## The issue

When a device receives a sync, the summary screen correctly reports the added
records (for example, "Recent files — 1 added · 0 kept"). But when the user
opens the **Recent files** (Home) screen on the receiving device, it is blank
("No recent files"). The added file only appears after the app is restarted.

## Why it happens

- The receive flow **does** save the records. In
  [lib/sync/sync_provider.dart](../lib/sync/sync_provider.dart) the private
  `_apply()` method (lines 267–286) writes each new recent to the database via
  `recents.upsert(...)`. That is why the summary says "1 added".
- The Home screen reads its list from
  [RecentsController](../lib/shell/home/recents_controller.dart), which is an
  `AsyncNotifierProvider` (not `autoDispose`). Once the Home screen has built
  it, the controller keeps its list in memory.
- After a receive writes new rows straight to the DB, **nothing tells the
  controller to reload**. No code calls `refreshList()` or invalidates
  `recentsControllerProvider`. So the Home screen keeps showing its old (empty)
  list until the app process restarts and the controller is rebuilt.

Note: a received recent whose file URI came from the *other* device will show
as **"Unavailable"** on this device (the receiver has no permission for the
sender's `content://` URI). That is expected and is not part of this bug — the
Home screen already shows unavailable entries; it does not hide them.

## The plan for the fix

Make the sync controller tell the app to reload the affected data after a
successful receive, so the Home screen (and any settings screens) show fresh
data without a restart. Keep the sync controller testable (no Riverpod inside
it) by using an optional callback.

1. **`lib/sync/sync_provider.dart`**
   - Add an optional callback to `SyncController`, e.g.
     `final void Function(SyncSummary summary)? onApplied;`, set through the
     constructor (defaults to null so existing tests keep working).
   - In `connectManual(...)`, right after a successful apply sets
     `_clientPhase = ClientPhase.done`, call `onApplied?.call(summary)` with the
     summary that was just built.
   - In `syncControllerProvider` (which has access to `ref`), pass an
     `onApplied` callback that invalidates the UI providers whose data may have
     changed:
     - Always invalidate `recentsControllerProvider` when the recents category
       was part of the summary (or simply always — it is cheap and only reloads
       from the local DB).
     - When `summary.settings.applied > 0`, invalidate the settings controllers
       that read the syncable settings from the store so display settings take
       effect without a restart. This covers the "Display settings" row of the
       summary. (Favourites and bookmarks have no dedicated list screen today,
       so there is nothing extra to invalidate for them.)

2. **Imports**
   - Add the needed provider imports to `sync_provider.dart`
     (`recents_controller.dart`, and the settings controllers such as
     `theme_controller.dart`, `editor_settings_controller.dart`,
     `tts_settings.dart`, `over_limit_behavior.dart`) — only those that map to
     keys in `SyncConstants.syncableSettingKeys`.

## Files to be changed

- `lib/sync/sync_provider.dart` — add the `onApplied` callback, call it on a
  successful receive, and wire it in `syncControllerProvider` to invalidate the
  affected UI providers.
- `test/sync/sync_provider_test.dart` — add a test that the `onApplied`
  callback fires once after a successful receive (loopback, no device).

## Testing

- Unit: extend the existing loopback test in
  [test/sync/sync_provider_test.dart](../test/sync/sync_provider_test.dart) to
  assert the `onApplied` callback runs exactly once after a successful apply,
  and does not run on a wrong-code / failed sync.
- Manual (two devices, before release): send a recent from device A to
  device B and confirm the file now appears in device B's Recent files list
  immediately (marked "Unavailable" if B has no access to A's URI), with no app
  restart.

## Notes / open questions

- Scope choice: the smallest fix is to invalidate only
  `recentsControllerProvider` (the reported symptom). The plan also invalidates
  the settings controllers so applied display settings show without a restart,
  because that is the same class of bug and the summary screen advertises a
  "Display settings" result. If you prefer the minimal recents-only fix, say so
  and I will drop the settings-controller invalidation.
