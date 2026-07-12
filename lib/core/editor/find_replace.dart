import '../search/search_options.dart';
import '../search/text_search.dart';

/// Where a find-&-replace applies: the half-open character range
/// `[start, end)`. A `null` scope means the whole document. Format modules build
/// a scope for a CSV column or a JSON/XML subtree by giving the character range
/// that span occupies (architecture.md §6).
class ReplaceScope {
  final int start;
  final int end;

  const ReplaceScope(this.start, this.end);

  int get length => end - start;
}

/// The result of a replace: the resulting [text] and how many matches were
/// [replacedCount]. When the query is an invalid regex, [errorMessage] is set,
/// [text] is unchanged, and [replacedCount] is 0 — the caller shows the hint and
/// nothing is modified.
class ReplaceResult {
  final String text;
  final int replacedCount;
  final String? errorMessage;

  const ReplaceResult({
    required this.text,
    required this.replacedCount,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
}

/// Find & replace with the power options from [SearchOptions] (case, whole-word,
/// regex), `$1` capture-group references in the replacement, a match-count
/// preview, and a scope limit (architecture.md §6). Pure Dart.
class FindReplace {
  final TextSearch _search;

  const FindReplace([this._search = const TextSearch()]);

  /// Counts matches of [query] in [text] under [options], limited to [scope].
  /// Returns -1 when the regex is invalid so the caller can show the hint (a
  /// count of 0 means "valid pattern, no matches").
  int matchCount(
    String text,
    String query,
    SearchOptions options, {
    ReplaceScope? scope,
  }) {
    final region = _region(text, scope);
    final outcome = _search.find(region, query, options);
    if (outcome.hasError) return -1;
    return outcome.count;
  }

  /// Replaces **every** match of [query] with [replacement] under [options],
  /// within [scope] (or the whole document). For a regex query, [replacement]
  /// may use `$1`…`$9` capture-group references and `$$` for a literal `$`;
  /// for a literal query the replacement is inserted verbatim.
  ReplaceResult replaceAll(
    String text,
    String query,
    String replacement,
    SearchOptions options, {
    ReplaceScope? scope,
  }) {
    if (query.isEmpty) {
      return ReplaceResult(text: text, replacedCount: 0);
    }

    final RegExp pattern;
    try {
      pattern = _search.buildPattern(query, options);
    } on FormatException catch (e) {
      return ReplaceResult(
        text: text,
        replacedCount: 0,
        errorMessage: 'Invalid search pattern (${e.message}).',
      );
    }

    final start = scope?.start ?? 0;
    final end = scope?.end ?? text.length;
    final before = text.substring(0, start);
    final region = text.substring(start, end);
    final after = text.substring(end);

    var count = 0;
    final rebuilt = region.replaceAllMapped(pattern, (match) {
      if (match.end == match.start) return match[0] ?? '';
      count++;
      return _expand(replacement, match, options.regex);
    });

    return ReplaceResult(text: before + rebuilt + after, replacedCount: count);
  }

  /// Replaces the **first** match at or after [from] and returns the result. If
  /// there is no match at/after [from], the text is returned unchanged with a
  /// count of 0.
  ReplaceResult replaceFirstFrom(
    String text,
    String query,
    String replacement,
    SearchOptions options,
    int from, {
    ReplaceScope? scope,
  }) {
    if (query.isEmpty) {
      return ReplaceResult(text: text, replacedCount: 0);
    }

    final RegExp pattern;
    try {
      pattern = _search.buildPattern(query, options);
    } on FormatException catch (e) {
      return ReplaceResult(
        text: text,
        replacedCount: 0,
        errorMessage: 'Invalid search pattern (${e.message}).',
      );
    }

    final scopeStart = scope?.start ?? 0;
    final scopeEnd = scope?.end ?? text.length;
    final searchFrom = from < scopeStart ? scopeStart : from;

    for (final match in pattern.allMatches(text)) {
      if (match.start < searchFrom || match.end > scopeEnd) continue;
      if (match.end == match.start) continue;
      final replaced = _expand(replacement, match, options.regex);
      final newText = text.replaceRange(match.start, match.end, replaced);
      return ReplaceResult(text: newText, replacedCount: 1);
    }
    return ReplaceResult(text: text, replacedCount: 0);
  }

  String _region(String text, ReplaceScope? scope) {
    if (scope == null) return text;
    return text.substring(scope.start, scope.end);
  }

  /// Expands `$1`…`$9` / `$$` in [replacement] against [match]. Only applies in
  /// regex mode; a literal replacement is returned untouched so a user typing a
  /// real `$` in literal mode gets exactly that.
  String _expand(String replacement, Match match, bool regex) {
    if (!regex || !replacement.contains(r'$')) return replacement;
    final out = StringBuffer();
    for (var i = 0; i < replacement.length; i++) {
      final ch = replacement[i];
      if (ch != r'$' || i + 1 >= replacement.length) {
        out.write(ch);
        continue;
      }
      final next = replacement[i + 1];
      if (next == r'$') {
        out.write(r'$');
        i++;
      } else if (_isDigit(next)) {
        final groupIndex = int.parse(next);
        if (groupIndex <= match.groupCount) {
          out.write(match.group(groupIndex) ?? '');
        }
        i++;
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  bool _isDigit(String s) {
    final c = s.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }
}
