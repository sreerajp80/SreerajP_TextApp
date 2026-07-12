import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/placeholder_document_view.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/shell/tabs/tabs_workspace.dart';

import '../support/test_support.dart';

// A non-text file so the body is the placeholder (this test checks edge-swipe
// tab switching, not the TXT editor).
SafFile file(String id) => SafFile(
    uri: 'content://$id',
    displayName: '$id.bin',
    mimeType: 'application/octet-stream');

void main() {
  Future<ProviderContainer> mountWithTwoTabs(WidgetTester tester) async {
    final store = await inMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(store),
        safServiceProvider.overrideWithValue(FakeSafService()),
        deviceMemoryProvider
            .overrideWithValue(const FakeDeviceMemory(4 * 1024 * 1024 * 1024)),
      ],
    );
    addTearDown(container.dispose);

    final tabs = container.read(tabsControllerProvider.notifier);
    tabs.openFile(file('a'), '10-a');
    tabs.openFile(file('b'), '20-b'); // active = b

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(home: const Scaffold(body: TabsWorkspace())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('edge swipe changes the active tab (2.7)', (tester) async {
    final container = await mountWithTwoTabs(tester);

    // Active tab is 'b' at start.
    expect(container.read(tabsControllerProvider).activeTab?.displayName,
        'b.bin');

    // Fling left on the right edge zone → next() → wraps to 'a'.
    await tester.fling(
      find.byKey(const Key('tab-swipe-right-edge')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(container.read(tabsControllerProvider).activeTab?.displayName,
        'a.bin');
  });

  testWidgets('a swipe in the content centre does not switch tabs (edge-binding)',
      (tester) async {
    final container = await mountWithTwoTabs(tester);
    expect(container.read(tabsControllerProvider).activeTab?.displayName,
        'b.bin');

    // Fling on the document body (centre) — no edge gesture zone there.
    await tester.fling(
      find.byType(PlaceholderDocumentView),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    // Still on 'b' — the centre swipe was ignored.
    expect(container.read(tabsControllerProvider).activeTab?.displayName,
        'b.bin');
  });
}
