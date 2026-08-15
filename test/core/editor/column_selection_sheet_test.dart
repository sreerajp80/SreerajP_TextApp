import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:text_data/core/editor/column_selection_sheet.dart';
import 'package:text_data/l10n/app_localizations.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ml')],
    home: Scaffold(body: child),
  );
}

void main() {
  group('ColumnSelectionSheet', () {
    testWidgets('renders all four mode segments and line range info', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = CodeLineEditingController.fromText(
        'first line\nsecond line\nthird line',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ColumnSelectionSheet(
            controller: controller,
            initialStartLineIndex: 0,
            initialEndLineIndex: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Column & Multi-Cursor Edit'), findsOneWidget);
      expect(find.text('Lines 1 to 3 (3 lines)'), findsOneWidget);
      expect(find.text('Prefix / Suffix'), findsOneWidget);
      expect(find.text('Column Block'), findsOneWidget);
      expect(find.text('Insert at Column'), findsOneWidget);
      expect(find.text('Numbering'), findsOneWidget);
      expect(find.text('Live Preview'), findsOneWidget);
    });

    testWidgets('applies prefix to selected lines upon tapping apply button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = CodeLineEditingController.fromText(
        'apple\nbanana\ncherry',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ColumnSelectionSheet(
            controller: controller,
            initialStartLineIndex: 0,
            initialEndLineIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap quick bullet chip
      final bulletChip = find.text('Bullet - ');
      expect(bulletChip, findsOneWidget);
      await tester.tap(bulletChip);
      await tester.pumpAndSettle();

      // Tap Apply Edits
      final applyButton = find.text('Apply Edits');
      expect(applyButton, findsOneWidget);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(controller.text, '- apple\n- banana\ncherry');
    });

    testWidgets('applies numbering when numbering mode is selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = CodeLineEditingController.fromText(
        'apple\nbanana\ncherry',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ColumnSelectionSheet(
            controller: controller,
            initialStartLineIndex: 0,
            initialEndLineIndex: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to numbering mode
      await tester.tap(find.text('Numbering'));
      await tester.pumpAndSettle();

      // Tap Apply Edits
      await tester.tap(find.text('Apply Edits'));
      await tester.pumpAndSettle();

      expect(controller.text, '1. apple\n2. banana\n3. cherry');
    });
  });
}
