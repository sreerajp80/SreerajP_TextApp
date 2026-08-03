import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/editor/atomic_saver.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/core/metadata/file_metadata.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/formats/markdown/md_document_session.dart';
import 'package:text_data/formats/markdown/md_live_preview.dart';
import 'package:text_data/shell/tabs/document_tab.dart';

import '../../support/test_support.dart';

class _Saf extends SafService {
  final Uint8List bytes;
  _Saf(this.bytes);

  @override
  Future<Uint8List> readBytes(String uri) async => bytes;

  @override
  Future<bool> isWritable(String uri) async => true;

  @override
  Future<int?> modifiedTime(String uri) async => null;
}

/// Guards the split-screen live dual view (roadmap §4.4.1): the layout must
/// follow the device orientation, not the raw screen width.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late DraftStore draftStore;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('md_split_test');
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    draftStore =
        DraftStore(baseDir: tempDir, index: DraftsIndexRepository(database.db));
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<MdDocumentSession> newSession(String text) async {
    final saf = _Saf(Uint8List.fromList(text.codeUnits));
    return MdDocumentSession(
      tab: DocumentTab(
        id: 't',
        fingerprint: 'fp',
        uri: 'u',
        displayName: 'notes.md',
        mimeType: 'text/markdown',
        lastActiveAt: 1,
      ),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
      autoSaveInterval: Duration.zero, // no periodic timer under testWidgets
    );
  }

  /// Pumps the split view at a given screen size. A wider-than-tall size is
  /// landscape, a taller-than-wide one is portrait.
  Future<MdDocumentSession> pumpSplit(
    WidgetTester tester, {
    required Size size,
    bool readOnly = false,
  }) async {
    late MdDocumentSession session;
    await tester.runAsync(() async {
      session = await newSession('# Title\n\nSome body text.');
      await session.load();
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await inMemoryKeyValueStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
        child: localizedApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: session,
              builder: (context, _) =>
                  MdLivePreview(session: session, readOnly: readOnly),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return session;
  }

  testWidgets('landscape puts the source and preview side by side',
      (tester) async {
    final session = await pumpSplit(tester, size: const Size(900, 500));
    expect(session.livePreview, isTrue);

    final divider = find.byKey(const Key('md-split-divider'));
    expect(divider, findsOneWidget);

    // Side by side: the divider is tall and narrow.
    final size = tester.getSize(divider);
    expect(size.width, lessThan(size.height));
    session.dispose();
  });

  testWidgets('portrait stacks the source above the preview', (tester) async {
    final session = await pumpSplit(tester, size: const Size(500, 900));

    final divider = find.byKey(const Key('md-split-divider'));
    expect(divider, findsOneWidget);

    // Stacked: the divider is wide and short.
    final size = tester.getSize(divider);
    expect(size.width, greaterThan(size.height));
    session.dispose();
  });

  testWidgets('turning the split off shows only the source', (tester) async {
    final session = await pumpSplit(tester, size: const Size(900, 500));
    session.toggleLivePreview();
    await tester.pump();

    expect(session.livePreview, isFalse);
    expect(find.byKey(const Key('md-split-divider')), findsNothing);
    session.dispose();
  });

  testWidgets('the split also works when the source is read-only',
      (tester) async {
    final session =
        await pumpSplit(tester, size: const Size(900, 500), readOnly: true);
    expect(find.byKey(const Key('md-split-divider')), findsOneWidget);
    session.dispose();
  });

  testWidgets('dragging the divider changes how much each pane gets',
      (tester) async {
    final session = await pumpSplit(tester, size: const Size(900, 500));
    final before = session.splitRatio;

    await tester.drag(
      find.byKey(const Key('md-split-divider')),
      const Offset(-150, 0),
    );
    await tester.pump();

    expect(session.splitRatio, lessThan(before));
    session.dispose();
  });

  testWidgets('the divider cannot be dragged past its limit', (tester) async {
    final session = await pumpSplit(tester, size: const Size(900, 500));

    await tester.drag(
      find.byKey(const Key('md-split-divider')),
      const Offset(-5000, 0),
    );
    await tester.pump();

    // Neither pane may disappear entirely.
    expect(session.splitRatio, greaterThanOrEqualTo(0.2));
    session.dispose();
  });
}
