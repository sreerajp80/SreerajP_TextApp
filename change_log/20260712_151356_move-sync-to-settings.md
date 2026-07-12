# Change log — Move sync out of the Recent files toolbar

Implements plan
[plans/20260712_151152_move-sync-to-settings.md](../plans/20260712_151152_move-sync-to-settings.md).

## What changed

Removed the **sync** icon button from the Recent files (Home) screen toolbar.
Sync is now reached only from **Settings → Sync → "Open sync"**, which already
opened the same `SyncLandingScreen`. The toolbar icon was a duplicate entry
point.

### Files changed

- `lib/shell/home/home_screen.dart`
  - Removed the `Icons.sync` `IconButton` (tooltip `homeSyncTooltip`) from the
    app bar actions.
  - Removed the now-unused `import '../../sync/ui/sync_landing_screen.dart';`.

The folder (open file) and delete (clear all) toolbar actions are unchanged.

### Not changed

- The `homeSyncTooltip` localization string was left in place. It is unused now
  but harmless, and removing it would force a full l10n regeneration.
- Settings was not touched — the sync entry point already exists there.

## Testing

- `flutter analyze lib/shell/home/home_screen.dart` — no issues.
- `flutter test test/shell/home_screen_widget_test.dart` — all 6 tests pass.
