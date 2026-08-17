import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sreerajp_textapp/core/editor/atomic_saver.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/editor/encoding.dart';
import 'package:sreerajp_textapp/core/metadata/file_metadata.dart';
import 'package:sreerajp_textapp/core/storage/app_database.dart';
import 'package:sreerajp_textapp/core/storage/drafts_index_repository.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/formats/markdown/md_document_session.dart';
import 'package:sreerajp_textapp/formats/markdown/md_front_matter_form.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';

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

/// Guards the YAML front-matter form editor (roadmap §4.4.3). The behaviour
/// that matters most is that applying the form does not throw away parts of the
/// file the small YAML parser does not understand.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late DraftStore draftStore;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('md_fm_form_test');
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    draftStore = DraftStore(
      baseDir: tempDir,
      index: DraftsIndexRepository(database.db),
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<MdDocumentSession> newSession(String text) async {
    final saf = _Saf(Uint8List.fromList(text.codeUnits));
    return MdDocumentSession(
      tab: const DocumentTab(
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

  /// Loads a document and opens the front-matter form over it.
  Future<MdDocumentSession> openForm(
    WidgetTester tester,
    String source, {
    bool readOnly = false,
  }) async {
    late MdDocumentSession session;
    await tester.runAsync(() async {
      session = await newSession(source);
      await session.load();
    });
    final store = await inMemoryKeyValueStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
        child: localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showMdFrontMatterForm(context, session, readOnly: readOnly),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('shows a field per front-matter entry', (tester) async {
    final session = await openForm(
      tester,
      '---\ntitle: T\nauthor: Jane\n---\n# Body',
    );

    expect(find.byKey(const Key('md-front-matter-title')), findsOneWidget);
    expect(find.byKey(const Key('md-front-matter-author')), findsOneWidget);
    session.dispose();
  });

  testWidgets('editing a field writes it back to the document', (tester) async {
    final session = await openForm(tester, '---\ntitle: Old\n---\n# Body');

    await tester.enterText(
      find.byKey(const Key('md-front-matter-title')),
      'New',
    );
    await tester.tap(find.byKey(const Key('md-front-matter-save')));
    await tester.pumpAndSettle();

    expect(session.code!.text, '---\ntitle: New\n---\n# Body');
    expect(session.isDirty, isTrue);
    session.dispose();
  });

  testWidgets('an edit keeps YAML the form does not show', (tester) async {
    const source =
        '---\n'
        '# a note\n'
        'title: Old\n'
        'nested:\n'
        '  deep: 1\n'
        '---\n'
        '# Body';
    final session = await openForm(tester, source);

    await tester.enterText(
      find.byKey(const Key('md-front-matter-title')),
      'New',
    );
    await tester.tap(find.byKey(const Key('md-front-matter-save')));
    await tester.pumpAndSettle();

    final result = session.code!.text;
    expect(result.contains('# a note'), isTrue);
    expect(result.contains('  deep: 1'), isTrue);
    expect(result.contains('title: New'), isTrue);
    session.dispose();
  });

  testWidgets('tags are shown as chips and one can be removed', (tester) async {
    final session = await openForm(
      tester,
      '---\ntags: [draft, ideas]\n---\n# Body',
    );

    expect(find.widgetWithText(InputChip, 'draft'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'ideas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('md-front-matter-tag-remove-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('md-front-matter-save')));
    await tester.pumpAndSettle();

    expect(session.code!.text.contains('draft'), isFalse);
    expect(session.code!.text.contains('ideas'), isTrue);
    session.dispose();
  });

  testWidgets('a file with no front matter offers the common fields', (
    tester,
  ) async {
    final session = await openForm(tester, '# Just a body');

    expect(find.byKey(const Key('md-front-matter-title')), findsOneWidget);
    expect(find.byKey(const Key('md-front-matter-date')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('md-front-matter-title')),
      'Fresh',
    );
    await tester.tap(find.byKey(const Key('md-front-matter-save')));
    await tester.pumpAndSettle();

    expect(session.code!.text, '---\ntitle: Fresh\n---\n# Just a body');
    session.dispose();
  });

  testWidgets('changing nothing leaves the document alone', (tester) async {
    const source = '---\ntitle: T\n---\n# Body';
    final session = await openForm(tester, source);

    await tester.tap(find.byKey(const Key('md-front-matter-save')));
    await tester.pumpAndSettle();

    expect(session.code!.text, source);
    expect(session.isDirty, isFalse);
    session.dispose();
  });

  testWidgets('a read-only tab gets no save button', (tester) async {
    final session = await openForm(
      tester,
      '---\ntitle: T\n---\n# Body',
      readOnly: true,
    );

    expect(find.byKey(const Key('md-front-matter-save')), findsNothing);
    expect(find.byKey(const Key('md-front-matter-add')), findsNothing);
    session.dispose();
  });
}
