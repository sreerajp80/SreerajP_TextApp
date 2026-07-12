import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import 'json_document_session.dart';
import 'json_editor_surface.dart';
import 'json_pretty_view.dart';
import 'json_session_manager.dart';
import 'json_tree_view.dart';

/// The body shown inside a JSON tab: it loads the document then shows the
/// pretty / tree / raw / minified / editor view — never a crash (CLAUDE.md §3.4).
///
/// The [JsonDocumentSession] lives in the [JsonSessionManager], so content, undo
/// history, scroll, and view mode survive switching between tabs.
class JsonDocumentView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const JsonDocumentView({super.key, required this.tab});

  @override
  ConsumerState<JsonDocumentView> createState() => _JsonDocumentViewState();
}

class _JsonDocumentViewState extends ConsumerState<JsonDocumentView> {
  void _retry() {
    ref.read(jsonSessionManagerProvider).release(widget.tab.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(jsonSessionManagerProvider).sessionFor(widget.tab);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.status) {
          case JsonLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case JsonLoadStatus.failed:
            return _FailureView(
              message: session.errorMessage ??
                  AppLocalizations.of(context).failCannotOpen,
              onRetry: _retry,
            );
          case JsonLoadStatus.ready:
            return _ReadyView(tab: widget.tab, session: session);
        }
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  final DocumentTab tab;
  final JsonDocumentSession session;

  const _ReadyView({required this.tab, required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (session.isNdjson) _NdjsonBanner(count: session.ndjsonCount),
        if (session.lenientOnly) _LenientBanner(session: session),
        if (session.draftAvailable) _DraftBanner(session: session),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final canEdit = !tab.isReadOnly;
    switch (session.mode) {
      case JsonViewMode.pretty:
        return JsonPrettyView(session: session);
      case JsonViewMode.minified:
        return JsonMinifiedView(session: session);
      case JsonViewMode.raw:
        return JsonEditorSurface(session: session, readOnly: true);
      case JsonViewMode.tree:
        return _TreeWithSearch(session: session, editing: canEdit);
      case JsonViewMode.edit:
        return JsonEditorSurface(session: session, readOnly: !canEdit);
    }
  }
}

/// The tree view with a search box above it that drives the session filter
/// (task 8.3). Kept here so the tree widget itself stays a pure list.
class _TreeWithSearch extends StatelessWidget {
  final JsonDocumentSession session;
  final bool editing;

  const _TreeWithSearch({required this.session, required this.editing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            key: const Key('json-tree-search'),
            decoration: InputDecoration(
              isDense: true,
              hintText: AppLocalizations.of(context).jsonTreeFilterHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: session.setTreeFilter,
          ),
        ),
        Expanded(child: JsonTreeView(session: session, editing: editing)),
      ],
    );
  }
}

class _NdjsonBanner extends StatelessWidget {
  final int count;
  const _NdjsonBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.view_stream_outlined,
              size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).jsonNdjsonBanner(count),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _LenientBanner extends StatelessWidget {
  final JsonDocumentSession session;
  const _LenientBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).jsonLenientBanner,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: session.formatDocument,
            child: Text(AppLocalizations.of(context).jsonMakeStrict),
          ),
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  final JsonDocumentSession session;

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
