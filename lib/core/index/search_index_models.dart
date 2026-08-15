// Plain data models for the workspace-wide search index (Feature 11).
//
// One row per indexed file lives in `search_docs`; its text lives in the FTS5
// table (or the `LIKE` fallback table) keyed by the same row id.

/// The document formats the index knows about. Used for the filter chips in the
/// search screen and stored as a short string in the DB.
enum IndexFormat {
  txt('txt'),
  markdown('md'),
  json('json'),
  csv('csv'),
  xml('xml'),
  other('other');

  final String id;

  const IndexFormat(this.id);

  /// Maps a stored id back to a format; unknown ids fall back to [other] so an
  /// older or newer row never breaks the list.
  static IndexFormat fromId(String? id) {
    for (final format in IndexFormat.values) {
      if (format.id == id) return format;
    }
    return IndexFormat.other;
  }

  /// Guesses the format from a file name (and, when the name has no useful
  /// extension, from the MIME type).
  static IndexFormat fromFileName(String displayName, {String? mimeType}) {
    final dot = displayName.lastIndexOf('.');
    final ext = dot < 0
        ? ''
        : displayName.substring(dot + 1).toLowerCase().trim();
    switch (ext) {
      case 'txt':
      case 'log':
      case 'text':
        return IndexFormat.txt;
      case 'md':
      case 'markdown':
      case 'mdown':
        return IndexFormat.markdown;
      case 'json':
      case 'jsonl':
      case 'geojson':
        return IndexFormat.json;
      case 'csv':
      case 'tsv':
        return IndexFormat.csv;
      case 'xml':
      case 'xhtml':
      case 'svg':
        return IndexFormat.xml;
    }
    final mime = mimeType?.toLowerCase() ?? '';
    if (mime.contains('json')) return IndexFormat.json;
    if (mime.contains('xml')) return IndexFormat.xml;
    if (mime.contains('csv')) return IndexFormat.csv;
    if (mime.contains('markdown')) return IndexFormat.markdown;
    if (mime.startsWith('text/')) return IndexFormat.txt;
    return IndexFormat.other;
  }
}

/// One indexed file's metadata (the body is stored separately).
class IndexedDoc {
  /// Row id; null until the row is written.
  final int? id;
  final String fingerprint;
  final String uri;
  final String displayName;
  final IndexFormat format;
  final int? size;
  final int indexedAt; // epoch millis

  /// True when only the first part of a long file was indexed.
  final bool truncated;

  /// True for a favorite, which is kept when the recents list is cleared.
  final bool pinned;

  const IndexedDoc({
    this.id,
    required this.fingerprint,
    required this.uri,
    required this.displayName,
    required this.format,
    this.size,
    required this.indexedAt,
    this.truncated = false,
    this.pinned = false,
  });

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'fingerprint': fingerprint,
    'uri': uri,
    'display_name': displayName,
    'format': format.id,
    'size': size,
    'indexed_at': indexedAt,
    'truncated': truncated ? 1 : 0,
    'pinned': pinned ? 1 : 0,
  };

  factory IndexedDoc.fromRow(Map<String, Object?> row) => IndexedDoc(
    id: (row['id'] as num?)?.toInt(),
    fingerprint: row['fingerprint'] as String,
    uri: row['uri'] as String,
    displayName: row['display_name'] as String,
    format: IndexFormat.fromId(row['format'] as String?),
    size: (row['size'] as num?)?.toInt(),
    indexedAt: (row['indexed_at'] as num).toInt(),
    truncated: ((row['truncated'] as num?)?.toInt() ?? 0) == 1,
    pinned: ((row['pinned'] as num?)?.toInt() ?? 0) == 1,
  );
}

/// One search result: the file it came from plus a short piece of text around
/// the match, split into plain and highlighted parts.
class SearchHit {
  final String fingerprint;
  final String uri;
  final String displayName;
  final IndexFormat format;
  final List<SnippetSpan> snippet;
  final bool truncated;

  const SearchHit({
    required this.fingerprint,
    required this.uri,
    required this.displayName,
    required this.format,
    required this.snippet,
    this.truncated = false,
  });

  /// The snippet as plain text (used in tests and for accessibility labels).
  String get snippetText => snippet.map((s) => s.text).join();
}

/// A piece of a snippet. [highlighted] marks the part that matched the query.
class SnippetSpan {
  final String text;
  final bool highlighted;

  const SnippetSpan(this.text, {this.highlighted = false});

  @override
  bool operator ==(Object other) =>
      other is SnippetSpan &&
      other.text == text &&
      other.highlighted == highlighted;

  @override
  int get hashCode => Object.hash(text, highlighted);

  @override
  String toString() => highlighted ? '[$text]' : text;
}
