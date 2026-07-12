import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import 'csv_document_session.dart';
import 'csv_grid.dart';
import 'csv_raw_view.dart';
import 'csv_session_manager.dart';

/// The body shown inside a CSV tab: it loads the document then shows the data
/// grid or the raw delimited text — never a crash (CLAUDE.md §3.4).
///
/// The [CsvDocumentSession] lives in the [CsvSessionManager], so the table, undo
/// history, sort / filter, and selection survive switching between tabs.
class CsvDocumentView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const CsvDocumentView({super.key, required this.tab});

  @override
  ConsumerState<CsvDocumentView> createState() => _CsvDocumentViewState();
}

class _CsvDocumentViewState extends ConsumerState<CsvDocumentView> {
  void _retry() {
    ref.read(csvSessionManagerProvider).release(widget.tab.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(csvSessionManagerProvider).sessionFor(widget.tab);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.status) {
          case CsvLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case CsvLoadStatus.failed:
            return _FailureView(
              message: session.errorMessage ??
                  AppLocalizations.of(context).failCannotOpen,
              onRetry: _retry,
            );
          case CsvLoadStatus.ready:
            return _ReadyView(tab: widget.tab, session: session);
        }
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  final DocumentTab tab;
  final CsvDocumentSession session;

  const _ReadyView({required this.tab, required this.session});

  @override
  Widget build(BuildContext context) {
    final editable = !tab.isReadOnly;
    return Column(
      children: [
        if (session.draftAvailable) _DraftBanner(session: session),
        Expanded(
          child: switch (session.mode) {
            CsvViewMode.table => CsvGrid(session: session, editable: editable),
            CsvViewMode.raw =>
              CsvRawView(session: session, readOnly: !editable),
          },
        ),
      ],
    );
  }
}

class _DraftBanner extends StatelessWidget {
  final CsvDocumentSession session;

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
