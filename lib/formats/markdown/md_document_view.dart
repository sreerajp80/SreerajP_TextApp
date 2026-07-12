import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import 'md_document_session.dart';
import 'md_editor_surface.dart';
import 'md_front_matter.dart';
import 'md_live_preview.dart';
import 'md_preview_view.dart';
import 'md_session_manager.dart';

/// The body shown inside a Markdown tab: it loads the document then shows the
/// rendered preview, the raw source, or the editor — never a crash
/// (CLAUDE.md §3.4).
///
/// The [MdDocumentSession] lives in the [MdSessionManager], so content, undo
/// history, scroll, and view mode survive switching between tabs.
class MdDocumentView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const MdDocumentView({super.key, required this.tab});

  @override
  ConsumerState<MdDocumentView> createState() => _MdDocumentViewState();
}

class _MdDocumentViewState extends ConsumerState<MdDocumentView> {
  void _retry() {
    ref.read(mdSessionManagerProvider).release(widget.tab.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(mdSessionManagerProvider).sessionFor(widget.tab);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.status) {
          case MdLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case MdLoadStatus.failed:
            return _FailureView(
              message: session.errorMessage ??
                  AppLocalizations.of(context).mdCannotOpenFile,
              onRetry: _retry,
            );
          case MdLoadStatus.ready:
            return _ReadyView(tab: widget.tab, session: session);
        }
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  final DocumentTab tab;
  final MdDocumentSession session;

  const _ReadyView({required this.tab, required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (session.frontMatter.present)
          _FrontMatterBanner(frontMatter: session.frontMatter),
        if (session.draftAvailable) _DraftBanner(session: session),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    // A read-only tab can never enter the source editor.
    switch (session.mode) {
      case MdMode.rendered:
        return MdPreviewView(session: session);
      case MdMode.raw:
        return MdEditorSurface(session: session, readOnly: true);
      case MdMode.edit:
        if (tab.isReadOnly) {
          return MdEditorSurface(session: session, readOnly: true);
        }
        return MdLivePreview(session: session);
    }
  }
}

class _FrontMatterBanner extends StatelessWidget {
  final MdFrontMatter frontMatter;

  const _FrontMatterBanner({required this.frontMatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = frontMatter.title;
    final author = frontMatter.author;
    final tags = frontMatter.tags;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (author != null)
            Text(
              AppLocalizations.of(context).mdByAuthor(author),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  final MdDocumentSession session;

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
              l10n.mdDraftFound,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: session.restoreDraft,
            child: Text(l10n.mdRestore),
          ),
          TextButton(
            onPressed: session.discardDraft,
            child: Text(l10n.mdDiscard),
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
            Text(l10n.mdCantOpenTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: Text(l10n.mdRetry)),
          ],
        ),
      ),
    );
  }
}
