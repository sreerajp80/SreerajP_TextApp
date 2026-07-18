import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';
import '../theme/theme_settings.dart';

/// A widget that wraps any file viewer/editor surface and intercepts pinch/scale
/// gestures to dynamically change the app-wide font size scale (CLAUDE.md §3).
///
/// ## Why a raw [Listener] instead of a [GestureDetector]
///
/// Flutter's [GestureDetector] uses a [ScaleGestureRecognizer], which competes
/// in the gesture arena with the scrollable child (text editor, CSV grid, list
/// view). When the second finger arrives after a one-finger scroll has already
/// begun — or when the two fingers start far apart — the recognizer does not
/// reliably re-fire as a scale, so the pinch is dropped.
///
/// Instead we track raw pointer events with a [Listener]. A [Listener] never
/// joins the gesture arena, so it always sees both fingers and computes the
/// zoom itself: `newScale = baseScale * (currentSpan / startSpan)`. The child's
/// one-finger scrolling keeps working because the [Listener] never claims the
/// pointers. (This mirrors the method used in the sibling PDF app.)
///
/// The [span] we track is the **vertical** distance between the two pointers,
/// so only vertical pinches zoom; horizontal separation is ignored (a
/// deliberate design choice — see the vertical-pinch change log).
///
/// A **double-tap** resets the font scale back to normal (`1.0`). A double-tap
/// is a single-finger gesture, so it never fights the two-finger pinch logic.
class PinchToZoomArea extends ConsumerStatefulWidget {
  final Widget child;

  const PinchToZoomArea({super.key, required this.child});

  @override
  ConsumerState<PinchToZoomArea> createState() => _PinchToZoomAreaState();
}

class _PinchToZoomAreaState extends ConsumerState<PinchToZoomArea> {
  /// Active pointer positions keyed by pointer id (widget-local coordinates).
  final Map<int, Offset> _pointers = {};

  /// The font scale when the pinch began.
  double? _baseScale;

  /// The vertical distance between the two pointers when the pinch began.
  double? _baseVerticalSpan;

  /// The most recently seen active child scroll position, so we can stop an
  /// in-progress one-finger scroll the moment the second finger lands.
  ScrollPosition? _activePosition;

  /// The two pointer ids currently tracked (first two by insertion order).
  List<int> get _twoPointers {
    final keys = _pointers.keys.toList();
    return keys.length >= 2 ? keys.sublist(0, 2) : keys;
  }

  /// Vertical distance between the two tracked pointers.
  double _currentVerticalSpan() {
    final ids = _twoPointers;
    return (_pointers[ids[0]]!.dy - _pointers[ids[1]]!.dy).abs();
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _pointers[event.pointer] = event.localPosition;
      if (_pointers.length == 2) {
        // Stop any in-progress one-finger scroll cleanly at its current
        // offset, then begin the pinch.
        try {
          if (_activePosition != null && _activePosition!.hasPixels) {
            _activePosition!.jumpTo(_activePosition!.pixels);
          }
        } catch (_) {}
        _startPinch();
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) {
      return;
    }
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2 && _baseVerticalSpan != null) {
      _updatePinch();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _pointers.remove(event.pointer);
      if (_pointers.length < 2) {
        _endPinch();
      }
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _pointers.remove(event.pointer);
      if (_pointers.length < 2) {
        _endPinch();
      }
    });
  }

  void _startPinch() {
    _baseVerticalSpan = _currentVerticalSpan();
    _baseScale = ref.read(themeControllerProvider).fontScale;
  }

  void _updatePinch() {
    final baseScale = _baseScale;
    final baseSpan = _baseVerticalSpan;
    if (baseScale == null || baseSpan == null || baseSpan < 1.0) {
      return; // avoid divide-by-near-zero
    }
    final newScale = (baseScale * (_currentVerticalSpan() / baseSpan))
        .clamp(ThemeSettings.minFontScale, ThemeSettings.maxFontScale)
        .toDouble();
    ref.read(themeControllerProvider.notifier).setFontScale(newScale);
  }

  void _endPinch() {
    _baseScale = null;
    _baseVerticalSpan = null;
  }

  /// Resets the font scale to normal (`1.0`). Ignored while a two-finger pinch
  /// is active, so a stray tap during a pinch cannot reset mid-gesture.
  void _resetZoom() {
    if (_pointers.length >= 2) {
      return;
    }
    ref.read(themeControllerProvider.notifier).setFontScale(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final parentBehavior = ScrollConfiguration.of(context);
    final behavior = parentBehavior.copyWith(
      physics: _pointers.length >= 2
          ? const NeverScrollableScrollPhysics()
          : null,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.context != null) {
          _activePosition = Scrollable.of(notification.context!).position;
        }
        return false;
      },
      child: Listener(
        // A Listener never joins the gesture arena, so the child's one-finger
        // pan/scroll still works and we always see both fingers of a pinch.
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        behavior: HitTestBehavior.translucent,
        child: GestureDetector(
          // A double-tap resets the zoom to normal. This single-pointer
          // gesture never fights the two-finger pinch, which the arena-free
          // Listener above tracks directly.
          onDoubleTap: _resetZoom,
          behavior: HitTestBehavior.translucent,
          child: ScrollConfiguration(
            behavior: behavior,
            child: AbsorbPointer(
              absorbing: _pointers.length >= 2,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
