# Change log — Reduce bottom navigation bar spacing

Implements plan `plans/20260712_133000_bottom-nav-spacing.md`.

## What changed

- `lib/shell/app_shell.dart`: added `height: 64` to the `NavigationBar` in
  `_NarrowLayout.build`. Before, the bar used the Material 3 default height of
  80 logical pixels, which left large top and bottom spacing around the icons
  and labels. Setting the height to 64 tightens that spacing while keeping the
  icons and labels readable and touch-friendly.

## What did not change

- Destinations (Home, Editor, Settings), selected index handling, labels, and
  the editor tab badge are unchanged.
- No test changes; `test/shell/adaptive_nav_widget_test.dart` checks the
  presence of destinations, not the bar height.
