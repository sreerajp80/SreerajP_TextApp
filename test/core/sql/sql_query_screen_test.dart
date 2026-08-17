import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';
import 'package:sreerajp_textapp/core/sql/sql_query_screen.dart';
import 'package:sreerajp_textapp/core/sql/sql_source.dart';

import '../../support/test_support.dart';

/// Feature 4 — the SQL screen itself: the schema is on screen before anything is
/// typed, a query shows its rows, and a blocked statement shows a message
/// instead of running.
void main() {
  setUpAll(() => sqfliteFfiInit());

  SqlSource source() => SqlSource(
    tabId: 'tab-1',
    displayName: 'sales.csv',
    suggestedTableName: 'data',
    build: () async => SqlDataset.fromRows(
      tableName: 'data',
      sourceLabel: 'sales.csv',
      columnNames: ['region', 'amount'],
      rows: [
        ['South', '100'],
        ['North', '250'],
      ],
    ),
  );

  /// The engine really talks to SQLite, which needs the real event loop, so
  /// every step that waits on it runs inside [WidgetTester.runAsync].
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
  }

  Future<void> pumpScreen(WidgetTester tester, {SqlSource? primary}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          home: SqlQueryScreen(
            primary: primary ?? source(),
            otherSources: () => const [],
            databaseFactoryOverride: databaseFactoryFfi,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> runQuery(WidgetTester tester, String sql) async {
    await tester.enterText(find.byKey(const Key('sql-input')), sql);
    await tester.pump();
    await tester.tap(find.byKey(const Key('sql-run-button')));
    await settle(tester);
  }

  testWidgets('the tables and columns are shown before anything is typed', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('sales.csv'), findsWidgets);
    expect(find.text('region'), findsOneWidget);
    expect(find.text('amount'), findsOneWidget);
    // A starter query is pre-filled, so Run works straight away.
    final field = tester.widget<TextField>(find.byKey(const Key('sql-input')));
    expect(field.controller?.text, contains('FROM data'));
  });

  testWidgets('running a query shows its rows', (tester) async {
    await pumpScreen(tester);
    await runQuery(tester, 'SELECT region FROM data ORDER BY region');

    expect(find.text('North'), findsOneWidget);
    expect(find.text('South'), findsOneWidget);
  });

  testWidgets('a blocked statement is refused with a message, not run', (
    tester,
  ) async {
    await pumpScreen(tester);
    await runQuery(tester, 'DROP TABLE data');

    expect(find.byKey(const Key('sql-error-text')), findsOneWidget);

    // The data is untouched: a normal query still works afterwards.
    await runQuery(tester, 'SELECT COUNT(*) AS n FROM data');
    expect(find.byKey(const Key('sql-error-text')), findsNothing);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('a document with nothing tabular says so', (tester) async {
    await pumpScreen(
      tester,
      primary: SqlSource(
        tabId: 'tab-2',
        displayName: 'notes.json',
        suggestedTableName: 'data',
        build: () async => null,
      ),
    );
    expect(find.byKey(const Key('sql-input')), findsNothing);
    expect(find.byKey(const Key('sql-run-button')), findsNothing);
  });
}
