/// How a search should match (architecture.md §6). The same options drive find,
/// highlight, and replace across every format.
class SearchOptions {
  /// Match upper/lower case exactly when true.
  final bool caseSensitive;

  /// Match only whole words (word boundaries on both sides) when true.
  final bool wholeWord;

  /// Treat the query as a regular expression when true; otherwise the query is
  /// matched literally.
  final bool regex;

  const SearchOptions({
    this.caseSensitive = false,
    this.wholeWord = false,
    this.regex = false,
  });

  SearchOptions copyWith({
    bool? caseSensitive,
    bool? wholeWord,
    bool? regex,
  }) {
    return SearchOptions(
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      regex: regex ?? this.regex,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchOptions &&
      other.caseSensitive == caseSensitive &&
      other.wholeWord == wholeWord &&
      other.regex == regex;

  @override
  int get hashCode => Object.hash(caseSensitive, wholeWord, regex);
}
