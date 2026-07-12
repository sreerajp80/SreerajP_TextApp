import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/degraded_document_view.dart';
import 'package:text_data/shell/tabs/document_tab.dart';

import '../../support/test_support.dart';

class _OkSaf extends SafService {
  final Uint8List bytes;
  _OkSaf(this.bytes);
  @override
  Future<Uint8List> readBytes(String uri) async => bytes;
}

class _FailSaf extends SafService {
  @override
  Future<Uint8List> readBytes(String uri) async => throw const SafIoFailure();
}

DocumentTab _tab() => const DocumentTab(
      id: 't',
      fingerprint: 'fp',
      uri: 'u',
      displayName: 'big.txt',
      size: 60 * 1024 * 1024,
      lastActiveAt: 1,
    );

Future<void> _pump(WidgetTester tester, SafService saf) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [safServiceProvider.overrideWithValue(saf)],
      child: localizedApp(
        home: Scaffold(
          body: DegradedDocumentView(tab: _tab(), linesPerPage: 5),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final text = List.generate(12, (i) => 'line$i').join('\n');

  testWidgets('shows the large-file read-only banner and first page',
      (tester) async {
    await _pump(tester, _OkSaf(Uint8List.fromList(text.codeUnits)));

    expect(find.textContaining('read-only mode'), findsOneWidget);
    // 12 lines / 5 per page = 3 pages.
    expect(find.textContaining('of 3'), findsOneWidget);

    final page = tester
        .widget<SelectableText>(find.byKey(const Key('degraded-page-text')));
    expect(page.data, contains('line0'));
    expect(page.data, contains('line4'));
    expect(page.data, isNot(contains('line5')));
  });

  testWidgets('next page button moves to the following page', (tester) async {
    await _pump(tester, _OkSaf(Uint8List.fromList(text.codeUnits)));

    await tester.tap(find.byKey(const Key('degraded-next-page')));
    await tester.pumpAndSettle();

    final page = tester
        .widget<SelectableText>(find.byKey(const Key('degraded-page-text')));
    expect(page.data, contains('line5'));
    expect(page.data, contains('line9'));
    expect(page.data, isNot(contains('line4')));
  });

  testWidgets('is read-only: no editable document surface', (tester) async {
    await _pump(tester, _OkSaf(Uint8List.fromList(text.codeUnits)));
    // The only text field is the page-jump box; the content is a SelectableText.
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // just the page jump
  });

  testWidgets('read failure shows a friendly state, never a crash',
      (tester) async {
    await _pump(tester, _FailSaf());
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const Key('degraded-page-text')), findsNothing);
  });
}
