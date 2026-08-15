import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/formats/json/json_document_session.dart';
import 'package:text_data/formats/json/json_path.dart';
import 'package:text_data/formats/json/json_query_builder.dart';

/// The visual JSONPath builder (roadmap §4.3.2).
///
/// Instead of typing `$..users[*].name`, the user taps the keys and positions
/// the open document actually has. The built query and its live match count are
/// always on screen, so the syntax is learned by seeing it rather than looked
/// up. "Use this query" hands the finished text back to the caller.
Future<String?> showJsonQueryBuilderSheet(
  BuildContext context,
  JsonDocumentSession session,
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
  final JsonDocumentSession session;
  final ScrollController scrollController;

  const _BuilderBody({required this.session, required this.scrollController});

  @override
  State<_BuilderBody> createState() => _BuilderBodyState();
}

class _BuilderBodyState extends State<_BuilderBody> {
  final List<JsonQueryStep> _steps = [];

  String get _query => JsonQueryBuilder.buildQuery(_steps);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final root = widget.session.root;

    if (root == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.jsonNotValidDoc, textAlign: TextAlign.center),
      );
    }

    final matches = JsonQueryBuilder.resolve(root, _steps);
    final choices = JsonQueryBuilder.suggestions(root, _steps);
    final deepKeys = JsonQueryBuilder.deepKeys(root, _steps);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.jsonQueryBuilderTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // The query being built, always visible.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _query,
                  key: const Key('json-query-preview'),
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
              if (choices.isEmpty && deepKeys.isEmpty)
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
              if (deepKeys.isNotEmpty) ...[
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
                    for (final key in deepKeys)
                      ActionChip(
                        label: Text('..$key'),
                        onPressed: () => setState(
                          () => _steps.add(JsonQueryStep.anyDepthKey(key)),
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
                    pathOf(node),
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
                    key: const Key('json-query-use'),
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
