import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/create_document_action.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/shell_providers.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';

import '../support/test_support.dart';

void main() {
  test('supported formats have the expected UTF-8 starter files', () {
    final expected = <NewDocumentFormat, (String, String, String)>{
      NewDocumentFormat.txt: ('untitled.txt', 'text/plain', ''),
      NewDocumentFormat.markdown: ('untitled.md', 'text/markdown', ''),
      NewDocumentFormat.csv: ('untitled.csv', 'text/csv', ''),
      NewDocumentFormat.json: ('untitled.json', 'application/json', '{}\n'),
      NewDocumentFormat.xml: (
        'untitled.xml',
        'application/xml',
        '<?xml version="1.0" encoding="UTF-8"?>\n<root></root>\n',
      ),
    };

    expect(NewDocumentFormat.values, hasLength(5));
    for (final entry in expected.entries) {
      expect(entry.key.suggestedName, entry.value.$1);
      expect(entry.key.mimeType, entry.value.$2);
      expect(utf8.decode(entry.key.starterBytes), entry.value.$3);
    }
  });

  Future<ProviderContainer> pumpAction(
    WidgetTester tester,
    FakeSafService saf,
  ) async {
    final store = await inMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(store),
        safServiceProvider.overrideWithValue(saf),
        recentsControllerProvider.overrideWith(() => StubRecentsController()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(home: const _CreateHarness()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('successful creation opens a tab and selects the editor', (
    tester,
  ) async {
    final saf = FakeSafService(
      createResult: const SafFile(
        uri: 'content://new/data.json',
        displayName: 'data.json',
        mimeType: 'application/json',
        size: 3,
      ),
    );
    final container = await pumpAction(tester, saf);

    await tester.tap(find.text('Create JSON'));
    await tester.pumpAndSettle();

    expect(saf.lastSuggestedName, 'untitled.json');
    expect(saf.lastMimeType, 'application/json');
    expect(saf.lastCreatedBytes, Uint8List.fromList(utf8.encode('{}\n')));
    expect(container.read(tabsControllerProvider).tabs, hasLength(1));
    expect(
      container.read(tabsControllerProvider).activeTab?.displayName,
      'data.json',
    );
    expect(
      container.read(tabsControllerProvider).activeTab?.viewMode,
      TabViewMode.edit,
    );
    expect(container.read(shellDestinationProvider), ShellDestination.editor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling creation leaves tabs unchanged', (tester) async {
    final container = await pumpAction(tester, FakeSafService());

    await tester.tap(find.text('Create JSON'));
    await tester.pumpAndSettle();

    expect(container.read(tabsControllerProvider).tabs, isEmpty);
    expect(container.read(shellDestinationProvider), ShellDestination.home);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('storage failure is friendly and does not open a tab', (
    tester,
  ) async {
    final container = await pumpAction(
      tester,
      FakeSafService(createError: const SafPermissionDenied()),
    );

    await tester.tap(find.text('Create JSON'));
    await tester.pumpAndSettle();

    expect(container.read(tabsControllerProvider).tabs, isEmpty);
    expect(
      find.text('Permission to access this file was denied.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _CreateHarness extends ConsumerWidget {
  const _CreateHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () =>
            CreateDocumentAction(ref).create(context, NewDocumentFormat.json),
        child: const Text('Create JSON'),
      ),
    ),
  );
}
