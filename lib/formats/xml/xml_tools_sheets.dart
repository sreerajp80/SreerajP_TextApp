import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/xml/xml_document_session.dart';
import 'package:sreerajp_textapp/formats/xml/xml_path.dart';
import 'package:sreerajp_textapp/formats/xml/xml_quick_fix.dart';

/// A bottom sheet to run an XPath query against the document and copy the paths
/// of matches (task 9.3).
///
/// [initialQuery] pre-fills the box and runs straight away — that is how a
/// query built in the visual builder (roadmap §4.3.2) arrives here.
Future<void> showXmlPathSheet(
  BuildContext context,
  XmlDocumentSession session, {
  String? initialQuery,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _XPathBody(session: session, initialQuery: initialQuery),
    ),
  );
}

class _XPathBody extends StatefulWidget {
  final XmlDocumentSession session;
  final String? initialQuery;

  const _XPathBody({required this.session, this.initialQuery});

  @override
  State<_XPathBody> createState() => _XPathBodyState();
}

class _XPathBodyState extends State<_XPathBody> {
  late final _controller = TextEditingController(
    text: widget.initialQuery ?? '//',
  );
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
    final document = widget.session.document;
    if (document == null) {
      setState(() {
        _error = AppLocalizations.of(context).xmlNotWellFormedDoc;
        _matches = const [];
      });
      return;
    }
    final result = evaluateXPath(document, _controller.text);
    setState(() {
      _error = result.error;
      _matches = result.matches.map(xmlPathOf).toList();
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
            Text(
              l10n.xmlXPathTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (_) => _run(),
                    decoration: InputDecoration(
                      hintText: l10n.xmlXPathHint,
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
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
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

/// Shows the well-formedness of the document. Full XSD schema validation is a
/// planned follow-up done via a native platform channel (plan §3.6); this sheet
/// makes that explicit so the button is never dead (task 9.4).
Future<void> showXmlValidateSheet(
  BuildContext context,
  XmlDocumentSession session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      final wellFormed = session.isWellFormed;
      final line = session.validationLine;
      final error = session.validationError ?? '';
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
                    wellFormed
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: wellFormed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wellFormed
                          ? l10n.xmlWellFormedYes
                          : (line != null && line > 0
                                ? l10n.xmlNotWellFormedWithLine(line, error)
                                : l10n.xmlNotWellFormedNoLine(error)),
                    ),
                  ),
                ],
              ),
              if (!wellFormed) _XmlQuickFixes(session: session),
              const SizedBox(height: 12),
              Text(
                l10n.xmlXsdComing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The 1-tap repairs offered for a document that is not well-formed
/// (roadmap §4.3.3).
///
/// Each button rewrites the buffer through the session, so the change is a
/// normal edit the user can undo and still has to save — nothing is written to
/// disk here.
class _XmlQuickFixes extends StatefulWidget {
  final XmlDocumentSession session;

  const _XmlQuickFixes({required this.session});

  @override
  State<_XmlQuickFixes> createState() => _XmlQuickFixesState();
}

class _XmlQuickFixesState extends State<_XmlQuickFixes> {
  String _labelFor(AppLocalizations l10n, String id) {
    switch (id) {
      case XmlQuickFixes.closeTags:
        return l10n.xmlFixCloseTags;
      case XmlQuickFixes.escapeAmpersands:
        return l10n.xmlFixEscapeAmpersands;
      case XmlQuickFixes.wrapRoot:
        return l10n.xmlFixWrapRoot;
      case XmlQuickFixes.trimBeforeDeclaration:
        return l10n.xmlFixTrimJunk;
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
    final fixes = XmlQuickFixes.forSource(source);
    final all = XmlQuickFixes.fixAll(source);
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
                key: const Key('xml-fix-all'),
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
