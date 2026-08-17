# Closing a tab: no more side effects during build, and a sane next tab

Implements `plans/20260817_073356_close-tab-blank-screen.md`.

## What changed

### `lib/shell/tabs/tabs_workspace.dart`

`TabsWorkspace` is now a `ConsumerStatefulWidget`. Its `build()` used to do real
work with side effects:

- `retainOnly(...)` on all five session managers — this **disposes** a closed
  tab's document session, and with it the `re_editor` controllers the screen was
  still using;
- `_releaseBackgroundSessions(...)` — disposes more sessions;
- `syncOpenTabs(...)` — changes another provider's state.

All three moved into `_cleanUpAfterFrame()`, which runs from a post-frame
callback. A `ref.listen` on the tabs provider schedules it whenever the tab set
changes, and `initState` schedules one pass on the way in. `build()` now only
reads state and returns widgets.

The workspace also remembers when the tab set went from "some tabs" to "none".
In that case the same post-frame pass switches the shell back to
`ShellDestination.home`, so closing the last tab no longer leaves the user on an
empty Editor screen. Opening the Editor tab with nothing open still shows the
"No open documents" state — the jump to Home only happens right after a close.

### `lib/shell/tabs/tabs_controller.dart`

`_removeTabs` picked `remaining.last` as the new active tab, so closing the first
of three tabs jumped to the last one. It now uses a new `_neighbourOf` helper:
the next tab to the right, falling back to the one on the left when the closed
tab was the right-most. `closeOthers`' `preferActive` still wins, and closing a
background tab still leaves the active one alone.

### Tests

- `test/shell/close_tab_widget_test.dart` (new) — closing the active tab shows
  another document with no thrown exception; closing a tab activates its
  neighbour; closing the right-most tab falls back to the left; closing the last
  tab sends the shell to Home.
- `test/shell/tabs_controller_test.dart` — three new cases for the neighbour rule
  at controller level.

## Checks

- `flutter analyze` — no issues.
- `flutter test` — all 1169 tests pass.
- `dart format lib test` — applied.

## Open point

The blank grey screen was **not reproduced** by the new widget tests: they pass
both before and after the controller change, and no exception is thrown in a
debug test run. The build-time disposal fixed here is a real defect and the most
likely cause (a thrown build is painted as a plain grey box in a release build),
but it is not proven. If the grey screen still appears on the device, the next
step is a device log (`adb logcat -s flutter`) to find the actual exception
rather than guessing again.
