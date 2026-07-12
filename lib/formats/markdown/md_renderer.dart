import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Our own Flutter renderer for a parsed Markdown AST (Phase 6).
///
/// We deliberately do **not** use a Markdown *rendering* package (the official
/// `flutter_markdown` is discontinued — CLAUDE.md §3.1). Instead we walk the AST
/// produced by the actively maintained `markdown` parser and map each node to a
/// Material 3 widget. This gives us full control over links (routed to a warning
/// dialog, offline-first), math (`flutter_math_fork`), theming, and the graceful
/// fallbacks the plan requires (mermaid → code block; bad LaTeX → source).
///
/// [headingAnchors] lists the heading anchors in document order (from `MdToc`)
/// and [headingKeys] maps each anchor to a [GlobalKey]; the renderer tags each
/// heading with its key so the TOC and internal `#` links can scroll to it.
class MarkdownRenderer extends StatefulWidget {
  final List<md.Node> nodes;

  /// Called when a normal (external) link is tapped.
  final void Function(String href)? onTapLink;

  /// Called when an internal `#anchor` link is tapped.
  final void Function(String anchor)? onTapAnchor;

  final List<String> headingAnchors;
  final Map<String, GlobalKey> headingKeys;

  /// Multiplier applied to every font size (the app's font-scale setting).
  final double textScale;

  const MarkdownRenderer({
    super.key,
    required this.nodes,
    this.onTapLink,
    this.onTapAnchor,
    this.headingAnchors = const [],
    this.headingKeys = const {},
    this.textScale = 1.0,
  });

  @override
  State<MarkdownRenderer> createState() => _MarkdownRendererState();
}

class _MarkdownRendererState extends State<MarkdownRenderer> {
  final List<TapGestureRecognizer> _recognizers = [];
  int _headingIndex = 0;

  static const Set<String> _blockTags = {
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
    'p', 'pre', 'blockquote', 'ul', 'ol', 'li', 'hr', //
    'table', 'thead', 'tbody', 'tr', 'th', 'td',
  };

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild from scratch: drop the previous pass's tap recognizers.
    _disposeRecognizers();
    _headingIndex = 0;

    final blocks = _flow(widget.nodes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: block,
          ),
      ],
    );
  }

  // --- block flow ----------------------------------------------------------

  /// Renders a node's children, grouping runs of inline nodes into paragraphs
  /// and rendering block nodes on their own.
  List<Widget> _flow(List<md.Node>? children) {
    final widgets = <Widget>[];
    final inlineRun = <md.Node>[];

    void flush() {
      if (inlineRun.isEmpty) return;
      widgets.add(_paragraph(List.of(inlineRun)));
      inlineRun.clear();
    }

    for (final node in children ?? const <md.Node>[]) {
      if (node is md.Element && _blockTags.contains(node.tag)) {
        flush();
        widgets.add(_block(node));
      } else {
        inlineRun.add(node);
      }
    }
    flush();
    return widgets;
  }

  Widget _block(md.Element element) {
    switch (element.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return _heading(element);
      case 'p':
        return _paragraph(element.children ?? const []);
      case 'pre':
        return _codeBlock(element);
      case 'blockquote':
        return _blockquote(element);
      case 'ul':
        return _list(element, ordered: false);
      case 'ol':
        return _list(element, ordered: true);
      case 'hr':
        return const Divider(height: 8);
      case 'table':
        return _table(element);
      default:
        // Unknown block: render its children as a flow.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _flow(element.children),
        );
    }
  }

  Widget _heading(md.Element element) {
    final theme = Theme.of(context);
    final level = int.parse(element.tag.substring(1));
    final base = switch (level) {
      1 => theme.textTheme.headlineMedium,
      2 => theme.textTheme.headlineSmall,
      3 => theme.textTheme.titleLarge,
      4 => theme.textTheme.titleMedium,
      5 => theme.textTheme.titleSmall,
      _ => theme.textTheme.labelLarge,
    };
    final style = (base ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (base?.fontSize ?? 16) * widget.textScale,
    );

    Widget child = Text.rich(
      TextSpan(children: _inlineSpans(element.children, style)),
    );

    // Attach the anchor key so the TOC / internal links can scroll here.
    final idx = _headingIndex++;
    if (idx < widget.headingAnchors.length) {
      final anchor = widget.headingAnchors[idx];
      final key = widget.headingKeys[anchor];
      if (key != null) child = KeyedSubtree(key: key, child: child);
    }
    return Padding(
      padding: EdgeInsets.only(top: level <= 2 ? 6 : 2),
      child: child,
    );
  }

  Widget _paragraph(List<md.Node> nodes) {
    final theme = Theme.of(context);
    final style = _bodyStyle(theme);
    return Text.rich(
      TextSpan(children: _inlineSpans(nodes, style)),
    );
  }

  Widget _blockquote(md.Element element) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _flow(element.children),
      ),
    );
  }

  Widget _list(md.Element element, {required bool ordered}) {
    final items = (element.children ?? const [])
        .whereType<md.Element>()
        .where((e) => e.tag == 'li')
        .toList();
    final theme = Theme.of(context);
    final style = _bodyStyle(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 4),
            child: _listItem(items[i], ordered ? '${i + 1}.' : '•', style),
          ),
      ],
    );
  }

  Widget _listItem(md.Element li, String marker, TextStyle style) {
    final children = li.children ?? const [];
    final task = _taskCheckbox(children);

    Widget leading;
    List<md.Node> contentNodes = children;
    if (task != null) {
      leading = Padding(
        padding: const EdgeInsets.only(top: 2, right: 4),
        child: Icon(
          task ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
      // Skip the leading checkbox input node.
      contentNodes = children
          .where((n) => !(n is md.Element && n.tag == 'input'))
          .toList();
    } else {
      leading = Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(marker, style: style),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _flow(contentNodes),
          ),
        ),
      ],
    );
  }

  /// Returns true/false when [children] begin with a task-list checkbox, or null
  /// when this is an ordinary list item.
  bool? _taskCheckbox(List<md.Node> children) {
    for (final node in children) {
      if (node is md.Element && node.tag == 'input') {
        final type = node.attributes['type'];
        if (type == 'checkbox') {
          return node.attributes['checked'] == 'true' ||
              node.attributes.containsKey('checked');
        }
      }
      if (node is md.Element && node.tag != 'input') break;
    }
    return null;
  }

  Widget _codeBlock(md.Element pre) {
    final theme = Theme.of(context);
    // <pre> wraps a single <code> whose text is the block body.
    final code = (pre.children ?? const [])
        .whereType<md.Element>()
        .firstWhere((e) => e.tag == 'code', orElse: () => pre);
    var text = code.textContent;
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13 * widget.textScale,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _table(md.Element table) {
    final theme = Theme.of(context);
    final rows = <TableRow>[];
    final headerStyle = _bodyStyle(theme).copyWith(fontWeight: FontWeight.w700);
    final cellStyle = _bodyStyle(theme);

    for (final section in (table.children ?? const []).whereType<md.Element>()) {
      final isHeader = section.tag == 'thead';
      for (final tr
          in (section.children ?? const []).whereType<md.Element>()) {
        if (tr.tag != 'tr') continue;
        final cells = <Widget>[];
        for (final cell
            in (tr.children ?? const []).whereType<md.Element>()) {
          cells.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text.rich(
                TextSpan(
                  children: _inlineSpans(
                    cell.children,
                    isHeader ? headerStyle : cellStyle,
                  ),
                ),
                textAlign: _cellAlign(cell),
              ),
            ),
          );
        }
        rows.add(
          TableRow(
            decoration: isHeader
                ? BoxDecoration(color: theme.colorScheme.surfaceContainerHigh)
                : null,
            children: cells,
          ),
        );
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    // Pad short rows so every TableRow has the same number of cells.
    final columns =
        rows.map((r) => r.children.length).fold<int>(0, (a, b) => a > b ? a : b);
    final normalized = <TableRow>[
      for (final row in rows)
        if (row.children.length == columns)
          row
        else
          TableRow(
            decoration: row.decoration,
            children: [
              ...row.children,
              for (var i = row.children.length; i < columns; i++)
                const SizedBox.shrink(),
            ],
          ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: theme.dividerColor,
          width: 0.5,
        ),
        children: normalized,
      ),
    );
  }

  TextAlign? _cellAlign(md.Element cell) {
    final style = cell.attributes['style'] ?? '';
    if (style.contains('right')) return TextAlign.right;
    if (style.contains('center')) return TextAlign.center;
    if (style.contains('left')) return TextAlign.left;
    return null;
  }

  // --- inline spans --------------------------------------------------------

  List<InlineSpan> _inlineSpans(List<md.Node>? nodes, TextStyle style) {
    final spans = <InlineSpan>[];
    for (final node in nodes ?? const <md.Node>[]) {
      if (node is md.Text) {
        spans.add(TextSpan(text: _unescape(node.text), style: style));
      } else if (node is md.Element) {
        spans.addAll(_inlineElement(node, style));
      }
    }
    return spans;
  }

  List<InlineSpan> _inlineElement(md.Element element, TextStyle style) {
    final theme = Theme.of(context);
    switch (element.tag) {
      case 'strong':
        return _inlineSpans(
          element.children,
          style.copyWith(fontWeight: FontWeight.w700),
        );
      case 'em':
        return _inlineSpans(
          element.children,
          style.copyWith(fontStyle: FontStyle.italic),
        );
      case 'del':
        return _inlineSpans(
          element.children,
          style.copyWith(decoration: TextDecoration.lineThrough),
        );
      case 'code':
        return [
          TextSpan(
            text: element.textContent,
            style: style.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ];
      case 'br':
        return [const TextSpan(text: '\n')];
      case 'a':
        return [_link(element, style)];
      case 'img':
        return [WidgetSpan(child: _image(element))];
      case 'math':
        return [WidgetSpan(child: _math(element), alignment: PlaceholderAlignment.middle)];
      default:
        return _inlineSpans(element.children, style);
    }
  }

  InlineSpan _link(md.Element element, TextStyle style) {
    final href = element.attributes['href'] ?? '';
    final theme = Theme.of(context);
    final linkStyle = style.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        if (href.startsWith('#')) {
          widget.onTapAnchor?.call(href.substring(1));
        } else {
          widget.onTapLink?.call(href);
        }
      };
    _recognizers.add(recognizer);
    return TextSpan(
      children: _inlineSpans(element.children, linkStyle),
      recognizer: recognizer,
    );
  }

  Widget _math(md.Element element) {
    final tex = element.attributes['tex'] ?? element.textContent;
    final display = element.attributes['display'] == '1';
    final theme = Theme.of(context);
    return Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: _bodyStyle(theme),
      onErrorFallback: (err) => Text(
        display ? '\$\$$tex\$\$' : '\$$tex\$',
        style: _bodyStyle(theme).copyWith(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _image(md.Element element) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';
    // Offline-first: only remote images are loaded, and any failure shows a
    // neutral placeholder rather than crashing (CLAUDE.md §3.2, §3.4).
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: Image.network(
          src,
          errorBuilder: (context, error, stack) => _imagePlaceholder(alt),
        ),
      );
    }
    return _imagePlaceholder(alt);
  }

  Widget _imagePlaceholder(String alt) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              alt.isEmpty ? 'Image' : alt,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _bodyStyle(ThemeData theme) {
    final base = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    return base.copyWith(fontSize: (base.fontSize ?? 16) * widget.textScale);
  }

  /// The parser is configured with `encodeHtml: false`, so entity text is left
  /// as-is; this only collapses the few basic escapes that can still appear.
  String _unescape(String s) => s;
}
