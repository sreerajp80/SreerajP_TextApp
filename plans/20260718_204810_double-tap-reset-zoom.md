# Double-tap to reset zoom (font scale) to normal

**Status:** completed

## What the issue is

The pinch-to-zoom feature lets the user change the app-wide font scale by
pinching. But there is no quick way to put the zoom back to the normal size
(`fontScale = 1.0`). Right now the only way is to pinch back by hand, which is
hard to land exactly on 1.0.

We want a **double-tap** on the same area to reset the font scale to the default
(`1.0`). A double-tap uses a single finger, so it will not fight the two-finger
pinch logic that already runs in `PinchToZoomArea`.

## Files to change

- `lib/core/editor/pinch_to_zoom_area.dart` — add a double-tap handler that
  resets the font scale.

## The plan for the fix

1. In `_PinchToZoomAreaState`, add a small method `_resetZoom()` that calls
   `ref.read(themeControllerProvider.notifier).setFontScale(1.0)`. Guard it so
   it does nothing while a two-finger pinch is active (`_pointers.length >= 2`),
   so a stray tap during a pinch cannot reset mid-gesture.

2. In `build()`, wrap the existing `Listener`'s child tree with a
   `GestureDetector`:
   - `onDoubleTap: _resetZoom`
   - `behavior: HitTestBehavior.translucent` (same as the Listener, so the
     child's own taps/scrolls still work).

   The `GestureDetector` must sit **inside** the `Listener` (as its child) so the
   raw pointer tracking still sees every finger. A `GestureDetector` for a
   double-tap only claims the arena after a single-pointer double-tap is
   recognized; it will not interfere with the two-finger pinch, which is tracked
   by the arena-free `Listener`.

3. Keep the `ScrollConfiguration` / `AbsorbPointer` wrapping exactly as it is;
   the `GestureDetector` goes around that inner tree.

4. Update the class doc comment near the top to mention that a double-tap
   resets the zoom to normal.

## What will NOT change

- No change to `ThemeController` or `ThemeSettings` — `setFontScale(1.0)` is
  already the correct, persisted way to reset (it writes to the store).
- No new UI widgets, buttons, or settings entries.

## Testing / verification

- Manual: pinch to zoom in, then double-tap — text returns to normal size and
  stays after leaving/reopening the file (persisted).
- Confirm one-finger scroll and two-finger pinch still work after the change.
- Run `flutter analyze` on the changed file.
