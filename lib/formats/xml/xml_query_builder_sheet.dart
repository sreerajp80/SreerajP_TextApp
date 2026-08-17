import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/xml/xml_document_session.dart';
import 'package:sreerajp_textapp/formats/xml/xml_path.dart';
import 'package:sreerajp_textapp/formats/xml/xml_query_builder.dart';

/// The visual XPath builder (roadmap §4.3.2) — the twin of the JSON one.
///
/// The user taps element names, positions and attributes the open document
/// really has; the expression and its live match count stay on screen. "Use
/// this query" hands the finished XPath back to the caller.
Future<String?> showXmlQueryBuilderSheet(
  BuildContext context,
  XmlDocumentSession session,
) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _BuilderBody(session: session, scrollController: controller),
    ),
  );
}

class _BuilderBody extends StatefulWidget {
  final XmlDocumentSession session;
  final ScrollController scrollController;

  const _BuilderBody({required this.session, required this.scrollController});

  @override
  State<_BuilderBody> createState() => _BuilderBodyState();
}

class _BuilderBodyState extends State<_BuilderBody> {
  final List<XmlQueryStep> _steps = [];

  String get _query => XmlQueryBuilder.buildQuery(_steps);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final document = widget.session.document;

    if (document == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.xmlNotWellFormedDoc, textAlign: TextAlign.center),
      );
    }

    final matches = XmlQueryBuilder.resolve(document, _steps);
    final choices = XmlQueryBuilder.suggestions(document, _steps);
    final deepNames = XmlQueryBuilder.deepElementNames(document, _steps);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.xmlQueryBuilderTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _query,
                  key: const Key('xml-query-preview'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.xmlMatchCount(matches.length),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (_steps.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _steps.removeLast()),
                      child: Text(l10n.jsonQueryStepBack),
                    ),
                  if (_steps.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_steps.clear),
                      child: Text(l10n.jsonQueryStartOver),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (choices.isEmpty && deepNames.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    matches.isEmpty
                        ? l10n.jsonQueryNoMatches
                        : l10n.jsonQueryNothingDeeper,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (choices.isNotEmpty) ...[
                Text(l10n.jsonQueryGoInto, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in choices)
                      ActionChip(
                        label: Text('${choice.label}  ·  ${choice.detail}'),
                        onPressed: () =>
                            setState(() => _steps.add(choice.step)),
                      ),
                  ],
                ),
              ],
              if (deepNames.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.jsonQueryAtAnyDepth,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in deepNames)
                      ActionChip(
                        label: Text('//$name'),
                        onPressed: () => setState(
                          () => _steps
                            ..clear()
                            ..add(XmlQueryStep.anyDepthElement(name)),
                        ),
                      ),
                  ],
                ),
              ],
              if (matches.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.jsonQueryMatchesHeading,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                for (final node in matches.take(20))
                  Text(
                    xmlPathOf(node),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _query)),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.actionCopy),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const Key('xml-query-use'),
                    onPressed: () => Navigator.of(context).pop(_query),
                    child: Text(l10n.jsonQueryUse),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
