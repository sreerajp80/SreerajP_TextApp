import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/shell/tabs/tabs_workspace.dart';

import '../support/test_support.dart';

// A non-text file so the workspace shows the format placeholder — these tests
// exercise tab close / unsaved-prompt mechanics, not the TXT editor (which has
// its own tests in test/formats/txt/).
SafFile _file(String id) => SafFile(
      uri: 'content://$id',
      displayName: '$id.bin',
      mimeType: 'application/octet-stream',
      size: 10,
    );

Future<(ProviderContainer, TabsController)> _pumpWithDirtyTab(
  WidgetTester tester,
) async {
  final kv = await inMemoryKeyValueStore();
  final container = ProviderContainer(
    overrides: [
      keyValueStoreSyncProvider.overrideWithValue(kv),
      safServiceProvider.overrideWithValue(FakeSafService()),
      deviceMemoryProvider
          .overrideWithValue(const FakeDeviceMemory(4 * 1024 * 1024 * 1024)),
    ],
  );
  addTearDown(container.dispose);
  final tabs = container.read(tabsControllerProvider.notifier);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const Scaffold(body: TabsWorkspace())),
    ),
  );

  tabs.openFile(_file('a'), '10-a');
  final state = container.read(tabsControllerProvider);
  tabs.setDirty(state.activeTab!.id, true);
  await tester.pumpAndSettle();
  return (container, tabs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('closing a dirty tab shows the Save/Discard prompt (3.7)',
      (tester) async {
    await _pumpWithDirtyTab(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);
    expect(find.byKey(const Key('unsaved-save')), findsOneWidget);
    expect(find.byKey(const Key('unsaved-save-copy')), findsOneWidget);
    expect(find.byKey(const Key('unsaved-discard')), findsOneWidget);
  });

  testWidgets('Discard closes the tab', (tester) async {
    final (container, _) = await _pumpWithDirtyTab(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-discard')));
    await tester.pumpAndSettle();

    expect(container.read(tabsControllerProvider).tabs, isEmpty);
  });

  testWidgets('Keep editing leaves the tab open', (tester) async {
    final (container, _) = await _pumpWithDirtyTab(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-cancel')));
    await tester.pumpAndSettle();

    expect(container.read(tabsControllerProvider).tabs, hasLength(1));
  });

  testWidgets('a read-only tab is offered a copy only (no Save)',
      (tester) async {
    final (container, tabs) = await _pumpWithDirtyTab(tester);
    final id = container.read(tabsControllerProvider).activeTab!.id;
    tabs.setReadOnly(id, true);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unsaved-save')), findsNothing);
    expect(find.byKey(const Key('unsaved-save-copy')), findsOneWidget);
  });
}
