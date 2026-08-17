import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/sync/diff/live_diff_controller.dart';
import 'package:sreerajp_textapp/sync/ui/widgets/csv_diff_view.dart';
import 'package:sreerajp_textapp/sync/ui/widgets/text_diff_view.dart';

enum _ViewDisplayMode { sideBySide, unified, preview }

/// Main screen for Serverless P2P Live Document Diff & Delta Sync.
class LiveDiffScreen extends ConsumerStatefulWidget {
  final LiveDiffController controller;
  final void Function(String mergedText)? onApplyToEditor;

  const LiveDiffScreen({
    super.key,
    required this.controller,
    this.onApplyToEditor,
  });

  @override
  ConsumerState<LiveDiffScreen> createState() => _LiveDiffScreenState();
}

class _LiveDiffScreenState extends ConsumerState<LiveDiffScreen> {
  _ViewDisplayMode _displayMode = _ViewDisplayMode.unified;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Use side-by-side on wide screens by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final width = MediaQuery.of(context).size.width;
        if (width >= 600) {
          setState(() => _displayMode = _ViewDisplayMode.sideBySide);
        }
      }
    });
  }

  Future<void> _saveMergedDocument() async {
    final l10n = AppLocalizations.of(context);
    final merged = widget.controller.getMergedOutput();

    // If callback provided (e.g. from open tab), apply directly
    if (widget.onApplyToEditor != null) {
      widget.onApplyToEditor!(merged);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.liveDiffApplied),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    // Otherwise prompt to save to device storage via SAF
    setState(() => _isSaving = true);
    try {
      final saf = ref.read(safServiceProvider);
      final bytes = Uint8List.fromList(utf8.encode(merged));
      final destFile = await saf.createDocument(
        suggestedName: 'merged_${widget.controller.documentName}',
        bytes: bytes,
        mimeType: widget.controller.mimeType,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.liveDiffSavedAs(destFile.displayName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on SafCancelled {
      if (mounted) setState(() => _isSaving = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.liveDiffSaveFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final totalDiffs = ctrl.totalDifferences;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.documentName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ctrl.mode == DiffSessionMode.standalone
                      ? 'Local Diff & Merge'
                      : 'P2P Live Delta Sync (AES-256-GCM)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ctrl.mode == DiffSessionMode.standalone
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              SegmentedButton<_ViewDisplayMode>(
                segments: [
                  ButtonSegment(
                    value: _ViewDisplayMode.unified,
                    icon: const Icon(Icons.view_agenda_outlined, size: 16),
                    tooltip: l10n.liveDiffUnified,
                  ),
                  ButtonSegment(
                    value: _ViewDisplayMode.sideBySide,
                    icon: const Icon(Icons.view_column_outlined, size: 16),
                    tooltip: l10n.liveDiffSideBySide,
                  ),
                  ButtonSegment(
                    value: _ViewDisplayMode.preview,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    tooltip: l10n.liveDiffPreview,
                  ),
                ],
                selected: {_displayMode},
                onSelectionChanged: (s) {
                  setState(() => _displayMode = s.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              if (ctrl.mode != DiffSessionMode.standalone)
                IconButton(
                  tooltip: l10n.liveDiffPushToPeer,
                  icon: ctrl.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_to_mobile),
                  onPressed: ctrl.isSending ? null : ctrl.pushLocalToPeer,
                ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'auto') ctrl.autoMergeNonConflicting();
                  if (val == 'mine') ctrl.acceptAllMine();
                  if (val == 'peer') ctrl.acceptAllPeer();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'auto',
                    child: ListTile(
                      leading: const Icon(Icons.auto_fix_high),
                      title: Text(l10n.liveDiffAutoMergeClean),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mine',
                    child: ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: Text(l10n.liveDiffAcceptMine),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'peer',
                    child: ListTile(
                      leading: const Icon(Icons.arrow_forward),
                      title: Text(l10n.liveDiffAcceptPeer),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Diff Summary Header Banner
              _DiffStatsHeader(
                controller: ctrl,
                totalDiffs: totalDiffs,
                theme: theme,
              ),

              if (ctrl.peerUpdatedNotice)
                Container(
                  color: theme.colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peer transmitted fresh edits over P2P socket.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: ctrl.clearPeerNotice,
                      ),
                    ],
                  ),
                ),

              // Main Diff Viewer Body
              Expanded(
                child: _displayMode == _ViewDisplayMode.preview
                    ? _MergePreviewView(controller: ctrl)
                    : (ctrl.isCsv
                          ? CsvDiffView(controller: ctrl)
                          : TextDiffView(
                              controller: ctrl,
                              isSplitView:
                                  _displayMode == _ViewDisplayMode.sideBySide,
                            )),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: ctrl.autoMergeNonConflicting,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(l10n.liveDiffAutoMerge),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveMergedDocument,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text(
                      widget.onApplyToEditor != null
                          ? 'Apply to Document'
                          : 'Save Merged Copy',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiffStatsHeader extends StatelessWidget {
  final LiveDiffController controller;
  final int totalDiffs;
  final ThemeData theme;

  const _DiffStatsHeader({
    required this.controller,
    required this.totalDiffs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              controller.isCsv
                  ? 'CSV'
                  : controller.isMarkdown
                  ? 'MD'
                  : controller.isJson
                  ? 'JSON'
                  : controller.isXml
                  ? 'XML'
                  : 'TXT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            totalDiffs == 0
                ? 'In Sync (Identical)'
                : '$totalDiffs Differences Found',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (controller.addedCount > 0) ...[
            _StatPill(
              text: '+${controller.addedCount}',
              color: Colors.green,
              theme: theme,
            ),
            const SizedBox(width: 6),
          ],
          if (controller.deletedCount > 0) ...[
            _StatPill(
              text: '-${controller.deletedCount}',
              color: Colors.red,
              theme: theme,
            ),
            const SizedBox(width: 6),
          ],
          if (controller.modifiedCount > 0) ...[
            _StatPill(
              text: '~${controller.modifiedCount}',
              color: Colors.amber[800]!,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String text;
  final Color color;
  final ThemeData theme;

  const _StatPill({
    required this.text,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _MergePreviewView extends StatelessWidget {
  final LiveDiffController controller;

  const _MergePreviewView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final merged = controller.getMergedOutput();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Text(
              merged,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
