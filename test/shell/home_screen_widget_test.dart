import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/shell/shell_providers.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/home/home_screen.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';

import '../support/test_support.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, List<RecentEntry> entries) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentsControllerProvider.overrideWith(
            () => StubRecentsController(entries),
          ),
          safServiceProvider.overrideWithValue(FakeSafService()),
        ],
        child: localizedApp(home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty list shows the friendly empty state', (tester) async {
    await pumpHome(tester, const []);
    expect(find.text('No recent files'), findsOneWidget);
    expect(find.text('Open a file'), findsWidgets);
    expect(find.text('New document'), findsOneWidget);
  });

  testWidgets('new document opens the five-format picker', (tester) async {
    await pumpHome(tester, const []);

    await tester.tap(find.text('New document'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a document type'), findsOneWidget);
    expect(find.text('Text (TXT)'), findsOneWidget);
    expect(find.text('Markdown (MD)'), findsOneWidget);
    expect(find.text('Table (CSV)'), findsOneWidget);
    expect(find.text('Data (JSON)'), findsOneWidget);
    expect(find.text('Data (XML)'), findsOneWidget);
  });

  testWidgets('populated list renders recent entries', (tester) async {
    await pumpHome(tester, [recentEntry('notes.txt')]);
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.text('No recent files'), findsNothing);
  });

  testWidgets('a stale entry is shown as unavailable', (tester) async {
    await pumpHome(tester, [recentEntry('missing.csv', available: false)]);
    expect(find.text('missing.csv'), findsOneWidget);
    expect(find.textContaining('Unavailable'), findsOneWidget);
  });

  testWidgets('removing an entry drops it from the list', (tester) async {
    await pumpHome(tester, [recentEntry('a.txt'), recentEntry('b.txt')]);
    expect(find.text('a.txt'), findsOneWidget);

    // Tap the remove (×) button on the first row.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('a.txt'), findsNothing);
    expect(find.text('b.txt'), findsOneWidget);
  });

  testWidgets('tapping a recent still opens editor when its list refreshes', (
    tester,
  ) async {
    final store = await inMemoryKeyValueStore();
    final entry = recentEntry('notes.txt');
    final container = ProviderContainer(
      overrides: [
        recentsControllerProvider.overrideWith(
          () => StubRecentsController([entry], true),
        ),
        safServiceProvider.overrideWithValue(
          FakeSafService(
            contents: {
              entry.file.uri: Uint8List.fromList([1]),
            },
          ),
        ),
        keyValueStoreSyncProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('notes.txt'));
    await tester.pumpAndSettle();

    expect(container.read(tabsControllerProvider).tabs, hasLength(1));
    expect(container.read(shellDestinationProvider), ShellDestination.editor);
    expect(tester.takeException(), isNull);
  });
}
