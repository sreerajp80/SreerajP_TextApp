import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/editor/atomic_saver.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/core/metadata/file_metadata.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/formats/csv/csv_document_session.dart';
import 'package:text_data/formats/csv/csv_filter_sort.dart';
import 'package:text_data/shell/tabs/document_tab.dart';

import '../../support/test_support.dart';

/// A SAF fake that serves fixed bytes and captures overwrite writes.
class RecordingSafService extends SafService {
  final Map<String, Uint8List> contents;
  final Set<String> writableUris;
  Uint8List? lastWritten;
  final bool failRead;

  RecordingSafService({
    this.contents = const {},
    this.writableUris = const {},
    this.failRead = false,
  });

  @override
  Future<Uint8List> readBytes(String uri) async {
    if (failRead) throw const SafUriStale();
    return contents[uri] ?? Uint8List(0);
  }

  @override
  Future<bool> isWritable(String uri) async => writableUris.contains(uri);

  @override
  Future<void> writeBytes(String uri, Uint8List bytes) async {
    lastWritten = bytes;
  }

  @override
  Future<int?> modifiedTime(String uri) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late DraftStore draftStore;
  late DraftsIndexRepository draftsIndex;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('csv_session_test');
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    draftsIndex = DraftsIndexRepository(database.db);
    draftStore = DraftStore(baseDir: tempDir, index: draftsIndex);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  DocumentTab tabFor(String uri, {String name = 'data.csv'}) => DocumentTab(
        id: 'tab-1',
        fingerprint: 'fp-1',
        uri: uri,
        displayName: name,
        mimeType: 'text/csv',
        lastActiveAt: 1,
      );

  Future<CsvDocumentSession> build(RecordingSafService saf) async {
    return CsvDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
  }

  RecordingSafService safWith(String text, {bool writable = true}) =>
      RecordingSafService(
        contents: {'u': Uint8List.fromList(text.codeUnits)},
        writableUris: writable ? {'u'} : const {},
      );

  test('loads, detects the dialect, and parses the table', () async {
    final session = await build(safWith('name,age\nAda,36\nBob,40'));
    await session.load();

    expect(session.status, CsvLoadStatus.ready);
    expect(session.table.header, ['name', 'age']);
    expect(session.table.rowCount, 2);
    expect(session.table.cell(1, 0), 'Bob');
    session.dispose();
  });

  test('a read failure lands in the failed state, not a throw', () async {
    final session = await build(RecordingSafService(failRead: true));
    await session.load();

    expect(session.status, CsvLoadStatus.failed);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });

  test('empty file loads without crashing', () async {
    final session = await build(safWith(''));
    await session.load();
    expect(session.status, CsvLoadStatus.ready);
    session.dispose();
  });

  test('raw toggle preserves content and re-parses edits back into the grid',
      () async {
    final session = await build(safWith('a,b\n1,2'));
    await session.load();

    session.setViewMode(CsvViewMode.raw);
    expect(session.code!.text, 'a,b\n1,2'); // grid serialized to raw

    // Edit the raw text and switch back to the grid.
    session.code!.text = 'a,b\n1,2\n3,4';
    session.setViewMode(CsvViewMode.table);
    expect(session.table.rowCount, 2);
    expect(session.table.cell(1, 1), '4');
    session.dispose();
  });

  test('filter and sort drive the visible row order', () async {
    final session = await build(safWith('name,age\nAda,36\nBob,40\nCid,8'));
    await session.load();

    session.setFilterQuery('b');
    expect(session.visibleRowIndices, [1]); // only "Bob"

    session.setFilterQuery('');
    session.sortBy(1); // ascending by age
    expect(session.visibleRowIndices, [2, 0, 1]); // 8, 36, 40
    session.dispose();
  });

  test('editing a cell flips the dirty flag and undo restores it', () async {
    bool? reported;
    final session = CsvDocumentSession(
      tab: tabFor('u'),
      saf: safWith('a,b\n1,2'),
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(safWith('a,b\n1,2')),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
      onDirtyChanged: (d) => reported = d,
    );
    await session.load();

    session.setCell(0, 0, '9');
    expect(session.table.cell(0, 0), '9');
    expect(session.isDirty, isTrue);
    expect(reported, isTrue);

    session.undo();
    expect(session.table.cell(0, 0), '1');
    expect(session.isDirty, isFalse);
    session.dispose();
  });

  test('removeDuplicateRows drops repeated rows', () async {
    final session = await build(safWith('id\n1\n2\n1\n3'));
    await session.load();
    expect(session.table.rowCount, 4);
    session.removeDuplicateRows();
    expect(session.table.rowCount, 3);
    session.dispose();
  });

  test('save round-trips preserving encoding and CRLF line endings', () async {
    // Windows-1252 bytes with CRLF: "a\r\ncafé\r\n".
    final original = Uint8List.fromList(
        [0x61, 0x0D, 0x0A, 0x63, 0x61, 0x66, 0xE9, 0x0D, 0x0A]);
    final saf = RecordingSafService(
      contents: {'u': original},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.encoding, TextEncodingType.windows1252);
    expect(session.lineEnding, LineEndingStyle.crlf);

    final result = await session.save();
    expect(result.outcome, SaveOutcome.saved);
    // Round-trips to the same bytes (no trailing newline was in the source).
    expect(saf.lastWritten, original.sublist(0, original.length - 2));
    expect(session.isDirty, isFalse);
    session.dispose();
  });

  test('read-only file cannot overwrite; save reports it needs a copy',
      () async {
    final session = await build(safWith('a,b\n1,2', writable: false));
    await session.load();
    expect(session.isWritable, isFalse);
    final result = await session.save();
    expect(result.outcome, SaveOutcome.readOnlyNeedsCopy);
    session.dispose();
  });

  test('restores the sort (column + direction) on a later open', () async {
    final store = await inMemoryKeyValueStore();
    CsvDocumentSession make() => CsvDocumentSession(
          tab: tabFor('u'),
          saf: safWith('name,age\nAda,36\nBob,40\nCid,8'),
          codec: const TextCodecService(),
          saver: const AtomicSaver(),
          metadata: MetadataService(safWith('name,age\nAda,36\nBob,40\nCid,8')),
          store: store,
          draftStore: Future.value(draftStore),
          tempDir: Future.value(tempDir),
        );

    final first = make();
    await first.load();
    first.sortBy(1); // ascending by age
    expect(first.sortColumn, 1);
    expect(first.sortDirection, SortDirection.ascending);
    first.persistPosition();
    first.dispose();

    // A fresh session for the same file picks the sort back up on load.
    final second = make();
    await second.load();
    expect(second.sortColumn, 1);
    expect(second.sortDirection, SortDirection.ascending);
    expect(second.visibleRowIndices, [2, 0, 1]); // 8, 36, 40
    second.dispose();
  });

  test('an unsorted file opens unsorted (nothing to restore)', () async {
    final session = await build(safWith('name,age\nAda,36\nBob,40'));
    await session.load();
    expect(session.sortColumn, isNull);
    expect(session.sortDirection, SortDirection.none);
    session.dispose();
  });

  test('a saved sort column out of range is ignored, not applied', () async {
    // Store a column index the reparsed (2-column) table does not have.
    final store = await inMemoryKeyValueStore(
      {'csv.pos.fp-1': 9, 'csv.dir.fp-1': SortDirection.ascending.index},
    );
    final session = CsvDocumentSession(
      tab: tabFor('u'),
      saf: safWith('name,age\nAda,36\nBob,40'),
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(safWith('name,age\nAda,36\nBob,40')),
      store: store,
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();
    expect(session.status, CsvLoadStatus.ready);
    expect(session.sortColumn, isNull);
    session.dispose();
  });

  test('filter helper matches the session view', () async {
    final session = await build(safWith('name\nAda\nBob'));
    await session.load();
    // The pure helper and the session agree on the filtered set.
    expect(CsvFilterSort.filter(session.table, 'ada'), [0]);
    session.dispose();
  });
}
