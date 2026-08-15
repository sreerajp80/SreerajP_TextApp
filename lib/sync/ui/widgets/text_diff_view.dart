import 'package:flutter/material.dart';
import 'package:text_data/sync/diff/diff_models.dart';
import 'package:text_data/sync/diff/live_diff_controller.dart';

/// Renders line-by-line text diff in Unified or Side-by-Side split modes.
class TextDiffView extends StatelessWidget {
  final LiveDiffController controller;
  final bool isSplitView;

  const TextDiffView({
    super.key,
    required this.controller,
    required this.isSplitView,
  });

  @override
  Widget build(BuildContext context) {
    final textDiff = controller.textDiff;
    if (textDiff == null || textDiff.hunks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No differences found. Documents are identical.'),
        ),
      );
    }

    if (isSplitView) {
      return _SideBySideDiffList(controller: controller, diff: textDiff);
    } else {
      return _UnifiedDiffList(controller: controller, diff: textDiff);
    }
  }
}

class _UnifiedDiffList extends StatelessWidget {
  final LiveDiffController controller;
  final TextDiffResult diff;

  const _UnifiedDiffList({required this.controller, required this.diff});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: diff.hunks.length,
      itemBuilder: (context, index) {
        final hunk = diff.hunks[index];
        return _HunkCard(controller: controller, hunk: hunk, theme: theme);
      },
    );
  }
}

class _HunkCard extends StatelessWidget {
  final LiveDiffController controller;
  final DiffHunk hunk;
  final ThemeData theme;

  const _HunkCard({
    required this.controller,
    required this.hunk,
    required this.theme,
  });

  Color _getHunkColor() {
    switch (hunk.type) {
      case DiffType.added:
        return Colors.green.withValues(alpha: 0.12);
      case DiffType.deleted:
        return Colors.red.withValues(alpha: 0.12);
      case DiffType.modified:
        return Colors.amber.withValues(alpha: 0.12);
      case DiffType.unchanged:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: hunk.hasChanges
              ? (hunk.isUnresolved
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.primary.withValues(alpha: 0.5))
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: hunk.hasChanges
          ? _getHunkColor()
          : (isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  )
                : theme.colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hunk.hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hunk.type == DiffType.added
                        ? Icons.add_circle_outline
                        : hunk.type == DiffType.deleted
                        ? Icons.remove_circle_outline
                        : Icons.change_circle_outlined,
                    size: 16,
                    color: hunk.type == DiffType.added
                        ? Colors.green
                        : hunk.type == DiffType.deleted
                        ? Colors.red
                        : Colors.amber[800],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Line ${hunk.startLocalLine} · ${hunk.type.name.toUpperCase()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _HunkActionButtons(controller: controller, hunk: hunk),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: hunk.lines.map((line) => _LineRow(line: line)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HunkActionButtons extends StatelessWidget {
  final LiveDiffController controller;
  final DiffHunk hunk;

  const _HunkActionButtons({required this.controller, required this.hunk});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        ChoiceChip(
          visualDensity: VisualDensity.compact,
          label: const Text('← Mine'),
          selected: hunk.resolution == HunkResolution.acceptLocal,
          onSelected: (_) =>
              controller.resolveHunk(hunk.id, HunkResolution.acceptLocal),
        ),
        ChoiceChip(
          visualDensity: VisualDensity.compact,
          label: const Text('Peer →'),
          selected: hunk.resolution == HunkResolution.acceptRemote,
          onSelected: (_) =>
              controller.resolveHunk(hunk.id, HunkResolution.acceptRemote),
        ),
        ChoiceChip(
          visualDensity: VisualDensity.compact,
          label: const Text('Both'),
          selected: hunk.resolution == HunkResolution.acceptBoth,
          onSelected: (_) =>
              controller.resolveHunk(hunk.id, HunkResolution.acceptBoth),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final DiffLine line;

  const _LineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? bg;
    if (line.type == DiffType.added) {
      bg = isDark
          ? Colors.green[900]?.withValues(alpha: 0.3)
          : Colors.green[50];
    } else if (line.type == DiffType.deleted) {
      bg = isDark ? Colors.red[900]?.withValues(alpha: 0.3) : Colors.red[50];
    } else if (line.type == DiffType.modified) {
      bg = isDark
          ? Colors.amber[900]?.withValues(alpha: 0.3)
          : Colors.amber[50];
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              line.localLineNumber?.toString() ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              line.remoteLineNumber?.toString() ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            line.type == DiffType.added
                ? '+'
                : line.type == DiffType.deleted
                ? '-'
                : line.type == DiffType.modified
                ? '~'
                : ' ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: line.type == DiffType.added
                  ? Colors.green
                  : line.type == DiffType.deleted
                  ? Colors.red
                  : line.type == DiffType.modified
                  ? Colors.amber[800]
                  : Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                children: _buildInlineSpans(line, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildInlineSpans(DiffLine line, bool isDark) {
    if (line.type == DiffType.modified) {
      final spans = <TextSpan>[
        const TextSpan(
          text: 'Mine: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ];
      for (final seg in line.localSegments) {
        spans.add(
          TextSpan(
            text: seg.text,
            style: TextStyle(
              backgroundColor: seg.isChanged
                  ? (isDark
                        ? Colors.red[800]?.withValues(alpha: 0.6)
                        : Colors.red[200])
                  : null,
            ),
          ),
        );
      }
      spans.add(
        const TextSpan(
          text: '\nPeer: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      for (final seg in line.remoteSegments) {
        spans.add(
          TextSpan(
            text: seg.text,
            style: TextStyle(
              backgroundColor: seg.isChanged
                  ? (isDark
                        ? Colors.green[800]?.withValues(alpha: 0.6)
                        : Colors.green[200])
                  : null,
            ),
          ),
        );
      }
      return spans;
    } else if (line.type == DiffType.added) {
      return [TextSpan(text: line.remoteText)];
    } else {
      return [TextSpan(text: line.localText)];
    }
  }
}

class _SideBySideDiffList extends StatelessWidget {
  final LiveDiffController controller;
  final TextDiffResult diff;

  const _SideBySideDiffList({required this.controller, required this.diff});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Local Document (Mine)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: Text(
                  'Remote Document (Peer)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: diff.lines.length,
            itemBuilder: (context, index) {
              final line = diff.lines[index];
              return _SideBySideRow(line: line);
            },
          ),
        ),
      ],
    );
  }
}

class _SideBySideRow extends StatelessWidget {
  final DiffLine line;

  const _SideBySideRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final localBg =
        line.type == DiffType.deleted || line.type == DiffType.modified
        ? (isDark ? Colors.red[900]?.withValues(alpha: 0.25) : Colors.red[50])
        : null;

    final remoteBg =
        line.type == DiffType.added || line.type == DiffType.modified
        ? (isDark
              ? Colors.green[900]?.withValues(alpha: 0.25)
              : Colors.green[50])
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: localBg,
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      line.localLineNumber?.toString() ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.localText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Container(
              color: remoteBg,
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      line.remoteLineNumber?.toString() ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.remoteText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
