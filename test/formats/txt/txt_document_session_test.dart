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
import 'package:text_data/formats/txt/txt_document_session.dart';
import 'package:text_data/shell/tabs/document_tab.dart';

import '../../support/test_support.dart';

/// A SAF fake that serves fixed bytes and captures overwrite writes so a save
/// round-trip can be inspected.
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
    tempDir = await Directory.systemTemp.createTemp('txt_session_test');
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

  DocumentTab tabFor(
    String uri, {
    String name = 'note.txt',
    TabViewMode viewMode = TabViewMode.view,
  }) => DocumentTab(
    id: 'tab-1',
    fingerprint: 'fp-1',
    uri: uri,
    displayName: name,
    mimeType: 'text/plain',
    viewMode: viewMode,
    lastActiveAt: 1,
  );

  test('loads and decodes a file into the editor', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('hello\nworld'.codeUnits)},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );

    await session.load();

    expect(session.status, TxtLoadStatus.ready);
    expect(session.code!.text, 'hello\nworld');
    expect(session.isWritable, isTrue);
    expect(session.isDirty, isFalse);
    expect(session.stats.words, 2);
    session.dispose();
  });

  test('uses the tab initial view mode', () async {
    final saf = RecordingSafService();
    final session = TxtDocumentSession(
      tab: tabFor('u', viewMode: TabViewMode.edit),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );

    expect(session.viewMode, TabViewMode.edit);
    session.dispose();
  });

  test('a read failure lands in the failed state, not a throw', () async {
    final saf = RecordingSafService(failRead: true);
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );

    await session.load();

    expect(session.status, TxtLoadStatus.failed);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });

  test('editing flips the dirty flag and reports it', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('abc'.codeUnits)},
      writableUris: {'u'},
    );
    bool? reported;
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
      onDirtyChanged: (d) => reported = d,
    );
    await session.load();

    session.code!.text = 'abcd';
    expect(session.isDirty, isTrue);
    expect(reported, isTrue);
    session.dispose();
  });

  test('save round-trips preserving encoding and CRLF line endings', () async {
    // Windows-1252 bytes with CRLF: "café\r\n" (é = 0xE9 in cp1252).
    final original = Uint8List.fromList([0x63, 0x61, 0x66, 0xE9, 0x0D, 0x0A]);
    final saf = RecordingSafService(
      contents: {'u': original},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();

    expect(session.encoding, TextEncodingType.windows1252);
    expect(session.lineEnding, LineEndingStyle.crlf);
    expect(session.code!.text, 'café\n'); // normalized in memory

    final result = await session.save();
    expect(result.outcome, SaveOutcome.saved);
    // The bytes written back match the original (same encoding + CRLF).
    expect(saf.lastWritten, original);
    expect(session.isDirty, isFalse);
    session.dispose();
  });

  test(
    'read-only file cannot overwrite; save reports it needs a copy',
    () async {
      final saf = RecordingSafService(
        contents: {'u': Uint8List.fromList('x'.codeUnits)},
        writableUris: const {}, // not writable
      );
      final session = TxtDocumentSession(
        tab: tabFor('u'),
        saf: saf,
        codec: const TextCodecService(),
        saver: const AtomicSaver(),
        metadata: MetadataService(saf),
        store: await inMemoryKeyValueStore(),
        draftStore: Future.value(draftStore),
        tempDir: Future.value(tempDir),
      );
      await session.load();

      expect(session.isWritable, isFalse);
      final result = await session.save();
      expect(result.outcome, SaveOutcome.readOnlyNeedsCopy);
      session.dispose();
    },
  );

  test('a waiting draft is offered and can be restored', () async {
    await draftStore.save('fp-1', 'recovered text');
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('on disk'.codeUnits)},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();

    expect(session.draftAvailable, isTrue);
    await session.restoreDraft();
    expect(session.code!.text, 'recovered text');
    expect(session.draftAvailable, isFalse);
    session.dispose();
  });

  test('jump-to-line moves the caret to that line', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('a\nb\nc\nd\ne'.codeUnits)},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();

    session.jumpToLine(3);
    expect(session.currentLine, 3);
    session.dispose();
  });

  test('restores the remembered reading position on load', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('a\nb\nc\nd\ne'.codeUnits)},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore({'txt.pos.fp-1': 2}),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();

    expect(session.currentLine, 2);
    session.dispose();
  });

  test('word-wrap and view-mode toggles flip their flags', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('abc'.codeUnits)},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();

    expect(session.wordWrap, isTrue);
    session.toggleWordWrap();
    expect(session.wordWrap, isFalse);

    expect(session.viewMode, TabViewMode.view);
    session.setViewMode(TabViewMode.edit);
    expect(session.viewMode, TabViewMode.edit);
    session.dispose();
  });

  test('changing the encoding re-decodes the same bytes', () async {
    // UTF-8 bytes for 'é'. Read as UTF-8 → 'é'; forced as Latin-1 → 'Ã©'.
    final bytes = Uint8List.fromList([0xC3, 0xA9]);
    final saf = RecordingSafService(
      contents: {'u': bytes},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: tabFor('u'),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
    );
    await session.load();

    expect(session.encoding, TextEncodingType.utf8);
    expect(session.code!.text, 'é');

    session.changeEncoding(TextEncodingType.latin1);
    expect(session.encoding, TextEncodingType.latin1);
    expect(session.code!.text, 'Ã©');
    expect(session.isDirty, isFalse);
    session.dispose();
  });
}
