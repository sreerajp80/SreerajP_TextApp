import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/editor/encoding.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import 'json_diff.dart';
import 'json_document_session.dart';
import 'json_parser.dart';
import 'json_path.dart';
import 'json_quick_fix.dart';
import 'json_schema_validator.dart';

/// A bottom sheet to run a JSONPath query against the document and jump to /
/// copy matches (task 8.3).
///
/// [initialQuery] pre-fills the box and runs straight away — that is how a
/// query built in the visual builder (roadmap §4.3.2) arrives here.
Future<void> showJsonPathSheet(
  BuildContext context,
  JsonDocumentSession session, {
  String? initialQuery,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _JsonPathBody(session: session, initialQuery: initialQuery),
    ),
  );
}

class _JsonPathBody extends StatefulWidget {
  final JsonDocumentSession session;
  final String? initialQuery;

  const _JsonPathBody({required this.session, this.initialQuery});

  @override
  State<_JsonPathBody> createState() => _JsonPathBodyState();
}

class _JsonPathBodyState extends State<_JsonPathBody> {
  late final _controller =
      TextEditingController(text: widget.initialQuery ?? r'$..');
  String? _error;
  List<String> _matches = const [];

  @override
  void initState() {
    super.initState();
    // A query handed over from the builder is already what the user wants, so
    // show its result without making them tap Run.
    if (widget.initialQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _run();
      });
    }
  }

  void _run() {
    final root = widget.session.root;
    if (root == null) {
      setState(() {
        _error = AppLocalizations.of(context).jsonNotValidDoc;
        _matches = const [];
      });
      return;
    }
    final result = evaluateJsonPath(root, _controller.text);
    setState(() {
      _error = result.error;
      _matches = result.matches.map(pathOf).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.jsonPathTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (_) => _run(),
                    decoration: InputDecoration(
                      hintText: l10n.jsonPathHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _run, child: Text(l10n.xmlRun)),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error))
            else
              Text(l10n.xmlMatchCount(_matches.length)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final path in _matches)
                    ListTile(
                      dense: true,
                      title: Text(path),
                      trailing: const Icon(Icons.copy, size: 16),
                      onTap: () => Clipboard.setData(ClipboardData(text: path)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the strict validity of the document and lets the user validate it
/// against a picked JSON Schema file (task 8.4).
Future<void> showJsonValidateSheet(
  BuildContext context,
  JsonDocumentSession session,
  SafService saf,
  TextCodecService codec,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        _ValidateBody(session: session, saf: saf, codec: codec),
  );
}

class _ValidateBody extends StatefulWidget {
  final JsonDocumentSession session;
  final SafService saf;
  final TextCodecService codec;

  const _ValidateBody({
    required this.session,
    required this.saf,
    required this.codec,
  });

  @override
  State<_ValidateBody> createState() => _ValidateBodyState();
}

class _ValidateBodyState extends State<_ValidateBody> {
  List<JsonSchemaError>? _schemaErrors;
  String? _note;

  Future<void> _validateAgainstSchema() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final root = widget.session.root;
    if (root == null) {
      setState(() => _note = l10n.jsonFixErrorsFirst);
      return;
    }
    SafFile file;
    try {
      file = await widget.saf
          .pickFile(mimeTypes: const ['application/json', 'text/*']);
    } on SafCancelled {
      return;
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    try {
      final bytes = await widget.saf.readBytes(file.uri);
      final schemaText = widget.codec.detectAndDecode(bytes).text;
      final schema = jsonDecode(schemaText);
      final errors = const JsonSchemaValidator().validate(root, schema);
      setState(() {
        _schemaErrors = errors;
        _note = errors.isEmpty ? l10n.jsonValidAgainstSchema : null;
      });
    } catch (_) {
      setState(() => _note = l10n.jsonSchemaReadError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final wellFormed = widget.session.isWellFormed;
    final line = widget.session.validationLine;
    final error = widget.session.validationError ?? '';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.xmlValidate, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  wellFormed ? Icons.check_circle_outline : Icons.error_outline,
                  color: wellFormed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(wellFormed
                      ? l10n.jsonWellFormed
                      : (line != null
                          ? l10n.jsonNotValidWithLine(line, error)
                          : l10n.jsonNotValidNoLine(error))),
                ),
              ],
            ),
            if (!wellFormed) _QuickFixes(session: widget.session),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _validateAgainstSchema,
              icon: const Icon(Icons.rule),
              label: Text(l10n.jsonValidateAgainstSchema),
            ),
            if (_note != null) ...[
              const SizedBox(height: 8),
              Text(_note!),
            ],
            if (_schemaErrors != null && _schemaErrors!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.jsonSchemaErrors(_schemaErrors!.length),
                  style: theme.textTheme.titleSmall),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final error in _schemaErrors!)
                      ListTile(
                        dense: true,
                        title: Text(error.path),
                        subtitle: Text(error.message),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The 1-tap repairs offered for a document that is not strict JSON
/// (roadmap §4.3.3).
///
/// Each button rewrites the buffer through the session, so the change is a
/// normal edit the user can undo and must still save — nothing is written to
/// disk here. The list refreshes after every tap, so fixing one problem reveals
/// what is left.
class _QuickFixes extends StatefulWidget {
  final JsonDocumentSession session;

  const _QuickFixes({required this.session});

  @override
  State<_QuickFixes> createState() => _QuickFixesState();
}

class _QuickFixesState extends State<_QuickFixes> {
  String _labelFor(AppLocalizations l10n, String id) {
    switch (id) {
      case JsonQuickFixes.quoteKeys:
        return l10n.jsonFixQuoteKeys;
      case JsonQuickFixes.doubleQuotes:
        return l10n.jsonFixDoubleQuotes;
      case JsonQuickFixes.trailingCommas:
        return l10n.jsonFixTrailingCommas;
      case JsonQuickFixes.removeComments:
        return l10n.jsonFixRemoveComments;
      case JsonQuickFixes.pythonLiterals:
        return l10n.jsonFixPythonLiterals;
      default:
        return l10n.jsonFixEverything;
    }
  }

  void _apply(String newSource) {
    widget.session.applySource(newSource);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final source = widget.session.code?.text ?? '';
    final fixes = JsonQuickFixes.forSource(source);
    final all = JsonQuickFixes.fixAll(source);
    if (fixes.isEmpty && all == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.jsonQuickFixes, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (all != null)
              FilledButton.tonalIcon(
                key: const Key('json-fix-all'),
                onPressed: () => _apply(all.result),
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: Text(l10n.jsonFixEverything),
              ),
            for (final fix in fixes)
              OutlinedButton(
                onPressed: () => _apply(fix.result),
                child: Text(_labelFor(l10n, fix.id)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Picks a second JSON file and shows the difference from this document
/// (task 8.6).
Future<void> showJsonDiffSheet(
  BuildContext context,
  JsonDocumentSession session,
  SafService saf,
  TextCodecService codec,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final root = session.root;
  if (root == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.jsonFixBeforeCompare)),
    );
    return;
  }
  SafFile file;
  try {
    file = await saf.pickFile(mimeTypes: const ['application/json', 'text/*']);
  } on SafCancelled {
    return;
  } on SafException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }

  JsonDiffResult diffResult;
  try {
    final bytes = await saf.readBytes(file.uri);
    final text = codec.detectAndDecode(bytes).text;
    final other = const JsonParser().parse(text, lenient: true);
    if (!other.ok || other.root == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.jsonOtherNotValid)),
      );
      return;
    }
    diffResult = const JsonDiff().compare(root, other.root!);
  } on SafException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _DiffBody(name: file.displayName, result: diffResult),
  );
}

class _DiffBody extends StatelessWidget {
  final String name;
  final JsonDiffResult result;

  const _DiffBody({required this.name, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.jsonDiffWith(name), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(result.isEmpty
                ? l10n.jsonIdentical
                : l10n.jsonDiffSummary(result.added.length,
                    result.removed.length, result.changed.length)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ..._section(theme, l10n, l10n.jsonDiffAdded, result.added,
                      theme.colorScheme.primary),
                  ..._section(theme, l10n, l10n.jsonDiffRemoved, result.removed,
                      theme.colorScheme.error),
                  ..._section(theme, l10n, l10n.jsonDiffChanged, result.changed,
                      theme.colorScheme.tertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(ThemeData theme, AppLocalizations l10n, String title,
      List<String> paths, Color color) {
    if (paths.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(l10n.jsonDiffSection(title, paths.length),
            style: theme.textTheme.titleSmall?.copyWith(color: color)),
      ),
      for (final path in paths)
        Text(path, style: const TextStyle(fontFamily: 'monospace')),
    ];
  }
}
