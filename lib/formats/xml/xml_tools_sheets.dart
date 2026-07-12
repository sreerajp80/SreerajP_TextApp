import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'xml_document_session.dart';
import 'xml_path.dart';

/// A bottom sheet to run an XPath query against the document and copy the paths
/// of matches (task 9.3).
Future<void> showXmlPathSheet(
    BuildContext context, XmlDocumentSession session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _XPathBody(session: session),
    ),
  );
}

class _XPathBody extends StatefulWidget {
  final XmlDocumentSession session;
  const _XPathBody({required this.session});

  @override
  State<_XPathBody> createState() => _XPathBodyState();
}

class _XPathBodyState extends State<_XPathBody> {
  final _controller = TextEditingController(text: '//');
  String? _error;
  List<String> _matches = const [];

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
            Text(l10n.xmlXPathTitle,
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

/// Shows the well-formedness of the document. Full XSD schema validation is a
/// planned follow-up done via a native platform channel (plan §3.6); this sheet
/// makes that explicit so the button is never dead (task 9.4).
Future<void> showXmlValidateSheet(
    BuildContext context, XmlDocumentSession session) {
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
                    child: Text(wellFormed
                        ? l10n.xmlWellFormedYes
                        : (line != null && line > 0
                            ? l10n.xmlNotWellFormedWithLine(line, error)
                            : l10n.xmlNotWellFormedNoLine(error))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.xmlXsdComing,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    },
  );
}
