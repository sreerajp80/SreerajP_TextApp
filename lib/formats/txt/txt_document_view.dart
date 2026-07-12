import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import 'txt_document_session.dart';
import 'txt_editor_surface.dart';
import 'txt_session_manager.dart';

/// The body shown inside a TXT tab: it loads the document and then shows the
/// viewer/editor, a friendly failure screen, or a loading spinner — never a
/// crash (CLAUDE.md §3.4).
///
/// The [TxtDocumentSession] lives in the [TxtSessionManager], so the editor's
/// content, undo history, and scroll survive switching between tabs.
class TxtDocumentView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const TxtDocumentView({super.key, required this.tab});

  @override
  ConsumerState<TxtDocumentView> createState() => _TxtDocumentViewState();
}

class _TxtDocumentViewState extends ConsumerState<TxtDocumentView> {
  void _retry() {
    ref.read(txtSessionManagerProvider).release(widget.tab.id);
    setState(() {}); // rebuild → a fresh session is created and reloaded
  }

  @override
  Widget build(BuildContext context) {
    final session =
        ref.read(txtSessionManagerProvider).sessionFor(widget.tab);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.status) {
          case TxtLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case TxtLoadStatus.failed:
            return _FailureView(
              message: session.errorMessage ??
                  AppLocalizations.of(context).failCannotOpen,
              onRetry: _retry,
            );
          case TxtLoadStatus.ready:
            return _ReadyView(tab: widget.tab, session: session);
        }
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  final DocumentTab tab;
  final TxtDocumentSession session;

  const _ReadyView({required this.tab, required this.session});

  @override
  Widget build(BuildContext context) {
    final readOnly =
        tab.isReadOnly || session.viewMode == TabViewMode.view;
    return Column(
      children: [
        if (session.binaryWarning) const _BinaryWarningBanner(),
        if (session.draftAvailable) _DraftBanner(session: session),
        Expanded(
          child: TxtEditorSurface(session: session, readOnly: readOnly),
        ),
      ],
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
            Icon(Icons.error_outline,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.failCantOpenTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: Text(l10n.actionRetry)),
          ],
        ),
      ),
    );
  }
}

class _BinaryWarningBanner extends StatelessWidget {
  const _BinaryWarningBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber,
              size: 18, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).txtBinaryWarning,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  final TxtDocumentSession session;

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
