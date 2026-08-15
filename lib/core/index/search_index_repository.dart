import 'package:sqflite/sqflite.dart';

import 'package:text_data/core/index/search_index_models.dart';

/// Reads and writes the workspace-wide search index (Feature 11).
///
/// The index has two parts: `search_docs` (one metadata row per file) and the
/// document body, held either in the FTS5 table `search_fts` or — on a SQLite
/// build without FTS5 — in the plain `search_body` table searched with `LIKE`.
/// Both paths return the same [SearchHit] list, so the UI never has to care
/// which one is in use.
///
/// Nothing here logs file text (security-rules: never log document content).
class SearchIndexRepository {
  /// Marks the FTS5 `snippet()` call puts around a match. They are control
  /// characters, so they can never appear in normal document text; the UI turns
  /// them into highlighted spans and never shows them.
  static const String highlightStart = '\u0002';
  static const String highlightEnd = '\u0003';

  /// How many results one search returns by default.
  static const int defaultLimit = 100;

  final Database _db;

  /// Whether the FTS5 path is in use. False means the `LIKE` fallback.
  final bool ftsAvailable;

  const SearchIndexRepository(this._db, {required this.ftsAvailable});

  // --- writing -------------------------------------------------------------

  /// Inserts or replaces the index entry for [doc] with [body] as its text.
  Future<void> upsert(IndexedDoc doc, String body) async {
    await _db.transaction((txn) async {
      final existing = await txn.query(
        'search_docs',
        columns: ['id'],
        where: 'fingerprint = ?',
        whereArgs: [doc.fingerprint],
        limit: 1,
      );
      int docId;
      if (existing.isEmpty) {
        docId = await txn.insert('search_docs', doc.toRow());
      } else {
        docId = (existing.first['id'] as num).toInt();
        final row = doc.toRow()..remove('id');
        await txn.update(
          'search_docs',
          row,
          where: 'id = ?',
          whereArgs: [docId],
        );
      }
      await _writeBody(txn, docId, body);
    });
  }

  Future<void> _writeBody(DatabaseExecutor txn, int docId, String body) async {
    if (ftsAvailable) {
      await txn.delete('search_fts', where: 'rowid = ?', whereArgs: [docId]);
      await txn.insert('search_fts', {'rowid': docId, 'body': body});
    } else {
      await txn.insert('search_body', {
        'doc_id': docId,
        'body': body,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Marks a file as a favorite (or not). A pinned file survives "clear recent
  /// files", because the user still keeps it on the favorites list.
  Future<void> setPinned(String fingerprint, bool pinned) async {
    await _db.update(
      'search_docs',
      {'pinned': pinned ? 1 : 0},
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }

  /// Drops one file from the index. The delete trigger removes its body too.
  Future<void> remove(String fingerprint) async {
    await _db.delete(
      'search_docs',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }

  /// Drops every entry that is not pinned (used when recents are cleared).
  Future<void> removeUnpinned() async {
    await _db.delete('search_docs', where: 'pinned = 0');
  }

  /// Empties the whole index (Settings › clear index).
  Future<void> clear() async {
    await _db.delete('search_docs');
  }

  // --- reading -------------------------------------------------------------

  Future<IndexedDoc?> byFingerprint(String fingerprint) async {
    final rows = await _db.query(
      'search_docs',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IndexedDoc.fromRow(rows.first);
  }

  /// The fingerprints already in the index. Used by the backfill so it never
  /// re-reads a file it has seen.
  Future<Set<String>> indexedFingerprints() async {
    final rows = await _db.query('search_docs', columns: ['fingerprint']);
    return rows.map((r) => r['fingerprint'] as String).toSet();
  }

  /// How many files are indexed (shown in Settings).
  Future<int> count() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS c FROM search_docs');
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  /// Searches every indexed file for [query].
  ///
  /// [formats] limits the search to those formats (empty means all). Returns an
  /// empty list when the query has nothing searchable in it.
  Future<List<SearchHit>> search(
    String query, {
    Set<IndexFormat> formats = const {},
    int limit = defaultLimit,
  }) async {
    final terms = queryTerms(query);
    if (terms.isEmpty) return const [];
    return ftsAvailable
        ? _searchFts(terms, formats, limit)
        : _searchLike(terms, formats, limit);
  }

  Future<List<SearchHit>> _searchFts(
    List<String> terms,
    Set<IndexFormat> formats,
    int limit,
  ) async {
    final match = buildMatchQuery(terms);
    final args = <Object?>[match, ...formats.map((f) => f.id), limit];
    final rows = await _db.rawQuery('''
      SELECT search_docs.fingerprint    AS fingerprint,
             search_docs.uri            AS uri,
             search_docs.display_name   AS display_name,
             search_docs.format         AS format,
             search_docs.truncated      AS truncated,
             snippet(search_fts, 0, char(2), char(3), '…', 14) AS snip
      FROM search_fts
      JOIN search_docs ON search_docs.id = search_fts.rowid
      WHERE search_fts MATCH ?${_formatFilter(formats)}
      ORDER BY bm25(search_fts)
      LIMIT ?
    ''', args);
    return rows
        .map((row) => _hit(row, parseSnippet((row['snip'] as String?) ?? '')))
        .toList(growable: false);
  }

  Future<List<SearchHit>> _searchLike(
    List<String> terms,
    Set<IndexFormat> formats,
    int limit,
  ) async {
    final where = terms
        .map((_) => "search_body.body LIKE ? ESCAPE '\\'")
        .join(' AND ');
    final args = <Object?>[
      ...terms.map((t) => '%${_escapeLike(t)}%'),
      ...formats.map((f) => f.id),
      limit,
    ];
    final rows = await _db.rawQuery('''
      SELECT search_docs.fingerprint  AS fingerprint,
             search_docs.uri          AS uri,
             search_docs.display_name AS display_name,
             search_docs.format       AS format,
             search_docs.truncated    AS truncated,
             search_body.body         AS body
      FROM search_body
      JOIN search_docs ON search_docs.id = search_body.doc_id
      WHERE $where${_formatFilter(formats)}
      ORDER BY search_docs.indexed_at DESC
      LIMIT ?
    ''', args);
    return rows
        .map(
          (row) =>
              _hit(row, buildSnippet((row['body'] as String?) ?? '', terms)),
        )
        .toList(growable: false);
  }

  String _formatFilter(Set<IndexFormat> formats) {
    if (formats.isEmpty) return '';
    final marks = List.filled(formats.length, '?').join(', ');
    return ' AND search_docs.format IN ($marks)';
  }

  SearchHit _hit(Map<String, Object?> row, List<SnippetSpan> snippet) {
    return SearchHit(
      fingerprint: row['fingerprint'] as String,
      uri: row['uri'] as String,
      displayName: row['display_name'] as String,
      format: IndexFormat.fromId(row['format'] as String?),
      snippet: snippet,
      truncated: ((row['truncated'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  // --- query handling ------------------------------------------------------

  /// Splits what the user typed into safe search terms.
  ///
  /// Everything that is not a letter, digit or underscore becomes a separator,
  /// so FTS5 operators (`"`, `*`, `NEAR`, `:`, `^`, brackets) can never reach
  /// the query engine and a stray quote can never break the search.
  static List<String> queryTerms(String input) {
    final cleaned = input.replaceAll(
      RegExp(r'[^\p{L}\p{N}_]+', unicode: true),
      ' ',
    );
    return cleaned
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  /// Builds the FTS5 `MATCH` expression: every term must be present, and the
  /// last one matches as a prefix so results appear while the user is typing.
  static String buildMatchQuery(List<String> terms) {
    final parts = <String>[];
    for (var i = 0; i < terms.length; i++) {
      final last = i == terms.length - 1;
      parts.add(last ? '"${terms[i]}"*' : '"${terms[i]}"');
    }
    return parts.join(' AND ');
  }

  /// Turns a `snippet()` result into plain and highlighted spans.
  static List<SnippetSpan> parseSnippet(String raw) {
    if (raw.isEmpty) return const [];
    final spans = <SnippetSpan>[];
    var rest = raw;
    while (rest.isNotEmpty) {
      final start = rest.indexOf(highlightStart);
      if (start < 0) {
        spans.add(SnippetSpan(rest));
        break;
      }
      if (start > 0) spans.add(SnippetSpan(rest.substring(0, start)));
      final end = rest.indexOf(highlightEnd, start + 1);
      if (end < 0) {
        // Unbalanced marker — show the remainder as plain text.
        spans.add(SnippetSpan(rest.substring(start + 1)));
        break;
      }
      spans.add(SnippetSpan(rest.substring(start + 1, end), highlighted: true));
      rest = rest.substring(end + 1);
    }
    return spans;
  }

  /// Builds a snippet in Dart for the `LIKE` fallback: a window of text around
  /// the first match, with the matched word highlighted.
  static List<SnippetSpan> buildSnippet(
    String body,
    List<String> terms, {
    int before = 40,
    int after = 90,
  }) {
    if (body.isEmpty || terms.isEmpty) return const [];
    final lower = body.toLowerCase();
    var at = -1;
    var term = terms.first;
    for (final t in terms) {
      final found = lower.indexOf(t.toLowerCase());
      if (found >= 0 && (at < 0 || found < at)) {
        at = found;
        term = t;
      }
    }
    if (at < 0) return [SnippetSpan(_squash(body, before + after))];
    final start = (at - before).clamp(0, body.length);
    final end = (at + term.length + after).clamp(0, body.length);
    final spans = <SnippetSpan>[];
    if (start > 0) spans.add(const SnippetSpan('…'));
    spans.add(SnippetSpan(_squash(body.substring(start, at), before)));
    spans.add(
      SnippetSpan(body.substring(at, at + term.length), highlighted: true),
    );
    spans.add(
      SnippetSpan(_squash(body.substring(at + term.length, end), after)),
    );
    if (end < body.length) spans.add(const SnippetSpan('…'));
    return spans;
  }

  /// Collapses newlines and runs of spaces so a snippet stays on one or two
  /// lines, and trims it to [max] characters.
  static String _squash(String text, int max) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ');
    return flat.length <= max ? flat : flat.substring(0, max);
  }

  static String _escapeLike(String term) =>
      term.replaceAll('%', r'\%').replaceAll('_', r'\_');
}
