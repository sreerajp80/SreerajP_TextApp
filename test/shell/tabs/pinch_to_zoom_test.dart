import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/theme/theme_controller.dart';
import 'package:text_data/core/editor/pinch_to_zoom_area.dart';

import '../../support/test_support.dart';

void main() {
  testWidgets('PinchToZoomArea scales the font size on pinch gestures',
      (tester) async {
    final store = await inMemoryKeyValueStore();

    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
        ],
        child: localizedApp(
          home: Scaffold(
            body: PinchToZoomArea(
              child: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  final settings = ref.watch(themeControllerProvider);
                  return Center(
                    child: Text(
                      'Zoomable Text',
                      style: TextStyle(fontSize: 16 * settings.fontScale),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial font scale is 1.0.
    expect(capturedRef.read(themeControllerProvider).fontScale, 1.0);

    // Simulate pinch zoom out (zoom in / increase scale).
    // Start with two pointers at (100, 100) and (200, 200).
    final TestGesture gesture1 = await tester.startGesture(const Offset(100, 100));
    final TestGesture gesture2 = await tester.startGesture(const Offset(200, 200));
    await tester.pump();

    // Move pointers apart: distance increases from 141.4 to 282.8 (scale factor of 2.0).
    await gesture1.moveTo(const Offset(50, 50));
    await gesture2.moveTo(const Offset(250, 250));
    await tester.pump();

    // End gestures.
    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();

    // Check if the font scale has increased to 2.0.
    expect(capturedRef.read(themeControllerProvider).fontScale, 2.0);

    // Now let's simulate pinch zoom in (zoom out / decrease scale).
    // Start with two pointers at (50, 50) and (250, 250) (distance 282.8).
    final TestGesture gesture3 = await tester.startGesture(const Offset(50, 50));
    final TestGesture gesture4 = await tester.startGesture(const Offset(250, 250));
    await tester.pump();

    // Move pointers closer: distance decreases from 282.8 to 141.4 (scale factor of 0.5 relative to start).
    await gesture3.moveTo(const Offset(100, 100));
    await gesture4.moveTo(const Offset(200, 200));
    await tester.pump();

    // End gestures.
    await gesture3.up();
    await gesture4.up();
    await tester.pumpAndSettle();

    // Distance went from 282.8 to 141.4, which is 0.5x of the scale at start (2.0), so 2.0 * 0.5 = 1.0.
    expect(capturedRef.read(themeControllerProvider).fontScale, 1.0);
  });

  testWidgets('PinchToZoomArea ignores horizontal pinch gestures but accepts vertical ones',
      (tester) async {
    final store = await inMemoryKeyValueStore();

    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
        ],
        child: localizedApp(
          home: Scaffold(
            body: PinchToZoomArea(
              child: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  final settings = ref.watch(themeControllerProvider);
                  return Center(
                    child: Text(
                      'Zoomable Text',
                      style: TextStyle(fontSize: 16 * settings.fontScale),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial font scale is 1.0.
    expect(capturedRef.read(themeControllerProvider).fontScale, 1.0);

    // 1. Simulate horizontal-only pinch zoom out.
    // Start with two pointers at (100, 100) and (200, 200) (vertical distance = 100).
    final TestGesture gestureH1 = await tester.startGesture(const Offset(100, 100));
    final TestGesture gestureH2 = await tester.startGesture(const Offset(200, 200));
    await tester.pump();

    // Move pointers horizontally apart only: X distance increases, but Y distance remains 100.
    await gestureH1.moveTo(const Offset(50, 100));
    await gestureH2.moveTo(const Offset(250, 200));
    await tester.pump();

    // End gestures.
    await gestureH1.up();
    await gestureH2.up();
    await tester.pumpAndSettle();

    // Font scale should still be 1.0 because vertical distance did not change.
    expect(capturedRef.read(themeControllerProvider).fontScale, 1.0);

    // 2. Simulate vertical-only pinch zoom out.
    // Start with two pointers at (100, 100) and (200, 200) (vertical distance = 100).
    final TestGesture gestureV1 = await tester.startGesture(const Offset(100, 100));
    final TestGesture gestureV2 = await tester.startGesture(const Offset(200, 200));
    await tester.pump();

    // Move pointers vertically apart only: Y distance increases to 200, X distance remains 100.
    await gestureV1.moveTo(const Offset(100, 50));
    await gestureV2.moveTo(const Offset(200, 250));
    await tester.pump();

    // End gestures.
    await gestureV1.up();
    await gestureV2.up();
    await tester.pumpAndSettle();

    // Check if the font scale has increased to 2.0 because vertical distance doubled.
    expect(capturedRef.read(themeControllerProvider).fontScale, 2.0);
  });

  testWidgets('PinchToZoomArea updates ScrollConfiguration physics to NeverScrollableScrollPhysics when 2 or more pointers are down',
      (tester) async {
    final store = await inMemoryKeyValueStore();
    ScrollPhysics? activePhysics;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
        ],
        child: localizedApp(
          home: Scaffold(
            body: PinchToZoomArea(
              child: SizedBox.expand(
                child: Builder(
                  builder: (context) {
                    activePhysics = ScrollConfiguration.of(context).getScrollPhysics(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // With 0 pointers, physics should be default/null.
    expect(activePhysics, isNot(isA<NeverScrollableScrollPhysics>()));

    // 1st pointer down.
    final TestGesture gesture1 = await tester.startGesture(const Offset(100, 100));
    await tester.pump();
    expect(activePhysics, isNot(isA<NeverScrollableScrollPhysics>()));

    // 2nd pointer down.
    final TestGesture gesture2 = await tester.startGesture(const Offset(200, 200));
    await tester.pump();
    
    // With 2 pointers, physics should be NeverScrollableScrollPhysics.
    expect(activePhysics, isA<NeverScrollableScrollPhysics>());

    // Lift one pointer.
    await gesture1.up();
    await tester.pump();
    expect(activePhysics, isNot(isA<NeverScrollableScrollPhysics>()));

    // Lift other pointer.
    await gesture2.up();
    await tester.pumpAndSettle();
  });

  testWidgets('PinchToZoomArea cancels ongoing scroll drag when 2 or more pointers are down',
      (tester) async {
    final store = await inMemoryKeyValueStore();
    final ScrollController controller = ScrollController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
        ],
        child: localizedApp(
          home: Scaffold(
            body: PinchToZoomArea(
              child: SizedBox.expand(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 100,
                  itemBuilder: (context, index) => SizedBox(
                    height: 100,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial scroll offset is 0.
    expect(controller.offset, 0.0);

    // 1st pointer down at (100, 300) and drags up to scroll down.
    final TestGesture gesture1 = await tester.startGesture(const Offset(100, 300));
    await tester.pump(const Duration(milliseconds: 50));
    // Move slightly to break touch slop
    await gesture1.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 50));
    // Move more to scroll
    await gesture1.moveBy(const Offset(0, -80));
    await tester.pumpAndSettle();

    // Verify scrolling occurred (offset > 0).
    final double scrolledOffset = controller.offset;
    expect(scrolledOffset, greaterThan(0.0));

    // 2nd pointer down. This triggers key change and should cancel the drag.
    final TestGesture gesture2 = await tester.startGesture(const Offset(200, 300));
    await tester.pump();

    // Move 1st pointer again (further up).
    await gesture1.moveTo(const Offset(100, 100));
    await tester.pumpAndSettle();

    // Verify scrolling is cancelled/stopped (offset remains identical).
    expect(controller.offset, scrolledOffset);

    // Lift fingers.
    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();
  });
}

