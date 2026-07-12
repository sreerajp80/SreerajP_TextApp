import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import 'xml_document_session.dart';
import 'xml_editor_surface.dart';
import 'xml_pretty_view.dart';
import 'xml_session_manager.dart';
import 'xml_tree_view.dart';

/// The body shown inside an XML tab: it loads the document then shows the
/// pretty / tree / raw / editor view — never a crash (CLAUDE.md §3.4).
///
/// The [XmlDocumentSession] lives in the [XmlSessionManager], so content, undo
/// history, scroll, and view mode survive switching between tabs.
class XmlDocumentView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const XmlDocumentView({super.key, required this.tab});

  @override
  ConsumerState<XmlDocumentView> createState() => _XmlDocumentViewState();
}

class _XmlDocumentViewState extends ConsumerState<XmlDocumentView> {
  void _retry() {
    ref.read(xmlSessionManagerProvider).release(widget.tab.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(xmlSessionManagerProvider).sessionFor(widget.tab);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.status) {
          case XmlLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case XmlLoadStatus.failed:
            return _FailureView(
              message: session.errorMessage ??
                  AppLocalizations.of(context).failCannotOpen,
              onRetry: _retry,
            );
          case XmlLoadStatus.ready:
            return _ReadyView(tab: widget.tab, session: session);
        }
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  final DocumentTab tab;
  final XmlDocumentSession session;

  const _ReadyView({required this.tab, required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (session.draftAvailable) _DraftBanner(session: session),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final canEdit = !tab.isReadOnly;
    switch (session.mode) {
      case XmlViewMode.pretty:
        return XmlPrettyView(session: session);
      case XmlViewMode.raw:
        return XmlEditorSurface(session: session, readOnly: true);
      case XmlViewMode.tree:
        return _TreeWithSearch(session: session, editing: canEdit);
      case XmlViewMode.edit:
        return XmlEditorSurface(session: session, readOnly: !canEdit);
    }
  }
}

/// The tree view with a search box above it that drives the session filter
/// (task 9.3). Kept here so the tree widget itself stays a pure list.
class _TreeWithSearch extends StatelessWidget {
  final XmlDocumentSession session;
  final bool editing;

  const _TreeWithSearch({required this.session, required this.editing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            key: const Key('xml-tree-search'),
            decoration: InputDecoration(
              isDense: true,
              hintText: AppLocalizations.of(context).xmlTreeFilterHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: session.setTreeFilter,
          ),
        ),
        Expanded(child: XmlTreeView(session: session, editing: editing)),
      ],
    );
  }
}

class _DraftBanner extends StatelessWidget {
  final XmlDocumentSession session;

  const _DraftBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      child: Row(
        children: [
          Icon(Icons.history,
              size: 18, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.draftBannerText,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: session.restoreDraft,
            child: Text(l10n.actionRestore),
          ),
          TextButton(
            onPressed: session.discardDraft,
            child: Text(l10n.actionDiscard),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.failCantOpenTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: Text(l10n.actionRetry)),
          ],
        ),
      ),
    );
  }
}
