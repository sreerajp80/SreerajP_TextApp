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
import 'package:text_data/formats/json/json_document_session.dart';
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
    tempDir = await Directory.systemTemp.createTemp('json_session_test');
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

  DocumentTab tabFor(String uri, {String name = 'data.json'}) => DocumentTab(
        id: 'tab-1',
        fingerprint: 'fp-1',
        uri: uri,
        displayName: name,
        mimeType: 'application/json',
        lastActiveAt: 1,
      );

  Future<JsonDocumentSession> build(
    RecordingSafService saf, {
    Map<String, Object> prefs = const {},
  }) async {
    return JsonDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(prefs),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
  }

  test('loads, decodes, and parses the document', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{"a": 1, "b": [2, 3]}'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.status, JsonLoadStatus.ready);
    expect(session.isWellFormed, isTrue);
    expect(session.root!.children.length, 2);
    expect(session.stats!.keyCount, 2);
    session.dispose();
  });

  test('a read failure lands in the failed state, not a throw', () async {
    final saf = RecordingSafService(failRead: true);
    final session = await build(saf);
    await session.load();

    expect(session.status, JsonLoadStatus.failed);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });

  test('a broken document opens ready but is marked not well-formed', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{"a": }'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.status, JsonLoadStatus.ready);
    expect(session.isWellFormed, isFalse);
    expect(session.validationLine, isNotNull);
    session.dispose();
  });

  test('save round-trips preserving encoding and CRLF line endings', () async {
    // Windows-1252 bytes with CRLF inside a JSON string: {"s":"café"}\r\n
    final original = Uint8List.fromList([
      0x7B, 0x22, 0x73, 0x22, 0x3A, 0x22, // {"s":"
      0x63, 0x61, 0x66, 0xE9, // café (é = 0xE9 in Windows-1252)
      0x22, 0x7D, 0x0D, 0x0A, // "}\r\n
    ]);
    final saf = RecordingSafService(
      contents: {'u': original},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.encoding, TextEncodingType.windows1252);
    expect(session.lineEnding, LineEndingStyle.crlf);
    expect(session.isWellFormed, isTrue);

    final result = await session.save();
    expect(result.outcome, SaveOutcome.saved);
    expect(saf.lastWritten, original);
    expect(session.isDirty, isFalse);
    session.dispose();
  });

  test('the gate blocks an invalid overwrite', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{"a": 1}'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    // Break the JSON in the buffer.
    session.code!.text = '{"a": }';
    final result = await session.save();
    expect(result.outcome, SaveOutcome.blockedByGate);
    expect(result.message, isNotNull);
    expect(saf.lastWritten, isNull); // nothing was written
    session.dispose();
  });

  test('JSONC is read leniently and can be made strict, then saved', () async {
    const jsonc = '{\n  // a comment\n  "a": 1,\n}';
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList(jsonc.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    // Read leniently: shows a tree but is not strict yet.
    expect(session.root, isNotNull);
    expect(session.lenientOnly, isTrue);
    expect(session.isWellFormed, isFalse);

    // "Make strict" drops comments / trailing commas.
    session.formatDocument();
    expect(session.isWellFormed, isTrue);
    expect(session.lenientOnly, isFalse);

    final result = await session.save();
    expect(result.outcome, SaveOutcome.saved);
    // The saved bytes are strict JSON (no comment).
    expect(String.fromCharCodes(saf.lastWritten!).contains('//'), isFalse);
    session.dispose();
  });

  test('read-only file cannot overwrite; save reports it needs a copy',
      () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{"a": 1}'.codeUnits)},
      writableUris: const {},
    );
    final session = await build(saf);
    await session.load();

    expect(session.isWritable, isFalse);
    final result = await session.save();
    expect(result.outcome, SaveOutcome.readOnlyNeedsCopy);
    session.dispose();
  });

  test('NDJSON is detected and shown as a record list', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{"a":1}\n{"a":2}\n{"a":3}'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.isNdjson, isTrue);
    expect(session.ndjsonCount, 3);
    expect(session.root!.children.length, 3);
    session.dispose();
  });

  test('minify and format rewrite the buffer', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{ "a" : 1 }'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    session.minifyDocument();
    expect(session.code!.text, '{"a":1}');
    session.setIndent(JsonIndent.twoSpaces);
    session.formatDocument();
    expect(session.code!.text, '{\n  "a": 1\n}');
    session.dispose();
  });

  test('a waiting draft is offered and can be restored', () async {
    await draftStore.save('fp-1', '{"draft": true}');
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('{"a": 1}'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.draftAvailable, isTrue);
    await session.restoreDraft();
    expect(session.code!.text, '{"draft": true}');
    expect(session.mode, JsonViewMode.edit);
    session.dispose();
  });

  test('empty file loads without crashing', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List(0)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.status, JsonLoadStatus.ready);
    expect(session.isWellFormed, isFalse);
    session.dispose();
  });
}
