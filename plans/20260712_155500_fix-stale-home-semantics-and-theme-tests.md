# Fix two stale widget tests (home semantics + theme switch)

**Status:** completed

## What the issue is

Two tests fail after earlier, already-completed UI changes. Neither is a real
bug in the app — the tests just describe the old UI.

1. `test/a11y/semantics_test.dart` → "home icon actions expose semantics
   labels". It looks for a **sync** icon (`Icons.sync`) on the Home screen with
   the tooltip "Sync with another device". Sync was **moved into Settings**
   (plans `20260712_151152_move-sync-to-settings.md` and
   `20260712_151518_remove-home-sync-tooltip-string.md`), so the Home screen no
   longer has that icon. The test fails at `getSemantics(find.byIcon(Icons.sync))`
   because it finds no widget.

2. `test/shell/theme_switch_widget_test.dart` → "switching the theme changes the
   visible scheme". It taps the "Settings" tab, then taps "Dark" directly. But
   Settings is now a **menu of cards**; each card opens its own detail page
   (plan `20260712_122606_settings-cards-per-section.md`). So "Dark" is not on
   the first Settings page anymore — you must open the **Appearance** card first.
   The test fails with `Found 0 widgets with text "Dark"`.

## The plan for the fix

These are **test-only** changes. The app code is correct and stays as is.

### File 1: `test/a11y/semantics_test.dart`

Replace the sync-icon check with a check on the icon-only action that now leads
the Home app bar: the **Open a file** button. It is an `IconButton` (icon-only)
with the tooltip "Open a file", so it still proves the test's real intent — an
icon-only control announces its purpose to screen readers.

- Change the first `expect(...)` from `find.byIcon(Icons.sync)` /
  `isSemantics(tooltip: 'Sync with another device')` to
  `find.widgetWithIcon(IconButton, Icons.folder_open_outlined)` /
  `isSemantics(tooltip: 'Open a file')`.
  (Use `widgetWithIcon(IconButton, …)` — not `byIcon` — because the empty-state
  body also draws `folder_open_outlined` as a decorative icon and inside a
  `FilledButton.icon`, so `byIcon` would match more than one widget.)
- Update the code comment above it to say "open-file" instead of "sync".
- Keep the second assertion (`find.bySemanticsLabel('Open a file')` findsWidgets)
  as is — the empty-state button still carries that visible label.

### File 2: `test/shell/theme_switch_widget_test.dart`

Add one navigation step: after tapping "Settings", tap the **Appearance** card,
then tap "Dark".

- After `await tester.tap(find.text('Settings'));` + `pumpAndSettle()`, add:
  `await tester.tap(find.text('Appearance'));` + `await tester.pumpAndSettle();`
  before the existing `await tester.tap(find.text('Dark'));`.

## Files to be changed

- `test/a11y/semantics_test.dart`
- `test/shell/theme_switch_widget_test.dart`

## How it will be verified

Run `flutter test` and confirm all tests pass (the two failing tests go green,
nothing else breaks).
