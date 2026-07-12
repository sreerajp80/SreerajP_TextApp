import 'package:markdown/markdown.dart' as md;

/// Shared Markdown parsing configuration for the Markdown module (Phase 6).
///
/// One place decides which Markdown flavour the app reads, so the rendered view,
/// the table of contents, the stats, and the HTML export all agree. We depend on
/// the actively maintained **`markdown`** parser (BSD-3, tools.dart.dev) only as a
/// *parser*; the on-screen rendering is our own widget code in `md_renderer.dart`
/// (CLAUDE.md §3.1 — no discontinued rendering package).
///
/// GitHub-web flavour gives us tables, task lists, strikethrough, autolinks, and
/// auto-generated heading ids (used for the TOC and internal `#` links).
class MdParse {
  const MdParse._();

  /// Parses [source] into a list of block-level AST nodes for our renderer.
  ///
  /// When [withMath] is true, `$…$` and `$$…$$` become `math` elements the
  /// renderer typesets with `flutter_math_fork`; otherwise the dollar spans are
  /// left as plain text. Never throws — a parser problem yields an empty list so
  /// the viewer degrades to a friendly empty state (CLAUDE.md §3.4).
  static List<md.Node> parseBlocks(String source, {bool withMath = false}) {
    try {
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubWeb,
        inlineSyntaxes: withMath
            ? <md.InlineSyntax>[_DisplayMathSyntax(), _InlineMathSyntax()]
            : const <md.InlineSyntax>[],
        encodeHtml: false,
      );
      return document.parseLines(source.split('\n'));
    } catch (_) {
      return const <md.Node>[];
    }
  }

  /// Renders [source] to a full, self-contained HTML string for export
  /// (task 6.5). Math is intentionally left as literal `$$…$$` source so a
  /// downstream viewer can typeset it; our own renderer handles math on screen.
  static String toHtml(String source) {
    return md.markdownToHtml(
      source,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
  }
}

/// Inline syntax for display math written as `$$ … $$` (may span lines).
class _DisplayMathSyntax extends md.InlineSyntax {
  _DisplayMathSyntax() : super(r'\$\$([\s\S]+?)\$\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_mathElement(match[1]!, display: true));
    return true;
  }
}

/// Inline syntax for inline math written as `$ … $` on a single line.
class _InlineMathSyntax extends md.InlineSyntax {
  _InlineMathSyntax() : super(r'\$([^$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_mathElement(match[1]!, display: false));
    return true;
  }
}

md.Element _mathElement(String tex, {required bool display}) {
  final element = md.Element.empty('math');
  element.attributes['tex'] = tex.trim();
  element.attributes['display'] = display ? '1' : '0';
  return element;
}
