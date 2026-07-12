import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/editor/atomic_saver.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/core/metadata/file_metadata.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/formats/csv/csv_document_session.dart';
import 'package:text_data/formats/csv/csv_grid.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late DraftStore draftStore;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('csv_grid_test');
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

  Future<CsvDocumentSession> newSession(String text) async {
    final saf = _Saf(Uint8List.fromList(text.codeUnits));
    return CsvDocumentSession(
      tab: DocumentTab(
        id: 't',
        fingerprint: 'fp',
        uri: 'u',
        displayName: 'data.csv',
        mimeType: 'text/csv',
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

  /// Builds and loads a session, then pumps the grid. The load does real DB I/O,
  /// so it runs via [WidgetTester.runAsync] (outside the fake-async zone).
  Future<CsvDocumentSession> pumpGrid(
    WidgetTester tester,
    String text,
  ) async {
    late CsvDocumentSession session;
    await tester.runAsync(() async {
      session = await newSession(text);
      await session.load();
    });
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 500,
            child: ListenableBuilder(
              listenable: session,
              builder: (context, _) =>
                  CsvGrid(session: session, editable: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('renders the header and cells of a sample grid', (tester) async {
    final session = await pumpGrid(tester, 'name,age\nAda,36\nBob,40');

    expect(find.text('name'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    session.dispose();
  });

  testWidgets('filtering hides non-matching rows', (tester) async {
    final session = await pumpGrid(tester, 'name,age\nAda,36\nBob,40\nCid,8');

    session.setFilterQuery('Bob');
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Ada'), findsNothing);
    expect(find.text('Cid'), findsNothing);
    session.dispose();
  });

  testWidgets('tapping a header sorts the column', (tester) async {
    final session = await pumpGrid(tester, 'name,age\nAda,36\nBob,40\nCid,8');

    await tester.tap(find.text('age'));
    await tester.pumpAndSettle();

    expect(session.sortColumn, 1);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    session.dispose();
  });

  testWidgets('raw toggle preserves the delimited content', (tester) async {
    final session = await pumpGrid(tester, 'name,age\nAda,36');

    session.setViewMode(CsvViewMode.raw);
    expect(session.currentText, 'name,age\nAda,36');
    session.dispose();
  });
}
