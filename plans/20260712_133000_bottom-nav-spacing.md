# Reduce bottom navigation bar spacing

**Status:** completed

## Issue

The bottom navigation bar (Home / Editor / Settings) on phones takes more
vertical space than needed. The top and bottom padding around the icons and
labels looks large. This is because the Material 3 `NavigationBar` uses its
default height of 80 logical pixels, with generous built-in vertical padding.

## Files to change

- `lib/shell/app_shell.dart` — the `NavigationBar` in `_NarrowLayout.build`.

## Plan for the fix

- Set the `height` property on the `NavigationBar` to a smaller value (64)
  to reduce the top and bottom spacing while keeping the icon and label
  readable.
- Keep everything else the same (destinations, selected index, labels).
- The label still shows because the default
  `labelBehavior` is unchanged; 64px is enough for icon + label.

## Notes / risks

- 64px is the older Material bottom-bar height, still comfortable for touch
  and respects system font scaling because it is only a minimum-ish height;
  very large font scales may clip, so if that is a concern we can use a
  slightly larger value. Starting with 64.
- No test change needed; `test/shell/adaptive_nav_widget_test.dart` checks
  presence of destinations, not exact height.
