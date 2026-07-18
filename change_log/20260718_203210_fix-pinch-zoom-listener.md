# Change log — Fix Pinch-to-Zoom Using the PDF App's Method

Implements plan `plans/20260718_203210_fix-pinch-zoom-listener.md`.

## The problem

Pinch-to-zoom in the editor/viewer surfaces was unreliable. It often only
started when both fingers landed at nearly the same spot at the same time, and
failed when the fingers started far apart or when the user first scrolled with
one finger and then added a second finger.

### Root cause

`PinchToZoomArea` used a Flutter `GestureDetector` (`onScaleStart` /
`onScaleUpdate` / `onScaleEnd`), which relies on `ScaleGestureRecognizer`. That
recognizer competes in Flutter's gesture arena with the scrollable child (text
editor, CSV grid, list view). When the second finger arrives after a pan has
begun, the recognizer does not reliably re-fire as a scale, so the pinch is
dropped. This is the same bug the sibling PDF app fixed.

## What changed

`lib/core/editor/pinch_to_zoom_area.dart`:
- Removed the `GestureDetector` and its `onScale*` handlers.
- Now computes the zoom from raw pointer events in the existing `Listener`
  (which never joins the gesture arena, so it always sees both fingers). This is
  the same method the PDF app uses in its `PinchZoomWrapper`.
  - Track pointer positions in a `Map<int, Offset>` (was a `Set<int>`).
  - When the second finger lands, record the base font scale and the base
    **vertical** span between the two pointers (vertical-only pinch is kept, per
    `change_log/20260716_074040_vertical-pinch.md`), and stop any in-progress
    one-finger scroll via `jumpTo` (scroll-cancel behaviour kept).
  - On pointer move with two fingers down, set the font scale to
    `baseScale * (currentVerticalSpan / baseVerticalSpan)`, clamped to
    `ThemeSettings.minFontScale` / `maxFontScale`. A `baseSpan < 1.0` guard
    avoids divide-by-near-zero.
  - Clear pinch state when fewer than two pointers remain.
- Kept the `NotificationListener<ScrollNotification>` (tracks the active scroll
  position) and kept disabling scroll physics + `AbsorbPointer` while two
  pointers are down, so the child does not scroll during a pinch.
- Added an import of `theme_settings.dart` for the clamp bounds.

No test file changes were needed — the existing tests in
`test/shell/tabs/pinch_to_zoom_test.dart` drive pinch by moving two pointers,
which the new logic supports with the same vertical-span ratio math.

## Verification

- `flutter analyze lib/core/editor/pinch_to_zoom_area.dart` — No issues found.
- `flutter test test/shell/tabs/pinch_to_zoom_test.dart` — all 4 passed.
- `flutter test` — all 564 tests passed.
- Manual device/emulator verification (open txt/md/json/xml/csv and Degraded
  view; pinch with fingers far apart, and scroll-then-add-second-finger) is
  still recommended before release.
