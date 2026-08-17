import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/editor/editor_providers.dart';
import 'package:sreerajp_textapp/core/editor/editor_settings.dart';
import 'package:sreerajp_textapp/core/editor/editor_settings_controller.dart';
import 'package:sreerajp_textapp/formats/format_dispatch.dart';
import 'package:sreerajp_textapp/core/storage/device_memory.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/formats/txt/txt_session_manager.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_workspace.dart';

import '../support/test_support.dart';

/// Leaving edit mode — the toolbar exit button and the Android back button.
///
/// Edit mode used to be a one-way door: the only way out was a toggle that read
/// as "preview", and back did nothing at all. These tests pin down the way out,
/// and that no unsaved work leaves without being asked about (CLAUDE.md §3.6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('exit_edit_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  const file = SafFile(
    uri: 'content://note',
    displayName: 'note.txt',
    mimeType: 'text/plain',
    size: 7,
  );

  late WidgetRef probeRef;

  /// Opens a TXT tab in the workspace and returns its container.
  Future<ProviderContainer> pumpTab(WidgetTester tester) async {
    // Auto-save off: its periodic timer would keep pumpAndSettle from ever
    // settling. Auto-save has its own tests in test/formats/txt/.
    final kv = await inMemoryKeyValueStore({
      EditorSettings.autoSaveSecondsKey: 0,
    });
    final saf = FakeSafService(
      accessibleUris: {file.uri},
      contents: {file.uri: Uint8List.fromList('on disk'.codeUnits)},
      writableUris: {file.uri},
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
        // inside a widget test's fake-async zone, and it would leave the
        // document stuck on its loading spinner.
        draftStoreProvider.overrideWith((ref) async => _MemoryDraftStore()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(
          home: Scaffold(
            body: Column(
              children: [
                // A live WidgetRef, so a test can call the shared edit-mode
                // helpers exactly as a toolbar button does.
                Consumer(
                  builder: (context, ref, _) {
                    probeRef = ref;
                    return const SizedBox.shrink();
                  },
                ),
                const Expanded(child: TabsWorkspace()),
              ],
            ),
          ),
        ),
      ),
    );
    container.read(tabsControllerProvider.notifier).openFile(file, 'fp-note');
    await tester.pumpAndSettle();
    return container;
  }

  DocumentTab activeTab(ProviderContainer c) =>
      c.read(tabsControllerProvider).activeTab!;

  bool isEditing(ProviderContainer c) =>
      c.read(txtSessionManagerProvider).peek(activeTab(c).id)!.viewMode ==
      TabViewMode.edit;

  Future<void> enterEditMode(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('txt-view-edit-toggle')));
    await tester.pumpAndSettle();
  }

  /// Types into the open document, which marks the tab dirty.
  void typeSomething(ProviderContainer c) {
    c.read(txtSessionManagerProvider).peek(activeTab(c).id)!.code!.text =
        'edited, not saved';
  }

  /// Delivers an Android back press to the app.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('the toolbar toggle says "Exit edit mode" while editing', (
    tester,
  ) async {
    await pumpTab(tester);

    // Before: the button offers to start editing.
    expect(find.byTooltip('Edit mode'), findsOneWidget);

    await enterEditMode(tester);

    // After: it names the way out, instead of showing an eye that reads as
    // "preview" — the thing that left people stuck.
    expect(find.byTooltip('Exit edit mode'), findsOneWidget);
    expect(find.byIcon(Icons.edit_off_outlined), findsOneWidget);
  });

  testWidgets('back leaves edit mode instead of the screen', (tester) async {
    final c = await pumpTab(tester);
    await enterEditMode(tester);
    expect(isEditing(c), isTrue);

    await pressBack(tester);

    expect(isEditing(c), isFalse);
    // The tab is still open — back left the mode, not the document.
    expect(c.read(tabsControllerProvider).tabs, hasLength(1));
  });

  testWidgets('a clean tab leaves edit mode with no prompt', (tester) async {
    final c = await pumpTab(tester);
    await enterEditMode(tester);

    await pressBack(tester);

    expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
    expect(isEditing(c), isFalse);
  });

  testWidgets('back with unsaved edits asks first', (tester) async {
    final c = await pumpTab(tester);
    await enterEditMode(tester);
    typeSomething(c);
    await tester.pumpAndSettle();

    await pressBack(tester);

    expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);
    // Still editing until the user answers.
    expect(isEditing(c), isTrue);
  });

  testWidgets('Keep editing cancels the exit and keeps the edits', (
    tester,
  ) async {
    final c = await pumpTab(tester);
    await enterEditMode(tester);
    typeSomething(c);
    await tester.pumpAndSettle();

    await pressBack(tester);
    await tester.tap(find.byKey(const Key('unsaved-cancel')));
    await tester.pumpAndSettle();

    expect(isEditing(c), isTrue);
    expect(activeTab(c).isDirty, isTrue);
    final session = c.read(txtSessionManagerProvider).peek(activeTab(c).id)!;
    expect(session.code!.text, 'edited, not saved');
  });

  testWidgets('Discard puts the file content back and leaves edit mode', (
    tester,
  ) async {
    final c = await pumpTab(tester);
    await enterEditMode(tester);
    typeSomething(c);
    await tester.pumpAndSettle();

    await pressBack(tester);
    await tester.tap(find.byKey(const Key('unsaved-discard')));
    await tester.pumpAndSettle();

    final session = c.read(txtSessionManagerProvider).peek(activeTab(c).id)!;
    // The tab stays open, so "discard" has to actually undo the edits.
    expect(session.code!.text, 'on disk');
    expect(isEditing(c), isFalse);
    expect(activeTab(c).isDirty, isFalse);
  });

  testWidgets('back does nothing special when the tab is not being edited', (
    tester,
  ) async {
    final c = await pumpTab(tester);
    expect(isEditing(c), isFalse);

    await pressBack(tester);

    // No prompt, no mode change — the guard is transparent here.
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
    expect(isEditing(c), isFalse);
  });

  group('leaving edit mode after a save', () {
    testWidgets('a finished save goes back to view mode by default', (
      tester,
    ) async {
      final c = await pumpTab(tester);
      await enterEditMode(tester);

      exitEditModeAfterSave(probeRef, activeTab(c), saved: true);
      await tester.pumpAndSettle();

      expect(isEditing(c), isFalse);
    });

    testWidgets('a save that did not happen leaves the user editing', (
      tester,
    ) async {
      final c = await pumpTab(tester);
      await enterEditMode(tester);

      // Cancelled or failed: the user must stay exactly where they were.
      exitEditModeAfterSave(probeRef, activeTab(c), saved: false);
      await tester.pumpAndSettle();

      expect(isEditing(c), isTrue);
    });

    testWidgets('the setting can turn it off', (tester) async {
      final c = await pumpTab(tester);
      c.read(editorSettingsProvider.notifier).setExitEditAfterSave(false);
      await enterEditMode(tester);

      exitEditModeAfterSave(probeRef, activeTab(c), saved: true);
      await tester.pumpAndSettle();

      expect(isEditing(c), isTrue);
    });
  });
}

/// A [DraftStore] that keeps drafts in a map, so nothing here touches the disk
/// or the drafts database. The real store has its own tests in
/// test/core/editor/draft_store_test.dart.
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
