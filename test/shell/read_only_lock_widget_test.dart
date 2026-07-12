import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/editor_controller.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/shell/tabs/tabs_workspace.dart';

import '../support/test_support.dart';

// A non-text file so the workspace shows the placeholder toolbar (with the lock
// button) rather than the async TXT editor; this test targets the lock, not TXT.
SafFile _file(String id) => SafFile(
      uri: 'content://$id',
      displayName: '$id.bin',
      mimeType: 'application/octet-stream',
      size: 10,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorController read-only lock (3.8)', () {
    test('a locked editor rejects edits; unlock restores them', () {
      final c = EditorController(text: 'hello');
      c.setReadOnly(true);

      c.insert(' world'); // ignored while locked
      expect(c.text, 'hello');
      c.undo();
      expect(c.text, 'hello');

      c.setReadOnly(false);
      c.insert(' world'); // now allowed
      expect(c.text, 'hello world');
    });
  });

  group('ReadOnlyLockButton (3.8)', () {
    testWidgets('toggles the active tab lock and shows the banner',
        (tester) async {
      final kv = await inMemoryKeyValueStore();
      final container = ProviderContainer(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(kv),
          safServiceProvider.overrideWithValue(FakeSafService()),
          deviceMemoryProvider.overrideWithValue(
            const FakeDeviceMemory(4 * 1024 * 1024 * 1024),
          ),
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
      await tester.pumpAndSettle();

      // Not locked yet: no banner.
      expect(find.byKey(const Key('read-only-banner')), findsNothing);

      // Tap the lock button.
      await tester.tap(find.byKey(const Key('read-only-lock-button')));
      await tester.pumpAndSettle();

      expect(
        container.read(tabsControllerProvider).activeTab?.isReadOnly,
        isTrue,
      );
      expect(find.byKey(const Key('read-only-banner')), findsOneWidget);

      // Tap again to unlock.
      await tester.tap(find.byKey(const Key('read-only-lock-button')));
      await tester.pumpAndSettle();
      expect(
        container.read(tabsControllerProvider).activeTab?.isReadOnly,
        isFalse,
      );
      expect(find.byKey(const Key('read-only-banner')), findsNothing);
    });
  });
}
