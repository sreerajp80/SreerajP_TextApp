import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/formats/markdown/md_table_builder_dialog.dart';
import 'package:sreerajp_textapp/formats/markdown/md_table_source.dart';

import '../../support/test_support.dart';

/// Guards the visual Markdown table builder dialog (roadmap §4.4.2).
void main() {
  /// Opens the builder and captures what it returns.
  Future<String?> openBuilder(
    WidgetTester tester, {
    MdTableData? initial,
  }) async {
    String? result;
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showMdTableBuilder(context, initial: initial);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<String?> finish(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('md-table-insert')));
    await tester.pumpAndSettle();
    return null;
  }

  testWidgets('opens with a usable blank table', (tester) async {
    await openBuilder(tester);
    // Three columns by default, so the first row of header fields is there.
    expect(find.byKey(const Key('md-table-cell--1-0')), findsOneWidget);
    expect(find.byKey(const Key('md-table-cell--1-2')), findsOneWidget);
    expect(find.byKey(const Key('md-table-preview')), findsOneWidget);
  });

  testWidgets('the preview updates as cells are typed into', (tester) async {
    await openBuilder(tester, initial: MdTableData.blank(columns: 1, rows: 1));

    await tester.enterText(find.byKey(const Key('md-table-cell--1-0')), 'Name');
    await tester.pump();

    final preview = tester.widget<Text>(
      find.byKey(const Key('md-table-preview')),
    );
    expect(preview.data, contains('Name'));
  });

  testWidgets('adding a row and a column changes the grid', (tester) async {
    await openBuilder(tester, initial: MdTableData.blank(columns: 1, rows: 1));

    await tester.tap(find.byKey(const Key('md-table-add-column')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('md-table-cell--1-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('md-table-add-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('md-table-cell-1-0')), findsOneWidget);
  });

  testWidgets('an existing table is loaded for editing', (tester) async {
    final initial = MdTableData.parse('''
| Name | Age |
| --- | --- |
| Ada | 36 |''');
    await openBuilder(tester, initial: initial);

    final field = tester.widget<TextField>(
      find.byKey(const Key('md-table-cell--1-0')),
    );
    expect(field.controller!.text, 'Name');

    final cell = tester.widget<TextField>(
      find.byKey(const Key('md-table-cell-0-1')),
    );
    expect(cell.controller!.text, '36');
  });

  testWidgets('inserting returns Markdown that parses back', (tester) async {
    String? captured;
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await showMdTableBuilder(
                  context,
                  initial: MdTableData.blank(columns: 2, rows: 1),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('md-table-cell--1-0')), 'A');
    await tester.enterText(find.byKey(const Key('md-table-cell-0-0')), '1');
    await finish(tester);

    expect(captured, isNotNull);
    final parsed = MdTableData.parse(captured!)!;
    expect(parsed.header.first, 'A');
    expect(parsed.cell(0, 0), '1');
  });

  testWidgets('cancelling returns nothing', (tester) async {
    String? captured = 'unset';
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await showMdTableBuilder(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(captured, isNull);
  });
}
