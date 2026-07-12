import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../l10n/app_localizations.dart';
import 'json_document_session.dart';
import 'json_node.dart';
import 'json_parser.dart';

/// The colour-coded, indented **pretty** view of a JSON document (task 8.1).
///
/// Built as rich text from the parsed tree (plan §3.2) — keys, strings, numbers,
/// and keywords each get a theme-aware colour, so it works in light / dark /
/// sepia with no extra package. When the document cannot be parsed at all a
/// friendly notice points the user to the editor (CLAUDE.md §3.4).
class JsonPrettyView extends ConsumerWidget {
  final JsonDocumentSession session;
  const JsonPrettyView({super.key, required this.session});

  static const double _baseFontSize = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = session.root;
    if (node == null) return _InvalidNotice(session: session);

    final theme = Theme.of(context);
    final appearance = ref.watch(themeControllerProvider);
    final colors = _JsonColors.of(theme);
    final spans = <InlineSpan>[];
    _build(node, spans, colors, session.indent.unit, 0);

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

  void _build(JsonNode node, List<InlineSpan> out, _JsonColors colors,
      String indentUnit, int depth) {
    switch (node.kind) {
      case JsonKind.object:
        if (node.children.isEmpty) {
          out.add(TextSpan(text: '{}', style: TextStyle(color: colors.punctuation)));
          return;
        }
        out.add(TextSpan(text: '{', style: TextStyle(color: colors.punctuation)));
        for (var i = 0; i < node.children.length; i++) {
          final child = node.children[i];
          out.add(TextSpan(text: '\n${indentUnit * (depth + 1)}'));
          out.add(TextSpan(
            text: encodeJsonString(child.key ?? ''),
            style: TextStyle(color: colors.key),
          ));
          out.add(TextSpan(text: ': ', style: TextStyle(color: colors.punctuation)));
          _build(child, out, colors, indentUnit, depth + 1);
          if (i != node.children.length - 1) {
            out.add(TextSpan(text: ',', style: TextStyle(color: colors.punctuation)));
          }
        }
        out.add(TextSpan(text: '\n${indentUnit * depth}}'));
        break;
      case JsonKind.array:
        if (node.children.isEmpty) {
          out.add(TextSpan(text: '[]', style: TextStyle(color: colors.punctuation)));
          return;
        }
        out.add(TextSpan(text: '[', style: TextStyle(color: colors.punctuation)));
        for (var i = 0; i < node.children.length; i++) {
          out.add(TextSpan(text: '\n${indentUnit * (depth + 1)}'));
          _build(node.children[i], out, colors, indentUnit, depth + 1);
          if (i != node.children.length - 1) {
            out.add(TextSpan(text: ',', style: TextStyle(color: colors.punctuation)));
          }
        }
        out.add(TextSpan(text: '\n${indentUnit * depth}]'));
        break;
      case JsonKind.string:
        out.add(TextSpan(
          text: encodeJsonString(node.stringValue ?? ''),
          style: TextStyle(color: colors.string),
        ));
        break;
      case JsonKind.number:
        out.add(TextSpan(text: node.rawText, style: TextStyle(color: colors.number)));
        break;
      case JsonKind.boolean:
      case JsonKind.nullValue:
        out.add(TextSpan(text: node.rawText, style: TextStyle(color: colors.keyword)));
        break;
    }
  }
}

/// The single-line **minified** view of a JSON document (task 8.1). Read-only and
/// horizontally scrollable; falls back to the raw text when unparseable.
class JsonMinifiedView extends ConsumerWidget {
  final JsonDocumentSession session;
  const JsonMinifiedView({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = session.root;
    final appearance = ref.watch(themeControllerProvider);
    final text = node != null ? minifyJson(node) : (session.code?.text ?? '');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: appearance.fontFamily ?? 'monospace',
          fontSize: 14 * appearance.fontScale,
        ),
      ),
    );
  }
}

class _InvalidNotice extends StatelessWidget {
  final JsonDocumentSession session;
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
            Text(l10n.jsonNotValidYet, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              line != null
                  ? l10n.jsonProblemNearLine(line)
                  : l10n.jsonOpenEditorToFix,
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

/// Theme-aware colours for JSON syntax, derived from the Material scheme so they
/// adapt to light / dark / sepia.
class _JsonColors {
  final Color punctuation;
  final Color key;
  final Color string;
  final Color number;
  final Color keyword;

  const _JsonColors({
    required this.punctuation,
    required this.key,
    required this.string,
    required this.number,
    required this.keyword,
  });

  factory _JsonColors.of(ThemeData theme) {
    final scheme = theme.colorScheme;
    return _JsonColors(
      punctuation: scheme.onSurfaceVariant,
      key: scheme.primary,
      string: scheme.tertiary,
      number: scheme.secondary,
      keyword: scheme.error,
    );
  }
}
