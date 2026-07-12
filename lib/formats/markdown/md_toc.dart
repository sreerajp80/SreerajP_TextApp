import 'package:markdown/markdown.dart' as md;

import 'md_parse.dart';

/// One heading in the table of contents (task 6.3).
class MdHeading {
  /// Heading level: 1 for `#`, 2 for `##`, … 6 for `######`.
  final int level;

  /// The heading's plain text (inline markup removed).
  final String text;

  /// The anchor id GitHub-web flavour generates (e.g. `my-heading`), used to
  /// resolve internal `#` links and to scroll to the heading.
  final String anchor;

  const MdHeading({
    required this.level,
    required this.text,
    required this.anchor,
  });
}

/// The table of contents built from a document's headings (task 6.3).
///
/// Pure Dart over the shared [MdParse] AST, so it is unit-tested without a
/// device. The renderer tags each heading widget with the same [MdHeading.anchor]
/// so tapping a TOC entry — or an internal `[link](#anchor)` — can scroll to it.
class MdToc {
  final List<MdHeading> headings;

  const MdToc(this.headings);

  bool get isEmpty => headings.isEmpty;
  bool get isNotEmpty => headings.isNotEmpty;

  /// Builds the TOC from a Markdown [source] (front matter already stripped by
  /// the caller).
  factory MdToc.of(String source) {
    final nodes = MdParse.parseBlocks(source);
    final headings = <MdHeading>[];
    final used = <String, int>{};

    void visit(List<md.Node>? children) {
      if (children == null) return;
      for (final node in children) {
        if (node is md.Element) {
          final level = _headingLevel(node.tag);
          if (level != null) {
            final text = node.textContent.trim();
            final anchor = _uniqueAnchor(
              node.generatedId ?? _slugify(text),
              used,
            );
            headings.add(
              MdHeading(level: level, text: text, anchor: anchor),
            );
          } else {
            visit(node.children);
          }
        }
      }
    }

    visit(nodes);
    return MdToc(headings);
  }

  /// Resolves an internal link target (`#anchor` or `anchor`) to the matching
  /// heading, or null when nothing matches.
  MdHeading? resolve(String target) {
    var slug = target.trim();
    if (slug.startsWith('#')) slug = slug.substring(1);
    slug = slug.toLowerCase();
    for (final heading in headings) {
      if (heading.anchor == slug) return heading;
    }
    // Fall back to matching a slugified heading text.
    for (final heading in headings) {
      if (_slugify(heading.text) == slug) return heading;
    }
    return null;
  }

  static int? _headingLevel(String tag) {
    if (tag.length == 2 && tag[0] == 'h') {
      final digit = int.tryParse(tag[1]);
      if (digit != null && digit >= 1 && digit <= 6) return digit;
    }
    return null;
  }

  /// GitHub-style slug: lowercase, spaces to hyphens, drop other punctuation.
  static String _slugify(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final c = String.fromCharCode(rune);
      if (RegExp(r'[a-z0-9]').hasMatch(c)) {
        buffer.write(c);
      } else if (c == ' ' || c == '-' || c == '_') {
        buffer.write('-');
      }
      // everything else is dropped
    }
    return buffer.toString().replaceAll(RegExp(r'-+'), '-').replaceAll(
          RegExp(r'^-|-$'),
          '',
        );
  }

  /// Ensures repeated heading text gets a `-1`, `-2`, … suffix like GitHub.
  static String _uniqueAnchor(String base, Map<String, int> used) {
    final count = used[base];
    if (count == null) {
      used[base] = 0;
      return base;
    }
    final next = count + 1;
    used[base] = next;
    return '$base-$next';
  }
}
