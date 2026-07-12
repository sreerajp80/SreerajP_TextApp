import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/storage/app_database.dart';
import 'package:text_data/core/storage/drafts_index_repository.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late Directory tempDir;
  late DraftStore store;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    tempDir = await Directory.systemTemp.createTemp('draft_store_test');
    store = DraftStore(
      baseDir: tempDir,
      index: DraftsIndexRepository(database.db),
      now: () => 1234,
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('a kill mid-edit is recovered on the next open', () async {
    const fp = '42-abc';
    // The editor auto-saved a draft but the app was killed before a real save.
    await store.save(fp, 'work in progress');

    // "Next open": the draft surfaces.
    expect(await store.hasDraft(fp), isTrue);
    expect(await store.load(fp), 'work in progress');
  });

  test('a real save clears the draft', () async {
    const fp = '42-abc';
    await store.save(fp, 'draft text');
    expect(await store.hasDraft(fp), isTrue);

    // After a real save the editor discards the draft.
    await store.discard(fp);
    expect(await store.hasDraft(fp), isFalse);
    expect(await store.load(fp), isNull);
  });

  test('save overwrites an earlier draft', () async {
    const fp = '42-abc';
    await store.save(fp, 'first');
    await store.save(fp, 'second');
    expect(await store.load(fp), 'second');
  });

  test('no draft returns null without throwing', () async {
    expect(await store.load('99-none'), isNull);
    expect(await store.hasDraft('99-none'), isFalse);
  });

  test('a stale index pointer (missing file) is cleaned up', () async {
    const fp = '42-abc';
    await store.save(fp, 'text');
    // Simulate the draft file vanishing under us.
    final entry = await DraftsIndexRepository(database.db).byFingerprint(fp);
    await File(entry!.draftPath).delete();

    expect(await store.load(fp), isNull);
    // The stale pointer is gone too.
    expect(await store.hasDraft(fp), isFalse);
  });

  group('AutoSaver', () {
    test('tick saves only when content changed', () async {
      const fp = '42-abc';
      var content = 'a';
      final auto = AutoSaver(
        store: store,
        fingerprint: fp,
        getContent: () => content,
      );

      expect(await auto.tick(), isTrue); // first write
      expect(await auto.tick(), isFalse); // unchanged → skip
      content = 'ab';
      expect(await auto.tick(), isTrue); // changed → write
      expect(await store.load(fp), 'ab');
    });
  });
}
