import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/index/search_index_models.dart';
import 'package:text_data/core/index/search_index_repository.dart';
import 'package:text_data/core/storage/app_database.dart';

/// Builds a doc row for the tests.
IndexedDoc doc(
  String fingerprint, {
  String name = 'notes.txt',
  IndexFormat format = IndexFormat.txt,
  bool pinned = false,
  bool truncated = false,
}) => IndexedDoc(
  fingerprint: fingerprint,
  uri: 'content://$fingerprint',
  displayName: name,
  format: format,
  indexedAt: 1000,
  pinned: pinned,
  truncated: truncated,
);

void main() {
  // Run sqflite on the host with an in-memory database (no device needed).
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late SearchIndexRepository repo;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repo = SearchIndexRepository(
      database.db,
      ftsAvailable: database.ftsAvailable,
    );
  });

  tearDown(() => database.close());

  group('query handling', () {
    test('splits on anything that is not a letter, digit or underscore', () {
      expect(SearchIndexRepository.queryTerms('hello, world!'), [
        'hello',
        'world',
      ]);
      expect(SearchIndexRepository.queryTerms('a-b_c'), ['a', 'b_c']);
      expect(SearchIndexRepository.queryTerms('  '), isEmpty);
      expect(SearchIndexRepository.queryTerms('***'), isEmpty);
    });

    test('strips FTS operators so a query can never break the engine', () {
      expect(SearchIndexRepository.queryTerms('"quoted" NEAR/2 x^y'), [
        'quoted',
        'NEAR',
        '2',
        'x',
        'y',
      ]);
    });

    test('builds an AND match with a prefix on the last term', () {
      expect(
        SearchIndexRepository.buildMatchQuery(['red', 'ap']),
        '"red" AND "ap"*',
      );
      expect(SearchIndexRepository.buildMatchQuery(['one']), '"one"*');
    });

    test('an empty or punctuation-only query returns no results', () async {
      await repo.upsert(doc('a'), 'anything at all');
      expect(await repo.search(''), isEmpty);
      expect(await repo.search('   '), isEmpty);
      expect(await repo.search('...'), isEmpty);
    });
  });

  group('snippet spans', () {
    test('parses the markers into highlighted spans', () {
      const raw =
          'before ${SearchIndexRepository.highlightStart}hit'
          '${SearchIndexRepository.highlightEnd} after';
      expect(SearchIndexRepository.parseSnippet(raw), const [
        SnippetSpan('before '),
        SnippetSpan('hit', highlighted: true),
        SnippetSpan(' after'),
      ]);
    });

    test('an unbalanced marker still gives readable text', () {
      const raw = 'a ${SearchIndexRepository.highlightStart}b';
      final spans = SearchIndexRepository.parseSnippet(raw);
      expect(spans.map((s) => s.text).join(), 'a b');
    });

    test('the LIKE fallback builds a window around the match', () {
      final spans = SearchIndexRepository.buildSnippet(
        'the quick brown fox jumps over the lazy dog',
        ['brown'],
        before: 4,
        after: 4,
      );
      expect(spans.any((s) => s.highlighted && s.text == 'brown'), isTrue);
      expect(spans.first.text, '…');
    });
  });

  group('indexing and searching', () {
    test('a file can be found by a word inside it', () async {
      await repo.upsert(doc('a'), 'the quick brown fox');
      final hits = await repo.search('brown');
      expect(hits, hasLength(1));
      expect(hits.single.displayName, 'notes.txt');
      expect(hits.single.snippetText, contains('brown'));
      expect(hits.single.snippet.any((s) => s.highlighted), isTrue);
    });

    test('search matches a prefix while typing', () async {
      await repo.upsert(doc('a'), 'invoices for September');
      expect(await repo.search('invo'), hasLength(1));
    });

    test('all terms must be present', () async {
      await repo.upsert(doc('a'), 'alpha beta');
      await repo.upsert(doc('b', name: 'other.txt'), 'alpha gamma');
      final hits = await repo.search('alpha beta');
      expect(hits, hasLength(1));
      expect(hits.single.fingerprint, 'a');
    });

    test('re-indexing replaces the old text', () async {
      await repo.upsert(doc('a'), 'first version');
      await repo.upsert(doc('a'), 'second version');
      expect(await repo.search('first'), isEmpty);
      expect(await repo.search('second'), hasLength(1));
      expect(await repo.count(), 1);
    });

    test('the format filter limits the search', () async {
      await repo.upsert(doc('a', name: 'a.txt'), 'shared word');
      await repo.upsert(
        doc('b', name: 'b.csv', format: IndexFormat.csv),
        'shared word',
      );
      final csvOnly = await repo.search(
        'shared',
        formats: const {IndexFormat.csv},
      );
      expect(csvOnly, hasLength(1));
      expect(csvOnly.single.displayName, 'b.csv');
      expect(await repo.search('shared'), hasLength(2));
    });

    test('the limit caps how many results come back', () async {
      for (var i = 0; i < 5; i++) {
        await repo.upsert(doc('f$i', name: 'f$i.txt'), 'common text');
      }
      expect(await repo.search('common', limit: 2), hasLength(2));
    });

    test('a truncated file is reported as partly indexed', () async {
      await repo.upsert(doc('a', truncated: true), 'partial content');
      expect((await repo.search('partial')).single.truncated, isTrue);
    });
  });

  group('removing entries', () {
    test('remove drops the row and its body (delete trigger)', () async {
      await repo.upsert(doc('a'), 'find me');
      await repo.remove('a');
      expect(await repo.search('find'), isEmpty);
      expect(await repo.count(), 0);
      expect(await _bodyRows(database), 0);
    });

    test('removeUnpinned keeps favorites', () async {
      await repo.upsert(doc('a'), 'plain file');
      await repo.upsert(doc('b', name: 'fav.txt', pinned: true), 'kept file');
      await repo.removeUnpinned();
      expect(await repo.search('plain'), isEmpty);
      expect(await repo.search('kept'), hasLength(1));
    });

    test('setPinned protects a file from removeUnpinned', () async {
      await repo.upsert(doc('a'), 'plain file');
      await repo.setPinned('a', true);
      await repo.removeUnpinned();
      expect(await repo.search('plain'), hasLength(1));
    });

    test('clear empties the index and its bodies', () async {
      await repo.upsert(doc('a'), 'one');
      await repo.upsert(doc('b', name: 'b.txt', pinned: true), 'two');
      await repo.clear();
      expect(await repo.count(), 0);
      expect(await _bodyRows(database), 0);
    });

    test('indexedFingerprints lists what is already stored', () async {
      await repo.upsert(doc('a'), 'one');
      await repo.upsert(doc('b', name: 'b.txt'), 'two');
      expect(await repo.indexedFingerprints(), {'a', 'b'});
    });
  });

  group('LIKE fallback (SQLite without FTS5)', () {
    late SearchIndexRepository fallback;

    setUp(() async {
      // Build the fallback table by hand and drive the repository through the
      // non-FTS path, so the behaviour is covered even on a host that has FTS5.
      await database.db.execute(
        'CREATE TABLE IF NOT EXISTS search_body '
        '(doc_id INTEGER PRIMARY KEY, body TEXT NOT NULL)',
      );
      fallback = SearchIndexRepository(database.db, ftsAvailable: false);
    });

    test('finds a file and highlights the match', () async {
      await fallback.upsert(doc('a'), 'the quick brown fox');
      final hits = await fallback.search('brown');
      expect(hits, hasLength(1));
      expect(hits.single.snippet.any((s) => s.highlighted), isTrue);
    });

    test('all terms must be present, and filters still apply', () async {
      await fallback.upsert(doc('a'), 'alpha beta');
      await fallback.upsert(
        doc('b', name: 'b.csv', format: IndexFormat.csv),
        'alpha gamma',
      );
      expect(await fallback.search('alpha beta'), hasLength(1));
      expect(
        await fallback.search('alpha', formats: const {IndexFormat.csv}),
        hasLength(1),
      );
    });

    test('a percent sign in the query is not treated as a wildcard', () async {
      await fallback.upsert(doc('a'), 'plain text');
      // '%' is stripped by the sanitiser, so this searches for "ain".
      expect(await fallback.search('%ain%'), hasLength(1));
    });
  });

  group('migration', () {
    test('a v1 database upgrades to v2 with its rows intact', () async {
      final dir = await Directory.systemTemp.createTemp('textdata_migration');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/v1.db';
      // Build a v1 database with one recent row.
      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE recents (
                fingerprint     TEXT PRIMARY KEY,
                uri             TEXT NOT NULL,
                display_name    TEXT NOT NULL,
                mime_type       TEXT,
                size            INTEGER,
                last_opened_at  INTEGER NOT NULL,
                scroll_position INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await db.insert('recents', {
              'fingerprint': 'old',
              'uri': 'content://old',
              'display_name': 'old.txt',
              'last_opened_at': 1,
            });
          },
        ),
      );
      await v1.close();

      final upgraded = await AppDatabase.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      final rows = await upgraded.db.query('recents');
      expect(rows, hasLength(1));
      expect(rows.single['display_name'], 'old.txt');

      // The new index tables are usable straight after the upgrade.
      final upgradedRepo = SearchIndexRepository(
        upgraded.db,
        ftsAvailable: upgraded.ftsAvailable,
      );
      await upgradedRepo.upsert(doc('a'), 'after upgrade');
      expect(await upgradedRepo.search('upgrade'), hasLength(1));
      await upgraded.close();
    });
  });
}

/// How many body rows exist, whichever storage the database ended up using.
Future<int> _bodyRows(AppDatabase database) async {
  final table = database.ftsAvailable ? 'search_fts' : 'search_body';
  final rows = await database.db.rawQuery('SELECT COUNT(*) AS c FROM $table');
  return (rows.first['c'] as num?)?.toInt() ?? 0;
}
