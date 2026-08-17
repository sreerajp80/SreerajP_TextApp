import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sreerajp_textapp/core/privacy/pii_detection.dart';
import 'package:sreerajp_textapp/core/privacy/pii_detector.dart';
import 'package:sreerajp_textapp/core/privacy/pii_mask_mode.dart';
import 'package:sreerajp_textapp/core/privacy/pii_scrubber.dart';
import 'package:sreerajp_textapp/core/privacy/pii_type.dart';
import 'package:sreerajp_textapp/core/share/share_service.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Modal bottom sheet for scanning documents for sensitive PII and secrets,
/// selecting masking transformations, and either applying changes in-place or
/// sharing/exporting a scrubbed copy.
class PrivacyShieldSheet extends StatefulWidget {
  final String text;
  final String documentTitle;
  final String mimeType;
  final ValueChanged<String>? onApplyToEditor;
  final ShareService shareService;
  final SafService safService;
  final PiiDetector detector;
  final PiiScrubber scrubber;

  const PrivacyShieldSheet({
    super.key,
    required this.text,
    required this.documentTitle,
    required this.mimeType,
    this.onApplyToEditor,
    required this.shareService,
    required this.safService,
    this.detector = const PiiDetector(),
    this.scrubber = const PiiScrubber(),
  });

  /// Displays the privacy shield bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String text,
    required String documentTitle,
    required String mimeType,
    ValueChanged<String>? onApplyToEditor,
    required ShareService shareService,
    required SafService safService,
    PiiDetector detector = const PiiDetector(),
    PiiScrubber scrubber = const PiiScrubber(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PrivacyShieldSheet(
        text: text,
        documentTitle: documentTitle,
        mimeType: mimeType,
        onApplyToEditor: onApplyToEditor,
        shareService: shareService,
        safService: safService,
        detector: detector,
        scrubber: scrubber,
      ),
    );
  }

  @override
  State<PrivacyShieldSheet> createState() => _PrivacyShieldSheetState();
}

class _PrivacyShieldSheetState extends State<PrivacyShieldSheet> {
  late PiiScanResult _scanResult;
  PiiMaskMode _mode = PiiMaskMode.redact;
  int _tabIndex = 0; // 0 = Items, 1 = Preview

  @override
  void initState() {
    super.initState();
    _scanResult = widget.detector.scan(widget.text);
  }

  void _toggleMatch(PiiMatch match, bool? value) {
    setState(() {
      final updated = _scanResult.matches.map((m) {
        if (m.id == match.id) {
          return m.copyWith(isSelected: value ?? false);
        }
        return m;
      }).toList();
      _scanResult = _scanResult.copyWith(matches: updated);
    });
  }

  void _toggleAll(bool select) {
    setState(() {
      final updated = _scanResult.matches.map((m) {
        return m.copyWith(isSelected: select);
      }).toList();
      _scanResult = _scanResult.copyWith(matches: updated);
    });
  }

  void _toggleCategory(PiiType type, bool select) {
    setState(() {
      final updated = _scanResult.matches.map((m) {
        if (m.type == type) {
          return m.copyWith(isSelected: select);
        }
        return m;
      }).toList();
      _scanResult = _scanResult.copyWith(matches: updated);
    });
  }

  PiiScrubResult _computeScrubResult() {
    return widget.scrubber.scrub(widget.text, _scanResult, mode: _mode);
  }

  Future<void> _handleApplyToEditor() async {
    final scrubResult = _computeScrubResult();
    widget.onApplyToEditor?.call(scrubResult.scrubbedText);
    Navigator.of(context).pop();
  }

  Future<void> _handleShareScrubbed() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final scrubResult = _computeScrubResult();
    final bytes = utf8.encode(scrubResult.scrubbedText);

    try {
      await widget.shareService.shareFileBytes(
        name: 'scrubbed_${widget.documentTitle}',
        mimeType: widget.mimeType,
        bytes: Uint8List.fromList(bytes),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.privacyShareFailed)));
    }
  }

  Future<void> _handleExportScrubbed() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final scrubResult = _computeScrubResult();
    final bytes = utf8.encode(scrubResult.scrubbedText);

    try {
      final file = await widget.safService.createDocument(
        suggestedName: 'scrubbed_${widget.documentTitle}',
        bytes: Uint8List.fromList(bytes),
        mimeType: widget.mimeType,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outSaved(file.displayName))),
      );
      if (mounted) Navigator.of(context).pop();
    } on SafCancelled {
      // User cancelled SAF
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.outExportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final total = _scanResult.totalCount;
    final selected = _scanResult.selectedCount;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(theme, l10n, total, selected),
              if (total > 0) ...[
                _buildModeSelector(theme, l10n),
                _buildCategoryChips(theme, l10n),
                _buildViewToggle(theme, l10n),
                Expanded(
                  child: _tabIndex == 0
                      ? _buildMatchesList(scrollController, theme)
                      : _buildPreviewPane(scrollController, theme),
                ),
                _buildActionButtons(theme, l10n, selected),
              ] else ...[
                Expanded(child: _buildCleanState(theme, l10n)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations l10n,
    int total,
    int selected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: total > 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.privacyShieldTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.privacyShieldSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0)
                Badge(
                  label: Text('$selected / $total'),
                  backgroundColor: theme.colorScheme.errorContainer,
                  textColor: theme.colorScheme.onErrorContainer,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SegmentedButton<PiiMaskMode>(
        segments: [
          ButtonSegment(
            value: PiiMaskMode.redact,
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
            label: Text(l10n.privacyModeRedact),
          ),
          ButtonSegment(
            value: PiiMaskMode.hash,
            icon: const Icon(Icons.tag_outlined, size: 18),
            label: Text(l10n.privacyModeHash),
          ),
          ButtonSegment(
            value: PiiMaskMode.anonymize,
            icon: const Icon(Icons.masks_outlined, size: 18),
            label: Text(l10n.privacyModeAnonymize),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (set) {
          if (set.isNotEmpty) {
            setState(() => _mode = set.first);
          }
        },
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, AppLocalizations l10n) {
    final counts = _scanResult.countsByType;
    final selectedCounts = _scanResult.selectedCountsByType;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.privacySelectAll),
            selected: _scanResult.selectedCount == _scanResult.totalCount,
            onSelected: (val) => _toggleAll(val),
          ),
          const SizedBox(width: 8),
          ...counts.entries.map((entry) {
            final type = entry.key;
            final count = entry.value;
            final selCount = selectedCounts[type] ?? 0;
            final isFullySelected = selCount == count;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(type.icon, size: 16),
                label: Text('${type.displayName} ($count)'),
                selected: isFullySelected,
                onSelected: (val) => _toggleCategory(type, val),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.privacyTabDetections),
            selected: _tabIndex == 0,
            onSelected: (val) {
              if (val) setState(() => _tabIndex = 0);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(l10n.privacyTabPreview),
            selected: _tabIndex == 1,
            onSelected: (val) {
              if (val) setState(() => _tabIndex = 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(ScrollController scrollController, ThemeData theme) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _scanResult.matches.length,
      itemBuilder: (context, index) {
        final match = _scanResult.matches[index];
        final scrubPreview = widget.scrubber.scrubMatches(match.rawValue, [
          match.copyWith(start: 0, end: match.rawValue.length),
        ], mode: _mode);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: match.isSelected ? 1 : 0,
          color: match.isSelected
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: match.isSelected
                  ? theme.colorScheme.outlineVariant
                  : Colors.transparent,
            ),
          ),
          child: CheckboxListTile(
            value: match.isSelected,
            onChanged: (val) => _toggleMatch(match, val),
            secondary: CircleAvatar(
              backgroundColor: match.type.isHighRisk
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.secondaryContainer,
              foregroundColor: match.type.isHighRisk
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
              child: Icon(match.type.icon, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  match.type.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'L${match.line}:C${match.column}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _truncate(match.rawValue, 40),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.error,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  _truncate(scrubPreview.scrubbedText, 40),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewPane(ScrollController scrollController, ThemeData theme) {
    final scrubResult = _computeScrubResult();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: SelectableText(
          scrubResult.scrubbedText,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Widget _buildCleanState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyCleanTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacyCleanDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionOk),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    ThemeData theme,
    AppLocalizations l10n,
    int selectedCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.onApplyToEditor != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: selectedCount > 0 ? _handleApplyToEditor : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.privacyApplyToBuffer),
                  ),
                ),
              if (widget.onApplyToEditor != null) const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: selectedCount > 0 ? _handleShareScrubbed : null,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.privacyShareScrubbed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: selectedCount > 0 ? _handleExportScrubbed : null,
                icon: const Icon(Icons.save_alt_outlined, size: 16),
                label: Text(l10n.privacyExportScrubbed),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
