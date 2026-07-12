import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart';

import '../../core/theme/theme_controller.dart';
import '../../l10n/app_localizations.dart';
import 'xml_document_session.dart';

/// The colour-coded, indented **pretty** view of an XML document (task 9.1).
///
/// Built as rich text by walking the parsed DOM — tag names, attribute names,
/// attribute values, text, comments, and CDATA each get a theme-aware colour, so
/// it works in light / dark / sepia with no extra package. When the document
/// cannot be parsed at all a friendly notice points the user to the editor
/// (CLAUDE.md §3.4).
class XmlPrettyView extends ConsumerWidget {
  final XmlDocumentSession session;
  const XmlPrettyView({super.key, required this.session});

  static const double _baseFontSize = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = session.document;
    if (document == null) return _InvalidNotice(session: session);

    final theme = Theme.of(context);
    final appearance = ref.watch(themeControllerProvider);
    final colors = _XmlColors.of(theme);
    final spans = <InlineSpan>[];
    final unit = session.indent.unit;
    for (final node in document.children) {
      _build(node, spans, colors, unit, 0);
    }

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText.rich(
          TextSpan(children: spans),
          style: TextStyle(
            fontFamily: appearance.fontFamily ?? 'monospace',
            fontSize: _baseFontSize * appearance.fontScale,
            height: appearance.lineSpacing,
            color: colors.punctuation,
          ),
        ),
      ),
    );
  }

  void _build(XmlNode node, List<InlineSpan> out, _XmlColors colors,
      String unit, int depth) {
    final indent = unit * depth;
    if (node is XmlElement) {
      out.add(TextSpan(text: '$indent<', style: TextStyle(color: colors.punctuation)));
      out.add(TextSpan(text: node.name.qualified, style: TextStyle(color: colors.tag)));
      for (final attribute in node.attributes) {
        out.add(const TextSpan(text: ' '));
        out.add(TextSpan(
            text: attribute.name.qualified,
            style: TextStyle(color: colors.attrName)));
        out.add(TextSpan(text: '=', style: TextStyle(color: colors.punctuation)));
        out.add(TextSpan(
            text: '"${_escape(attribute.value)}"',
            style: TextStyle(color: colors.attrValue)));
      }

      final elementChildren = node.childElements.toList();
      final textOnly = elementChildren.isEmpty;
      final significant = node.children
          .where((c) => c is! XmlText || c.value.trim().isNotEmpty)
          .toList();

      if (significant.isEmpty) {
        out.add(TextSpan(text: '/>\n', style: TextStyle(color: colors.punctuation)));
        return;
      }
      out.add(TextSpan(text: '>', style: TextStyle(color: colors.punctuation)));
      if (textOnly) {
        for (final child in significant) {
          _inline(child, out, colors);
        }
        out.add(TextSpan(text: '</', style: TextStyle(color: colors.punctuation)));
        out.add(TextSpan(text: node.name.qualified, style: TextStyle(color: colors.tag)));
        out.add(TextSpan(text: '>\n', style: TextStyle(color: colors.punctuation)));
      } else {
        out.add(const TextSpan(text: '\n'));
        for (final child in significant) {
          _build(child, out, colors, unit, depth + 1);
        }
        out.add(TextSpan(text: '$indent</', style: TextStyle(color: colors.punctuation)));
        out.add(TextSpan(text: node.name.qualified, style: TextStyle(color: colors.tag)));
        out.add(TextSpan(text: '>\n', style: TextStyle(color: colors.punctuation)));
      }
    } else if (node is XmlText) {
      final value = node.value.trim();
      if (value.isEmpty) return;
      out.add(TextSpan(text: '$indent${_escape(value)}\n',
          style: TextStyle(color: colors.text)));
    } else if (node is XmlCDATA) {
      out.add(TextSpan(
          text: '$indent<![CDATA[${node.value}]]>\n',
          style: TextStyle(color: colors.cdata)));
    } else if (node is XmlComment) {
      out.add(TextSpan(
          text: '$indent<!--${node.value}-->\n',
          style: TextStyle(color: colors.comment, fontStyle: FontStyle.italic)));
    } else {
      // Declaration, processing instructions, doctype: render verbatim.
      out.add(TextSpan(
          text: '$indent${node.toXmlString()}\n',
          style: TextStyle(color: colors.punctuation)));
    }
  }

  /// Renders a text / CDATA child inline (inside a text-only element).
  void _inline(XmlNode node, List<InlineSpan> out, _XmlColors colors) {
    if (node is XmlText) {
      out.add(TextSpan(text: _escape(node.value.trim()),
          style: TextStyle(color: colors.text)));
    } else if (node is XmlCDATA) {
      out.add(TextSpan(text: '<![CDATA[${node.value}]]>',
          style: TextStyle(color: colors.cdata)));
    } else if (node is XmlComment) {
      out.add(TextSpan(text: '<!--${node.value}-->',
          style: TextStyle(color: colors.comment, fontStyle: FontStyle.italic)));
    }
  }

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

class _InvalidNotice extends StatelessWidget {
  final XmlDocumentSession session;
  const _InvalidNotice({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final line = session.validationLine;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule_folder_outlined,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.xmlNotWellFormedYet, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              line != null && line > 0
                  ? l10n.xmlProblemNearLine(line)
                  : l10n.xmlOpenEditorToFix,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme-aware colours for XML syntax, derived from the Material scheme so they
/// adapt to light / dark / sepia.
class _XmlColors {
  final Color punctuation;
  final Color tag;
  final Color attrName;
  final Color attrValue;
  final Color text;
  final Color comment;
  final Color cdata;

  const _XmlColors({
    required this.punctuation,
    required this.tag,
    required this.attrName,
    required this.attrValue,
    required this.text,
    required this.comment,
    required this.cdata,
  });

  factory _XmlColors.of(ThemeData theme) {
    final scheme = theme.colorScheme;
    return _XmlColors(
      punctuation: scheme.onSurfaceVariant,
      tag: scheme.primary,
      attrName: scheme.secondary,
      attrValue: scheme.tertiary,
      text: scheme.onSurface,
      comment: scheme.onSurfaceVariant,
      cdata: scheme.error,
    );
  }
}
