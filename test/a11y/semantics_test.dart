import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/shell/home/home_screen.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/core/storage/saf_service.dart';

import '../support/test_support.dart';

/// Accessibility guard (task 13.3): primary controls must expose a screen-reader
/// label (from a tooltip / Semantics), and the app must not fight the platform's
/// font scaling. TalkBack-quality is verified manually on a device; this locks in
/// the labels so a redesign does not silently drop them.
void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentsControllerProvider
              .overrideWith(() => StubRecentsController(const [])),
          safServiceProvider.overrideWithValue(FakeSafService()),
        ],
        child: localizedApp(home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home icon actions expose semantics labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);

    // The icon-only open-file action must announce its purpose. A tooltip
    // surfaces in the semantics tree as the node's tooltip, which screen readers
    // speak. (Match the app-bar IconButton specifically: the empty-state body
    // also draws folder_open_outlined decoratively and inside a button.)
    expect(
      tester.getSemantics(
        find.widgetWithIcon(IconButton, Icons.folder_open_outlined),
      ),
      isSemantics(tooltip: 'Open a file'),
    );

    // The primary "Open a file" action carries a visible text label, which
    // becomes its semantics label.
    expect(find.bySemanticsLabel('Open a file'), findsWidgets);

    handle.dispose();
  });

  testWidgets('respects a large system text scale without overriding it',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpHome(tester);

    // The app must read back the platform scale, not a hardcoded 1.0.
    final scale = MediaQuery.textScalerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(scale.scale(10), greaterThan(10.0));
  });
}
