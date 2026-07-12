# Editor screen no longer renders behind the top status bar

Implements plan `plans/20260712_121950_editor-status-bar-overlap.md`.

## What was changed

- `lib/shell/tabs/tabs_workspace.dart` — wrapped the `TabsWorkspace.build`
  output in a `SafeArea`:
  - The empty state now returns `SafeArea(child: _NoOpenTabs())`.
  - The normal case now wraps the `Column` (tab strip, toolbar, and document
    body) in a `SafeArea`.

## Why

The Editor body had no `Scaffold`/`AppBar`, so nothing padded it below the top
status bar and its tab strip and toolbar drew behind the clock/battery area.
Home and Settings were unaffected because each has its own `AppBar`, which
already adds that inset. The fix was made only at the Editor level so Home and
Settings do not get a double top inset.

## Verification

- `dart format` applied to the changed file.
- `flutter analyze lib/shell/tabs/tabs_workspace.dart` — no issues.
- Manual on-device check of portrait/landscape still recommended before release.
