# Closing a tab shows a blank grey screen

**Status:** completed

## What the user sees

Close a tab from the tab strip (the × button). The editor area turns into a plain
grey box. Nothing is shown — no tab strip, no document, and not the "No open
documents" empty state either. The bottom navigation still works.

Expected: after closing a tab the app should show the next open tab; if that was
the last tab, it should go back to Home.

## What is wrong

Two separate problems.

### 1. The grey box — a crash inside `build()`

A plain grey rectangle is what Flutter draws in a **release build** when a widget
throws while building, laying out, or painting (`ErrorWidget`). So closing a tab
throws an exception inside the editor screen.

The cause is in `lib/shell/tabs/tabs_workspace.dart`. `TabsWorkspace.build()` does
real work with side effects, right in the middle of building the widget tree:

- `retainOnly(openIds)` on all five session managers — this **disposes** the
  closed tab's document session, and with it the `re_editor` controllers
  (`code`, `scroll`, `find`) that the editor widget on screen is still using;
- `_releaseBackgroundSessions(...)` — disposes more sessions, again during build;
- `syncOpenTabs(openIds)` — changes another provider's state during build.

Disposing controllers that the currently mounted editor still points at, in the
same frame, is what blows up: the old `CodeEditor` element is reused (it has a
fixed key) and its render objects keep reading a controller that has just been
thrown away. A `build()` method must not have side effects; this one is full of
them.

### 2. The tab that gets picked after a close

`TabsController._removeTabs` picks `remaining.last` as the new active tab. That is
not "the next tab" — with three tabs open, closing the first jumps to the last
one. And when the last tab is closed the app stays on the (now empty) Editor
screen instead of going Home, which is what the user expects.

## The fix

**A. Take the side effects out of `build()`**
(`lib/shell/tabs/tabs_workspace.dart`)

- Turn `TabsWorkspace` into a `ConsumerStatefulWidget`.
- Move session clean-up (`retainOnly`, `_releaseBackgroundSessions`) and the
  ephemeral `syncOpenTabs` call out of `build()` into a `ref.listen` on
  `tabsControllerProvider` that runs the clean-up **after the frame**
  (`WidgetsBinding.instance.addPostFrameCallback`), so the closed tab's editor is
  already off the screen before its controllers are disposed.
- `build()` then only reads state and returns widgets.

**B. Pick the neighbour tab, and leave the Editor when nothing is left**

- `lib/shell/tabs/tabs_controller.dart` — in `_removeTabs`, when the active tab is
  the one being closed, activate the tab that took its place (the next one to the
  right), and fall back to the one on the left when the closed tab was last.
- `lib/shell/tabs/tabs_workspace.dart` (or `app_shell.dart`) — when the workspace
  becomes empty, switch `shellDestinationProvider` to `ShellDestination.home`.
  Done from the same post-frame callback, never during build.

**C. Keep the empty state**

`_NoOpenTabs` stays as it is. It is still shown if the user opens the Editor tab
with nothing open.

## Files to change

| File | Change |
|------|--------|
| `lib/shell/tabs/tabs_workspace.dart` | stateful widget; session clean-up + ephemeral sync moved to a post-frame callback; go Home when the last tab closes |
| `lib/shell/tabs/tabs_controller.dart` | `_removeTabs` picks the neighbouring tab as the new active one |
| `test/shell/close_tab_widget_test.dart` (new) | widget test: closing the active tab shows the next tab and throws nothing; closing the last tab leaves no error widget and sends the shell Home |
| `test/shell/tabs_controller_test.dart` (existing, if present) | cover the new "next tab" rule |

## How it will be checked

1. A new widget test that closes a tab and asserts `tester.takeException()` is
   null — this reproduces the grey box first, then proves it is gone.
2. `flutter test` (whole suite), `flutter analyze` (zero issues),
   `dart format lib test`.
3. Manual check on the device: close a middle tab, close the last tab.

## Note

If the widget test does **not** reproduce the crash, I will report that before
changing behaviour, and ask for the device log (`flutter logs` /
`adb logcat -s flutter`) to find the real exception. The `build()` side-effect
clean-up (part A) is worth doing either way, but I will not guess at a fix for a
crash I cannot see.
