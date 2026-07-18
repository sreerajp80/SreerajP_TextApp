# Plan — Fix Pinch-to-Zoom Using the PDF App's Method

**Status:** completed

## The issue

Pinch-to-zoom in the editor/viewer surfaces is unreliable. It behaves the same
way the PDF app's bug did: the zoom often only starts when both fingers land at
almost the same spot at the same time, and it fails when the fingers start far
apart or when the user first scrolls with one finger and then adds a second
finger.

### Root cause

`lib/core/editor/pinch_to_zoom_area.dart` uses a Flutter `GestureDetector`
(`onScaleStart` / `onScaleUpdate` / `onScaleEnd`). Under the hood this uses
`ScaleGestureRecognizer`, which competes in Flutter's "gesture arena" with the
scrollable child (text editor, CSV grid, list view). When the second finger
arrives after a pan has begun, the recognizer does not reliably re-fire as a
scale, so the pinch is dropped.

This is exactly the problem the PDF app hit and fixed. The PDF app stopped using
the gesture recognizer for pinch and instead used a raw `Listener` that watches
the pointer positions directly and computes the zoom itself. A `Listener` never
joins the gesture arena, so it always sees both fingers and never loses the
gesture to the scrollable child.

## The method (copied from the PDF app)

See `L:\Android\SreerajP_PDFApp\lib\features\viewer\presentation\widgets\pinch_zoom_wrapper.dart`.
Its approach:
- A transparent `Listener` tracks each active pointer's position by id.
- When two pointers are down, record the starting "span" (distance between the
  two fingers) and the starting zoom value.
- On every pointer move, compute `newZoom = baseZoom * (currentSpan / startSpan)`,
  clamp it, and apply it directly.
- On pointer up/cancel, clear the pinch state.

Because the `Listener` does not claim the pointers, the child's one-finger
scrolling keeps working.

## How this maps to the Text app

The Text app zooms the **app-wide font scale** (via `themeControllerProvider`),
not a matrix. We keep that. We also keep the existing **vertical-only** design
decision (see `change_log/20260716_074040_vertical-pinch.md`): only vertical
finger separation should zoom, horizontal separation is ignored. So instead of
the full Euclidean distance, the "span" we track is the **vertical distance**
between the two pointers (`|y1 - y2|`).

We also keep the existing **scroll-cancel** behaviour: when the second finger
lands, jump the active child scroll position to its current offset so an
in-progress one-finger scroll stops cleanly.

### New logic in `_PinchToZoomAreaState`

- Track `Map<int, Offset> _pointers` (position by pointer id), replacing the
  current `Set<int>`.
- On second pointer down: record `_baseVerticalSpan` (vertical distance of the
  two pointers) and `_baseScale` (current `fontScale`), and do the existing
  scroll-cancel `jumpTo`.
- On pointer move (while two pointers are down): compute
  `newScale = _baseScale * (currentVerticalSpan / _baseVerticalSpan)`, clamp to
  the theme's min/max font scale, and call
  `themeControllerProvider.notifier.setFontScale(newScale)`.
- On pointer up/cancel dropping below two pointers: clear the pinch state.
- Remove the `GestureDetector` and its `onScale*` handlers entirely.
- Keep the `NotificationListener<ScrollNotification>` (tracks active scroll
  position) and keep disabling scroll physics / `AbsorbPointer` while two
  pointers are down so the child does not scroll during a pinch.

Guard against divide-by-near-zero: if `_baseVerticalSpan` is below a small
threshold (e.g. 1.0 px), skip the update (mirrors the PDF wrapper's
`_initialSpan < 1.0` guard).

## Files to change

- `lib/core/editor/pinch_to_zoom_area.dart` — replace the `GestureDetector`
  scale handling with raw `Listener` span-based zoom, as described above.
- `test/shell/tabs/pinch_to_zoom_test.dart` — the existing tests drive pinch by
  moving two pointers, which the new logic still supports. Review and adjust:
  - The "scales the font size" and "ignores horizontal / accepts vertical" tests
    should still pass (the math is the same vertical-span ratio).
  - The "updates ScrollConfiguration physics ..." and "cancels ongoing scroll
    drag ..." tests should still pass (that behaviour is unchanged).
  - Update only if a test asserts on `GestureDetector` internals (none appear
    to). Add no behavioural change beyond reliability.

## Testing / verification

- `flutter analyze` — no new static errors.
- `flutter test test/shell/tabs/pinch_to_zoom_test.dart` — passes.
- `flutter test` — full suite passes.
- Manual (device/emulator): open txt, md, json, xml, csv and Degraded view;
  verify pinch zoom works when fingers start far apart, and when starting a
  one-finger scroll then adding a second finger.

## Change log

After implementation, write `change_log/<timestamp>_fix-pinch-zoom-listener.md`
referencing this plan.
