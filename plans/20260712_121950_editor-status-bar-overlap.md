# Editor screen renders behind the top status bar

**Status:** completed

## The issue

On the **Editor** tab, the document workspace (tab strip, toolbar, and file
content) draws behind the phone's top status bar. In the screenshot the file
name and the toolbar icons sit under the clock and battery, so the top row is
partly hidden and hard to tap.

The cause is in the app shell layout:

- `HomeScreen` and `SettingsScreen` each build their **own `Scaffold` + `AppBar`**.
  A Material `AppBar` automatically adds top padding for the status bar, so those
  two screens look correct.
- `TabsWorkspace` (the Editor body) returns a **bare `Column`** with no `Scaffold`,
  no `AppBar`, and no `SafeArea`. Nothing insets it below the status bar, so its
  content starts at the very top of the screen and slides under the status bar.

The shell `Scaffold` in `app_shell.dart` puts the selected screen straight into
its `body`, and the `body` area extends up to the top of the screen. Only the
screen itself can add the top inset, and the Editor screen does not.

## The fix

Wrap the `TabsWorkspace` content in a `SafeArea` so the tab strip and toolbar
start below the status bar. This matches the top inset the other two screens
already get from their `AppBar`.

- Use `SafeArea` around both return branches of `TabsWorkspace.build`
  (the "no open tabs" empty state and the normal Column), or wrap the whole
  build result once.
- Keep the default `SafeArea` sides. In the narrow layout the shell `Scaffold`
  already consumes the bottom inset with its `NavigationBar`, so `SafeArea`
  adds no extra bottom padding there. In the wide layout it will also protect
  the content from the bottom system gesture area, which is correct.

The fix is done **only at the Editor (`TabsWorkspace`) level**, not at the shell
level. Adding a `SafeArea` around all three screens in `app_shell.dart` would
give `HomeScreen` and `SettingsScreen` a **double top inset** (SafeArea + their
own AppBar), pushing their headers down. So the shell is left unchanged.

## Files to change

- `lib/shell/tabs/tabs_workspace.dart` — wrap the `build` output in a `SafeArea`.

No other files need changes. Home, Settings, and onboarding already handle the
top inset themselves.

## Testing

- Static analysis (`flutter analyze`) stays clean.
- Manual check on device/emulator: open a file, go to the Editor tab, and confirm
  the tab strip and toolbar now sit below the status bar in both portrait and
  landscape, and that Home and Settings headers are unchanged.
