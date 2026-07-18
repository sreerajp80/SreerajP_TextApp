import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';

/// A widget that wraps any file viewer/editor surface and intercepts pinch/scale
/// gestures to dynamically change the app-wide font size scale (CLAUDE.md §3).
class PinchToZoomArea extends ConsumerStatefulWidget {
  final Widget child;

  const PinchToZoomArea({super.key, required this.child});

  @override
  ConsumerState<PinchToZoomArea> createState() => _PinchToZoomAreaState();
}

class _PinchToZoomAreaState extends ConsumerState<PinchToZoomArea> {
  double? _baseScale;
  final Set<int> _pointers = {};
  ScrollPosition? _activePosition;

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
        onPointerDown: (event) {
          setState(() {
            _pointers.add(event.pointer);
            if (_pointers.length >= 2) {
              try {
                if (_activePosition != null && _activePosition!.hasPixels) {
                  _activePosition!.jumpTo(_activePosition!.pixels);
                }
              } catch (_) {}
            }
          });
        },
        onPointerUp: (event) {
          setState(() {
            _pointers.remove(event.pointer);
          });
        },
        onPointerCancel: (event) {
          setState(() {
            _pointers.remove(event.pointer);
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _baseScale = ref.read(themeControllerProvider).fontScale;
          },
          onScaleUpdate: (details) {
            if (_baseScale != null && details.pointerCount >= 2) {
              final newScale = _baseScale! * details.verticalScale;
              ref.read(themeControllerProvider.notifier).setFontScale(newScale);
            }
          },
          onScaleEnd: (details) {
            _baseScale = null;
          },
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
