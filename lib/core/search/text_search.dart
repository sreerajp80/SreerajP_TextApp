import 'search_options.dart';

/// One match: the half-open character range `[start, end)` in the searched text.
class SearchMatch {
  final int start;
  final int end;

  const SearchMatch(this.start, this.end);

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is SearchMatch && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SearchMatch($start, $end)';
}

/// The outcome of a search: either the list of [matches], or a friendly
/// [errorMessage] when the query is an invalid regular expression.
///
/// A bad regex never throws to the caller — it comes back as an error outcome so
/// the UI can show an "invalid pattern" hint instead of crashing (architecture
/// §6, CLAUDE.md §3.4).
class SearchOutcome {
  final List<SearchMatch> matches;
  final String? errorMessage;

  const SearchOutcome.success(this.matches) : errorMessage = null;
  const SearchOutcome.error(this.errorMessage) : matches = const [];

  bool get hasError => errorMessage != null;
  bool get isEmpty => matches.isEmpty;
  int get count => matches.length;
}

/// Shared text search used by find, highlight, and find-&-replace across every
/// format (architecture.md §6). Pure Dart, no Flutter dependency.
class TextSearch {
  const TextSearch();

  /// Finds every non-overlapping match of [query] in [text] under [options].
  ///
  /// Returns an empty success outcome for an empty query. Returns an error
  /// outcome (never throws) when [options.regex] is on and the query does not
  /// compile.
  SearchOutcome find(String text, String query, SearchOptions options) {
    if (query.isEmpty) return const SearchOutcome.success([]);

    final RegExp pattern;
    try {
      pattern = buildPattern(query, options);
    } on FormatException catch (e) {
      return SearchOutcome.error(_friendlyRegexError(e));
    }

    final matches = <SearchMatch>[];
    for (final m in pattern.allMatches(text)) {
      // A zero-width match (possible with some regexes) would loop forever if we
      // trusted allMatches to advance; Dart's allMatches already steps past it,
      // but we skip empties so callers only get real spans.
      if (m.end > m.start) {
        matches.add(SearchMatch(m.start, m.end));
      }
    }
    return SearchOutcome.success(matches);
  }

  /// Builds the [RegExp] for [query] under [options]. Throws [FormatException]
  /// only for an invalid user regex; literal and whole-word queries are always
  /// valid because they are escaped first.
  RegExp buildPattern(String query, SearchOptions options) {
    var source = options.regex ? query : RegExp.escape(query);
    if (options.wholeWord) {
      source = '\\b(?:$source)\\b';
    }
    return RegExp(source, caseSensitive: options.caseSensitive);
  }

  String _friendlyRegexError(FormatException e) {
    final detail = e.message.isEmpty ? '' : ' (${e.message})';
    return 'Invalid search pattern$detail.';
  }
}
