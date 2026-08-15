# Change Log: Fix Last Card Clipping in Help Section

**Plan reference:** plans/20260815_160800_fix_help_section_bottom_padding.md

## Summary of Changes
- Wrapped `ListView` in `SafeArea(top: false, ...)` with increased bottom padding (`32dp`) in `lib/shell/settings/settings_detail_screen.dart`. This ensures that cards and text across all settings detail pages (such as Help, Help topic detail pages, Appearance, Editor, Backup, etc.) are never occluded by the Android 3-button or gesture navigation bar.
- Wrapped `ListView` in `SafeArea(top: false, ...)` with `bottom: 24dp` padding in `lib/shell/settings/settings_screen.dart` so main settings menu cards also respect navigation bar insets.

## Files Modified
- `lib/shell/settings/settings_detail_screen.dart`
- `lib/shell/settings/settings_screen.dart`

## Verification
- `flutter analyze` completed with 0 issues.
- `flutter test` passed all 1144 tests.
