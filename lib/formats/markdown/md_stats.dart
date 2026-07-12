import 'package:markdown/markdown.dart' as md;

import 'md_parse.dart';

/// Word / character / line / heading / link counts for a Markdown document
/// (task 6.5 metadata).
///
/// Pure Dart, no Flutter dependency. Words, characters, and lines are counted on
/// the raw source (so the count matches what the editor shows); headings and
/// links are counted from the parsed AST (so `#` inside a code block is not
/// mistaken for a heading).
class MdStats {
  final int words;
  final int characters;
  final int lines;
  final int headings;
  final int links;

  const MdStats({
    required this.words,
    required this.characters,
    required this.lines,
    required this.headings,
    required this.links,
  });

  static const MdStats empty =
      MdStats(words: 0, characters: 0, lines: 0, headings: 0, links: 0);

  /// Counts stats for [source] (front matter already stripped by the caller).
  factory MdStats.of(String source) {
    if (source.isEmpty) return empty;

    var words = 0;
    var inWord = false;
    var newlineChars = 0;
    for (final rune in source.runes) {
      if (rune == 0x0A) newlineChars++;
      if (_isWhitespace(rune)) {
        inWord = false;
      } else if (!inWord) {
        inWord = true;
        words++;
      }
    }

    final nodes = MdParse.parseBlocks(source);
    var headings = 0;
    var links = 0;
    void visit(List<md.Node>? children) {
      if (children == null) return;
      for (final node in children) {
        if (node is md.Element) {
          if (_isHeading(node.tag)) headings++;
          if (node.tag == 'a') links++;
          visit(node.children);
        }
      }
    }

    visit(nodes);

    return MdStats(
      words: words,
      characters: source.runes.length,
      lines: newlineChars + 1,
      headings: headings,
      links: links,
    );
  }

  static bool _isHeading(String tag) =>
      tag.length == 2 &&
      tag[0] == 'h' &&
      (int.tryParse(tag[1]) ?? 0) >= 1 &&
      (int.tryParse(tag[1]) ?? 0) <= 6;

  static bool _isWhitespace(int rune) {
    switch (rune) {
      case 0x09:
      case 0x0A:
      case 0x0B:
      case 0x0C:
      case 0x0D:
      case 0x20:
      case 0xA0:
      case 0x2028:
      case 0x2029:
        return true;
      default:
        return false;
    }
  }
}
