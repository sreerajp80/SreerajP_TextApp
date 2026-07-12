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
import 'package:text_data/formats/markdown/md_document_session.dart';
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
    tempDir = await Directory.systemTemp.createTemp('md_session_test');
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

  DocumentTab tabFor(String uri, {String name = 'note.md'}) => DocumentTab(
        id: 'tab-1',
        fingerprint: 'fp-1',
        uri: uri,
        displayName: name,
        mimeType: 'text/markdown',
        lastActiveAt: 1,
      );

  Future<MdDocumentSession> build(
    RecordingSafService saf, {
    Map<String, Object> prefs = const {},
  }) async {
    return MdDocumentSession(
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
      contents: {
        'u': Uint8List.fromList('# Title\n\nHello [x](https://x.com)'.codeUnits),
      },
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.status, MdLoadStatus.ready);
    expect(session.stats.headings, 1);
    expect(session.stats.links, 1);
    expect(session.toc.headings.first.text, 'Title');
    session.dispose();
  });

  test('a read failure lands in the failed state, not a throw', () async {
    final saf = RecordingSafService(failRead: true);
    final session = await build(saf);
    await session.load();

    expect(session.status, MdLoadStatus.failed);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });

  test('front matter is parsed and stripped from the rendered body', () async {
    final saf = RecordingSafService(
      contents: {
        'u': Uint8List.fromList(
          '---\ntitle: My Doc\nauthor: Jane\n---\n# Heading'.codeUnits,
        ),
      },
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.frontMatter.present, isTrue);
    expect(session.frontMatter.title, 'My Doc');
    expect(session.frontMatter.author, 'Jane');
    // Only the heading is counted; the front matter is not part of the body.
    expect(session.stats.headings, 1);
    session.dispose();
  });

  test('editing flips the dirty flag and reports it', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('# a'.codeUnits)},
      writableUris: {'u'},
    );
    bool? reported;
    final session = MdDocumentSession(
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

    session.code!.text = '# ab';
    expect(session.isDirty, isTrue);
    expect(reported, isTrue);
    session.dispose();
  });

  test('save round-trips preserving encoding and CRLF line endings', () async {
    // Windows-1252 bytes with CRLF: "café\r\n".
    final original = Uint8List.fromList([0x63, 0x61, 0x66, 0xE9, 0x0D, 0x0A]);
    final saf = RecordingSafService(
      contents: {'u': original},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.encoding, TextEncodingType.windows1252);
    expect(session.lineEnding, LineEndingStyle.crlf);
    expect(session.code!.text, 'café\n');

    final result = await session.save();
    expect(result.outcome, SaveOutcome.saved);
    expect(saf.lastWritten, original);
    expect(session.isDirty, isFalse);
    session.dispose();
  });

  test('read-only file cannot overwrite; save reports it needs a copy',
      () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('# x'.codeUnits)},
      writableUris: const {},
    );
    final session = await build(saf);
    await session.load();

    expect(session.isWritable, isFalse);
    final result = await session.save();
    expect(result.outcome, SaveOutcome.readOnlyNeedsCopy);
    session.dispose();
  });

  test('a waiting draft is offered and can be restored', () async {
    await draftStore.save('fp-1', '# recovered');
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('# on disk'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.draftAvailable, isTrue);
    await session.restoreDraft();
    expect(session.code!.text, '# recovered');
    expect(session.mode, MdMode.edit);
    session.dispose();
  });

  test('empty file loads without crashing', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List(0)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.status, MdLoadStatus.ready);
    expect(session.stats.headings, 0);
    session.dispose();
  });

  test('mode toggles between rendered, raw, and edit', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('# a'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    expect(session.mode, MdMode.rendered);
    session.setMode(MdMode.raw);
    expect(session.mode, MdMode.raw);
    session.setMode(MdMode.edit);
    expect(session.isEditing, isTrue);
    session.dispose();
  });

  test('applyEdit replaces text and restores a multi-line selection', () async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('one\ntwo\nthree'.codeUnits)},
      writableUris: {'u'},
    );
    final session = await build(saf);
    await session.load();

    // Bold the word "two" (chars 4..7 in "one\ntwo\nthree").
    session.applyEdit('one\n**two**\nthree', 6, 9);
    expect(session.code!.text, 'one\n**two**\nthree');
    final (start, end) = session.selectionRange;
    expect(session.code!.text.substring(start, end), 'two');
    session.dispose();
  });
}
