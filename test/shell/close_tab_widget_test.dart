import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/editor/editor_providers.dart';
import 'package:sreerajp_textapp/core/editor/editor_settings.dart';
import 'package:sreerajp_textapp/core/storage/device_memory.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/shell/shell_providers.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_workspace.dart';

import '../support/test_support.dart';

/// Closing a tab.
///
/// The workspace used to dispose the closed document's session — and with it the
/// editor controllers the screen was still using — in the middle of its own
/// `build()`. That threw, and a release build paints a thrown build as a plain
/// grey box: the user closed a tab and got an empty screen.
///
/// These tests pin down that closing a tab shows the next document, that closing
/// the last one leaves the Editor for Home, and that neither throws.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('close_tab_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  SafFile file(String id) => SafFile(
    uri: 'content://$id',
    displayName: '$id.txt',
    mimeType: 'text/plain',
    size: 7,
  );

  /// Builds the workspace with [names] open, the last one active.
  Future<ProviderContainer> pumpTabs(
    WidgetTester tester,
    List<String> names,
  ) async {
    // Auto-save off: its periodic timer would keep pumpAndSettle from settling.
    final kv = await inMemoryKeyValueStore({
      EditorSettings.autoSaveSecondsKey: 0,
    });
    final saf = FakeSafService(
      accessibleUris: {for (final n in names) file(n).uri},
      contents: {
        for (final n in names)
          file(n).uri: Uint8List.fromList('text of $n'.codeUnits),
      },
      writableUris: {for (final n in names) file(n).uri},
    );
    final container = ProviderContainer(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(kv),
        safServiceProvider.overrideWithValue(saf),
        deviceMemoryProvider.overrideWithValue(
          const FakeDeviceMemory(4 * 1024 * 1024 * 1024),
        ),
        // Real path_provider is not available in tests.
        saveTempDirProvider.overrideWith((ref) async => tempDir),
        // In memory, not on disk: real file and database I/O never completes
        // inside a widget test's fake-async zone.
        draftStoreProvider.overrideWith((ref) async => _MemoryDraftStore()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(home: const Scaffold(body: TabsWorkspace())),
      ),
    );

    final tabs = container.read(tabsControllerProvider.notifier);
    for (final n in names) {
      tabs.openFile(file(n), 'fp-$n');
    }
    await tester.pumpAndSettle();
    return container;
  }

  /// Taps the × on the tab showing [name].
  Future<void> closeTab(WidgetTester tester, String name) async {
    final chip = find.ancestor(
      of: find.text('$name.txt'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: chip.first, matching: find.byIcon(Icons.close)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('closing the active tab shows another one, with no crash', (
    tester,
  ) async {
    final c = await pumpTabs(tester, ['a', 'b']);

    await closeTab(tester, 'b');

    expect(tester.takeException(), isNull);
    final state = c.read(tabsControllerProvider);
    expect(state.tabs, hasLength(1));
    expect(state.activeTab?.displayName, 'a.txt');
    // The remaining document is on screen, not an error box.
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.text('a.txt'), findsOneWidget);
  });

  testWidgets('closing a tab moves to its neighbour, not to the last tab', (
    tester,
  ) async {
    final c = await pumpTabs(tester, ['a', 'b', 'c']);
    final first = c.read(tabsControllerProvider).tabs.first;
    c.read(tabsControllerProvider.notifier).setActive(first.id);
    await tester.pumpAndSettle();

    await closeTab(tester, 'a');

    expect(tester.takeException(), isNull);
    // "The next tab" is the neighbour on the right, not whatever is last.
    expect(c.read(tabsControllerProvider).activeTab?.displayName, 'b.txt');
  });

  testWidgets('closing the right-most tab falls back to the one on its left', (
    tester,
  ) async {
    final c = await pumpTabs(tester, ['a', 'b', 'c']);

    await closeTab(tester, 'c');

    expect(tester.takeException(), isNull);
    expect(c.read(tabsControllerProvider).activeTab?.displayName, 'b.txt');
  });

  testWidgets('closing the last open tab goes back to Home', (tester) async {
    final c = await pumpTabs(tester, ['a']);
    c.read(shellDestinationProvider.notifier).select(ShellDestination.editor);

    await closeTab(tester, 'a');

    expect(tester.takeException(), isNull);
    expect(c.read(tabsControllerProvider).tabs, isEmpty);
    expect(c.read(shellDestinationProvider), ShellDestination.home);
  });
}

/// A [DraftStore] that keeps drafts in a map, so nothing here touches the disk
/// or the drafts database.
class _MemoryDraftStore implements DraftStore {
  final Map<String, String> _drafts = {};

  @override
  Future<void> save(String fingerprint, String content) async =>
      _drafts[fingerprint] = content;

  @override
  Future<String?> load(String fingerprint) async => _drafts[fingerprint];

  @override
  Future<bool> hasDraft(String fingerprint) async =>
      _drafts.containsKey(fingerprint);

  @override
  Future<void> discard(String fingerprint) async => _drafts.remove(fingerprint);

  @override
  Future<void> wipe(String fingerprint) async => _drafts.remove(fingerprint);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not needed by these tests');
}
