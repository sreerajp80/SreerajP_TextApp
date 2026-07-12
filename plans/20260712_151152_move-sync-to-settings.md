# Move sync out of the Recent files toolbar

**Status:** completed

## The issue

The Recent files (Home) screen has a **sync** icon in its top toolbar
(folder, sync, delete). The user wants sync reached from **Settings**, not
from this toolbar.

Sync is already fully available in **Settings → Sync**: that section has an
"Open sync" button that opens the same `SyncLandingScreen`. So the toolbar
sync icon is a duplicate entry point.

## The plan for the fix

Remove the sync `IconButton` from the Home screen toolbar. Keep the folder
(open file) and delete (clear all) actions as they are. No change to Settings,
because the sync entry point already exists there.

Steps:

1. In [lib/shell/home/home_screen.dart](../lib/shell/home/home_screen.dart):
   - Delete the sync `IconButton` (the one with `Icons.sync` /
     `l10n.homeSyncTooltip` that pushes `SyncLandingScreen`).
   - Remove the now-unused `import '../../sync/ui/sync_landing_screen.dart';`.
2. Leave the `homeSyncTooltip` localization string in place. It is harmless if
   unused and removing it would force a full l10n regeneration; no test depends
   on it.

## Files to be changed

- `lib/shell/home/home_screen.dart` — remove the sync toolbar button and its
  unused import.

## Testing

- Run `flutter analyze` to confirm no unused-import or other warnings.
- Run the home screen widget tests (`test/shell/home_screen_widget_test.dart`)
  and the settings tests — none reference the home sync button, so they should
  still pass.

## Notes

- No behavior change to sync itself; only the extra entry point is removed.
- Sync remains reachable via Settings → Sync → "Open sync".
