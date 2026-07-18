# Double-tap to reset zoom (font scale) to normal

Implements plan: `plans/20260718_204810_double-tap-reset-zoom.md`

## What changed

Added a **double-tap to reset zoom** gesture to `PinchToZoomArea`. A double-tap
anywhere on the pinch area now sets the app-wide font scale back to normal
(`1.0`).

### `lib/core/editor/pinch_to_zoom_area.dart`

1. Added `_resetZoom()`. It calls
   `ref.read(themeControllerProvider.notifier).setFontScale(1.0)`, which resets
   and persists the font scale. It is guarded to do nothing while a two-finger
   pinch is active (`_pointers.length >= 2`), so a stray tap during a pinch
   cannot reset mid-gesture.

2. Wrapped the `Listener`'s child tree with a `GestureDetector`
   (`onDoubleTap: _resetZoom`, `behavior: HitTestBehavior.translucent`). It sits
   **inside** the `Listener` so the raw pointer tracking still sees every finger.
   The `ScrollConfiguration` / `AbsorbPointer` wrapping is unchanged.

3. Updated the class doc comment to describe the double-tap reset.

## Why it is safe

- A double-tap is a single-finger gesture, so it does not compete with the
  two-finger pinch, which the arena-free `Listener` tracks directly.
- No changes to `ThemeController` or `ThemeSettings`; `setFontScale(1.0)` was
  already the correct, persisted reset path.

## Verification

- `flutter analyze lib/core/editor/pinch_to_zoom_area.dart` — no issues.
- Manual check recommended before release: pinch to zoom, double-tap to reset,
  and confirm one-finger scroll + two-finger pinch still work.
