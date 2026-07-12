/// Word / character / line counts for a plain-text document (task 4.3).
///
/// Pure Dart, no Flutter dependency, so it is cheap to unit-test. The counts are
/// computed on the in-memory text, whose newlines are always `\n` (the codec
/// normalizes line endings on load, see `encoding.dart`).
class TxtStats {
  /// Number of words: runs of non-whitespace characters. `0` for empty or
  /// whitespace-only text.
  final int words;

  /// Number of characters, counting every Unicode scalar value including spaces
  /// and newlines. Uses runes so a multi-byte character counts once.
  final int characters;

  /// Number of characters excluding line-break characters, so the count matches
  /// what the reader sees on the page.
  final int charactersNoLineBreaks;

  /// Number of lines. `0` for empty text; otherwise the number of `\n`-separated
  /// segments (so a trailing newline counts the final empty line). This matches
  /// `text.split('\n').length` for non-empty text.
  final int lines;

  const TxtStats({
    required this.words,
    required this.characters,
    required this.charactersNoLineBreaks,
    required this.lines,
  });

  /// Empty-document stats (all zero).
  static const TxtStats empty =
      TxtStats(words: 0, characters: 0, charactersNoLineBreaks: 0, lines: 0);

  /// Counts words, characters, and lines in [text].
  factory TxtStats.of(String text) {
    if (text.isEmpty) return empty;

    var words = 0;
    var inWord = false;
    var lineBreaks = 0;
    var newlineChars = 0;

    for (final rune in text.runes) {
      final isNewline = rune == 0x0A; // \n (text is already normalized)
      if (isNewline) {
        lineBreaks++;
        newlineChars++;
      }
      if (_isWhitespace(rune)) {
        inWord = false;
      } else if (!inWord) {
        inWord = true;
        words++;
      }
    }

    final characters = text.runes.length;
    return TxtStats(
      words: words,
      characters: characters,
      charactersNoLineBreaks: characters - newlineChars,
      lines: lineBreaks + 1,
    );
  }

  static bool _isWhitespace(int rune) {
    switch (rune) {
      case 0x09: // tab
      case 0x0A: // \n
      case 0x0B: // vertical tab
      case 0x0C: // form feed
      case 0x0D: // \r (should not appear after normalization, handled anyway)
      case 0x20: // space
      case 0xA0: // no-break space
      case 0x2028: // line separator
      case 0x2029: // paragraph separator
        return true;
      default:
        return false;
    }
  }
}
