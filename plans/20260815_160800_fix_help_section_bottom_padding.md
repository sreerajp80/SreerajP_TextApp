# Plan: Fix Last Card Clipping in Help Section

**Status:** Completed

## Problem
In the Help section (and other settings detail screens), the last card is partially covered by the Android system navigation bar because `SettingsDetailScreen` does not wrap its scrollable body in a `SafeArea` with bottom insets.

## Proposed Fix
1. Update `lib/shell/settings/settings_detail_screen.dart` to wrap its `ListView` body in `SafeArea(top: false, ...)` and set comfortable bottom padding.
2. Update `lib/shell/settings/settings_screen.dart` to wrap its `ListView` body in `SafeArea(top: false, ...)` to ensure the main settings cards list also has proper bottom insets.

## Files to Change
- `lib/shell/settings/settings_detail_screen.dart`
- `lib/shell/settings/settings_screen.dart`

## Verification
- `flutter analyze`
- `flutter test`
- `dart format lib test`
