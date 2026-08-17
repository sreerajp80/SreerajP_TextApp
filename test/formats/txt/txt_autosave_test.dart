import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sreerajp_textapp/core/editor/atomic_saver.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/editor/encoding.dart';
import 'package:sreerajp_textapp/core/metadata/file_metadata.dart';
import 'package:sreerajp_textapp/core/storage/app_database.dart';
import 'package:sreerajp_textapp/core/storage/drafts_index_repository.dart';
import 'package:sreerajp_textapp/formats/txt/txt_document_session.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';

import '../../support/test_support.dart';
import 'txt_document_session_test.dart' show RecordingSafService;

/// Auto-save gaps found while giving the editor a way out of edit mode:
/// flushing the draft when the app is about to be killed, and following a
/// changed interval on a tab that is already open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late DraftStore draftStore;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('txt_autosave_test');
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

  const fingerprint = 'fp-auto';

  Future<TxtDocumentSession> openSession({
    Duration autoSaveInterval = const Duration(seconds: 5),
  }) async {
    final saf = RecordingSafService(
      contents: {'u': Uint8List.fromList('on disk'.codeUnits)},
      writableUris: {'u'},
    );
    final session = TxtDocumentSession(
      tab: const DocumentTab(
        id: 'tab-1',
        fingerprint: fingerprint,
        uri: 'u',
        displayName: 'note.txt',
        mimeType: 'text/plain',
        lastActiveAt: 1,
      ),
      saf: saf,
      codec: const TextCodecService(),
      saver: const AtomicSaver(),
      metadata: MetadataService(saf),
      store: await inMemoryKeyValueStore(),
      draftStore: Future.value(draftStore),
      tempDir: Future.value(tempDir),
      autoSaveInterval: autoSaveInterval,
    );
    await session.load();
    addTearDown(session.dispose);
    return session;
  }

  group('flushDraft', () {
    // Android can kill a paused app at any moment. Without this the user loses
    // everything typed since the last tick (CLAUDE.md §3.6).
    test('writes the draft immediately, without waiting for a tick', () async {
      final session = await openSession();
      session.code!.text = 'typed but not saved';

      expect(await draftStore.hasDraft(fingerprint), isFalse);
      await session.flushDraft();

      expect(await draftStore.load(fingerprint), 'typed but not saved');
    });

    test('writes nothing when auto-save is switched off', () async {
      final session = await openSession(autoSaveInterval: Duration.zero);
      session.code!.text = 'typed but not saved';

      await session.flushDraft();

      expect(await draftStore.hasDraft(fingerprint), isFalse);
    });

    test('is a no-op when the text has not changed', () async {
      final session = await openSession();

      await session.flushDraft();

      // Nothing was typed, so there is nothing worth a disk write.
      expect(await draftStore.hasDraft(fingerprint), isFalse);
    });
  });

  group('setAutoSaveInterval', () {
    test('turning auto-save off stops protecting an open tab', () async {
      final session = await openSession();
      session.setAutoSaveInterval(Duration.zero);

      expect(session.autoSaveInterval, Duration.zero);
      session.code!.text = 'typed after switching off';
      await session.flushDraft();
      expect(await draftStore.hasDraft(fingerprint), isFalse);
    });

    test('turning auto-save on starts protecting an open tab', () async {
      final session = await openSession(autoSaveInterval: Duration.zero);
      session.setAutoSaveInterval(const Duration(seconds: 2));

      expect(session.autoSaveInterval, const Duration(seconds: 2));
      session.code!.text = 'typed after switching on';
      await session.flushDraft();
      expect(await draftStore.load(fingerprint), 'typed after switching on');
    });

    test('setting the same interval changes nothing', () async {
      final session = await openSession();
      session.setAutoSaveInterval(const Duration(seconds: 5));

      session.code!.text = 'still protected';
      await session.flushDraft();
      expect(await draftStore.load(fingerprint), 'still protected');
    });
  });
}
