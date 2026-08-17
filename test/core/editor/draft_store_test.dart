import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/storage/app_database.dart';
import 'package:sreerajp_textapp/core/storage/drafts_index_repository.dart';

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

    // The timer that drives tick() throws the returned future away, so an error
    // escaping here would be an unhandled async error nobody ever sees while the
    // user keeps typing (CLAUDE.md §3.6).
    test('a failing write is reported, not thrown or swallowed', () async {
      final failing = _FailingDraftStore(store);
      final failures = <bool>[];
      final auto = AutoSaver(
        store: failing,
        fingerprint: '42-abc',
        getContent: () => 'work in progress',
        onFailingChanged: failures.add,
      );

      expect(await auto.tick(), isFalse); // did not write
      expect(auto.isFailing, isTrue);
      expect(failures, [true]); // the editor was told once
    });

    test('the next good tick clears the failure and writes', () async {
      const fp = '42-abc';
      final failing = _FailingDraftStore(store);
      final failures = <bool>[];
      var content = 'first';
      final auto = AutoSaver(
        store: failing,
        fingerprint: fp,
        getContent: () => content,
        onFailingChanged: failures.add,
      );

      await auto.tick();
      expect(auto.isFailing, isTrue);

      // The disk recovers. The same content must still be written — a failed
      // tick must not mark it as saved.
      failing.fail = false;
      expect(await auto.tick(), isTrue);
      expect(await store.load(fp), 'first');
      expect(auto.isFailing, isFalse);
      expect(failures, [true, false]);

      // And normal skipping still works afterwards.
      expect(await auto.tick(), isFalse);
      content = 'second';
      expect(await auto.tick(), isTrue);
      expect(await store.load(fp), 'second');
    });
  });
}

/// A [DraftStore] whose writes fail on demand, standing in for a full disk or a
/// broken drafts index.
class _FailingDraftStore implements DraftStore {
  final DraftStore _inner;
  bool fail = true;

  _FailingDraftStore(this._inner);

  @override
  Future<void> save(String fingerprint, String content) {
    if (fail) throw const FileSystemException('no space left on device');
    return _inner.save(fingerprint, content);
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not needed by these tests');
}
