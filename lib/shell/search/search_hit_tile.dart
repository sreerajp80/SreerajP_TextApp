import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/core/index/search_index_models.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/home/file_type_icon.dart';

/// One row in the workspace search results: the file, a snippet of the matching
/// text with the match highlighted, and — when the file can no longer be opened
/// — a note with a way to drop it from the index (Feature 11).
class SearchHitTile extends StatelessWidget {
  final SearchHit hit;

  /// Resolves whether the file behind the hit is still reachable. Null means
  /// "do not check" (used by tests and by the not-yet-resolved case).
  final Future<bool>? available;

  final VoidCallback onOpen;
  final VoidCallback onForget;

  const SearchHitTile({
    super.key,
    required this.hit,
    required this.onOpen,
    required this.onForget,
    this.available,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final check = available;

    return FutureBuilder<bool>(
      future: check,
      initialData: true,
      builder: (context, snapshot) {
        // Treat "still loading" and "check failed" as available; a bad guess
        // only means the friendly open error shows instead of the note.
        final reachable = snapshot.data ?? true;
        return ListTile(
          isThreeLine: true,
          leading: Icon(fileTypeIcon(displayName: hit.displayName)),
          title: Text(
            hit.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Snippet(spans: hit.snippet),
              if (hit.truncated)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.searchWorkspacePartial,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (!reachable)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.searchWorkspaceUnavailable,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          onTap: reachable ? onOpen : onForget,
        );
      },
    );
  }
}

/// Draws a snippet, showing the matched words in the app's highlight colour.
class _Snippet extends StatelessWidget {
  final List<SnippetSpan> spans;

  const _Snippet({required this.spans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style: span.highlighted
                  ? base?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      fontWeight: FontWeight.w600,
                    )
                  : base,
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
