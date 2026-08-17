import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

import 'package:sreerajp_textapp/core/editor/column_selection.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Available operation modes in the Column & Multi-Cursor edit sheet.
enum ColumnSelectionMode { prefixSuffix, columnBlock, insertAtCol, numbering }

/// Interactive modal sheet allowing users to perform bulk multi-cursor,
/// column block, prefix/suffix, and auto-numbering transformations across lines.
class ColumnSelectionSheet extends StatefulWidget {
  final CodeLineEditingController controller;
  final int initialStartLineIndex;
  final int initialEndLineIndex;
  final VoidCallback? onApplied;

  const ColumnSelectionSheet({
    super.key,
    required this.controller,
    this.initialStartLineIndex = 0,
    this.initialEndLineIndex = 0,
    this.onApplied,
  });

  /// Shows the [ColumnSelectionSheet] as a bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required CodeLineEditingController controller,
    int? initialStartLineIndex,
    int? initialEndLineIndex,
    VoidCallback? onApplied,
  }) {
    // Derive line bounds from current selection if not explicitly provided
    final selection = controller.selection;
    final int startLine =
        initialStartLineIndex ??
        min(selection.baseIndex, selection.extentIndex);
    final int endLine =
        initialEndLineIndex ?? max(selection.baseIndex, selection.extentIndex);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ColumnSelectionSheet(
          controller: controller,
          initialStartLineIndex: startLine,
          initialEndLineIndex: endLine,
          onApplied: onApplied,
        ),
      ),
    );
  }

  @override
  State<ColumnSelectionSheet> createState() => _ColumnSelectionSheetState();
}

class _ColumnSelectionSheetState extends State<ColumnSelectionSheet> {
  late ColumnSelectionMode _mode;
  late int _startLine; // 1-indexed for display
  late int _endLine; // 1-indexed for display
  late int _totalLines;

  // Prefix / Suffix
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();

  // Column Block
  final TextEditingController _startColController = TextEditingController(
    text: '1',
  );
  final TextEditingController _endColController = TextEditingController(
    text: '5',
  );
  final TextEditingController _replaceBlockController = TextEditingController();

  // Insert at Column
  final TextEditingController _insertColController = TextEditingController(
    text: '1',
  );
  final TextEditingController _insertTextController = TextEditingController();
  bool _padShorterLines = true;

  // Numbering
  final TextEditingController _numStartController = TextEditingController(
    text: '1',
  );
  final TextEditingController _numStepController = TextEditingController(
    text: '1',
  );
  final TextEditingController _numFormatController = TextEditingController(
    text: '%d. ',
  );
  final TextEditingController _numPaddingController = TextEditingController(
    text: '0',
  );

  @override
  void initState() {
    super.initState();
    _mode = ColumnSelectionMode.prefixSuffix;
    _totalLines = max(1, widget.controller.codeLines.length);

    _startLine = (widget.initialStartLineIndex + 1).clamp(1, _totalLines);
    _endLine = (widget.initialEndLineIndex + 1).clamp(_startLine, _totalLines);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _suffixController.dispose();
    _startColController.dispose();
    _endColController.dispose();
    _replaceBlockController.dispose();
    _insertColController.dispose();
    _insertTextController.dispose();
    _numStartController.dispose();
    _numStepController.dispose();
    _numFormatController.dispose();
    _numPaddingController.dispose();
    super.dispose();
  }

  int get _startLineIndex => _startLine - 1;
  int get _endLineIndex => _endLine - 1;

  void _setLineRange(int start, int end) {
    setState(() {
      _startLine = start.clamp(1, _totalLines);
      _endLine = end.clamp(_startLine, _totalLines);
    });
  }

  ColumnEditResult _computeResult({bool forPreview = false}) {
    final String currentText = widget.controller.text;
    final int startIdx = _startLineIndex;
    final int endIdx = _endLineIndex;

    switch (_mode) {
      case ColumnSelectionMode.prefixSuffix:
        final prefix = _prefixController.text;
        final suffix = _suffixController.text;
        if (prefix.isNotEmpty && suffix.isNotEmpty) {
          return ColumnSelectionEngine.applyWrap(
            currentText,
            startLineIndex: startIdx,
            endLineIndex: endIdx,
            prefix: prefix,
            suffix: suffix,
          );
        } else if (prefix.isNotEmpty) {
          return ColumnSelectionEngine.applyPrefix(
            currentText,
            startLineIndex: startIdx,
            endLineIndex: endIdx,
            prefix: prefix,
          );
        } else if (suffix.isNotEmpty) {
          return ColumnSelectionEngine.applySuffix(
            currentText,
            startLineIndex: startIdx,
            endLineIndex: endIdx,
            suffix: suffix,
          );
        } else {
          return ColumnSelectionEngine.applyPrefix(
            currentText,
            startLineIndex: startIdx,
            endLineIndex: endIdx,
            prefix: '',
          );
        }

      case ColumnSelectionMode.columnBlock:
        final int startCol = (int.tryParse(_startColController.text) ?? 1) - 1;
        final int endCol = int.tryParse(_endColController.text) ?? 1;
        final String replacement = _replaceBlockController.text;
        if (replacement.isNotEmpty) {
          return ColumnSelectionEngine.replaceColumnBlock(
            currentText,
            startLineIndex: startIdx,
            endLineIndex: endIdx,
            startCol: startCol,
            endCol: endCol,
            replacement: replacement,
            padShorterLines: false,
          );
        } else {
          return ColumnSelectionEngine.extractColumnBlock(
            currentText,
            startLineIndex: startIdx,
            endLineIndex: endIdx,
            startCol: startCol,
            endCol: endCol,
          );
        }

      case ColumnSelectionMode.insertAtCol:
        final int col = (int.tryParse(_insertColController.text) ?? 1) - 1;
        final String insertText = _insertTextController.text;
        return ColumnSelectionEngine.applyInsertAtColumn(
          currentText,
          startLineIndex: startIdx,
          endLineIndex: endIdx,
          column: col,
          insertText: insertText,
          padShorterLines: _padShorterLines,
        );

      case ColumnSelectionMode.numbering:
        final int startNum = int.tryParse(_numStartController.text) ?? 1;
        final int step = int.tryParse(_numStepController.text) ?? 1;
        final String format = _numFormatController.text.isEmpty
            ? '%d. '
            : _numFormatController.text;
        final int padding = int.tryParse(_numPaddingController.text) ?? 0;
        return ColumnSelectionEngine.applyNumbering(
          currentText,
          startLineIndex: startIdx,
          endLineIndex: endIdx,
          startNumber: startNum,
          step: step,
          format: format,
          padding: padding,
        );
    }
  }

  void _applyEdits() {
    final result = _computeResult();
    widget.controller.text = result.text;
    widget.onApplied?.call();

    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.columnEditsApplied(result.affectedLineCount)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyColumnBlock() {
    final int startCol = (int.tryParse(_startColController.text) ?? 1) - 1;
    final int endCol = int.tryParse(_endColController.text) ?? 1;
    final result = ColumnSelectionEngine.extractColumnBlock(
      widget.controller.text,
      startLineIndex: _startLineIndex,
      endLineIndex: _endLineIndex,
      startCol: startCol,
      endCol: endCol,
    );

    if (result.extractedBlock != null && result.extractedBlock!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: result.extractedBlock!));
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.columnBlockCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _cutColumnBlock() {
    _copyColumnBlock();
    final int startCol = (int.tryParse(_startColController.text) ?? 1) - 1;
    final int endCol = int.tryParse(_endColController.text) ?? 1;
    final result = ColumnSelectionEngine.deleteColumnBlock(
      widget.controller.text,
      startLineIndex: _startLineIndex,
      endLineIndex: _endLineIndex,
      startCol: startCol,
      endCol: endCol,
    );
    widget.controller.text = result.text;
    widget.onApplied?.call();

    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.columnEditsApplied(result.affectedLineCount)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteColumnBlock() {
    final int startCol = (int.tryParse(_startColController.text) ?? 1) - 1;
    final int endCol = int.tryParse(_endColController.text) ?? 1;
    final result = ColumnSelectionEngine.deleteColumnBlock(
      widget.controller.text,
      startLineIndex: _startLineIndex,
      endLineIndex: _endLineIndex,
      startCol: startCol,
      endCol: endCol,
    );
    widget.controller.text = result.text;
    widget.onApplied?.call();

    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.columnEditsApplied(result.affectedLineCount)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final int count = _endLine - _startLine + 1;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title Row
          Row(
            children: [
              Icon(Icons.view_column_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.columnSelectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Line Range Section Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_line_spacing,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.columnSelectionLines(_startLine, _endLine, count),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Presets
                      ActionChip(
                        avatar: const Icon(Icons.select_all, size: 16),
                        label: Text(l10n.columnSelectionAllLines),
                        onPressed: () => _setLineRange(1, _totalLines),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          label: l10n.columnSelectionStartLine,
                          value: _startLine,
                          min: 1,
                          max: _endLine,
                          onChanged: (val) => setState(() => _startLine = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberInput(
                          label: l10n.columnSelectionEndLine,
                          value: _endLine,
                          min: _startLine,
                          max: _totalLines,
                          onChanged: (val) => setState(() => _endLine = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mode Segmented Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ColumnSelectionMode>(
              segments: [
                ButtonSegment(
                  value: ColumnSelectionMode.prefixSuffix,
                  label: Text(l10n.columnModePrefixSuffix),
                  icon: const Icon(Icons.wrap_text, size: 18),
                ),
                ButtonSegment(
                  value: ColumnSelectionMode.columnBlock,
                  label: Text(l10n.columnModeBlock),
                  icon: const Icon(Icons.border_vertical_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ColumnSelectionMode.insertAtCol,
                  label: Text(l10n.columnModeInsertAtCol),
                  icon: const Icon(Icons.format_indent_increase, size: 18),
                ),
                ButtonSegment(
                  value: ColumnSelectionMode.numbering,
                  label: Text(l10n.columnModeNumbering),
                  icon: const Icon(Icons.format_list_numbered, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) => setState(() => _mode = set.first),
            ),
          ),
          const SizedBox(height: 16),

          // Mode Active Controls
          _buildActiveModeControls(l10n, theme),
          const SizedBox(height: 16),

          // Live Preview Section
          _buildLivePreview(l10n, theme),
          const SizedBox(height: 20),

          // Bottom Actions
          _buildActionButtons(l10n, theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove, size: 16),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(
                  '$value',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          icon: const Icon(Icons.add, size: 16),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _buildActiveModeControls(AppLocalizations l10n, ThemeData theme) {
    switch (_mode) {
      case ColumnSelectionMode.prefixSuffix:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prefixController,
                    decoration: InputDecoration(
                      labelText: l10n.columnPrefixLabel,
                      prefixIcon: const Icon(Icons.arrow_right_alt, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _suffixController,
                    decoration: InputDecoration(
                      labelText: l10n.columnSuffixLabel,
                      prefixIcon: const Icon(Icons.keyboard_return, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Quick preset chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(label: 'Bullet - ', onTap: () => _setPrefix('- ')),
                _chip(label: 'Task [ ] ', onTap: () => _setPrefix('- [ ] ')),
                _chip(label: 'Comment //', onTap: () => _setPrefix('// ')),
                _chip(label: 'Hash #', onTap: () => _setPrefix('# ')),
                _chip(label: 'Quote >', onTap: () => _setPrefix('> ')),
                _chip(label: 'Comma ,', onTap: () => _setSuffix(',')),
                _chip(label: 'Semicolon ;', onTap: () => _setSuffix(';')),
                _chip(
                  label: '"..." Quotes',
                  onTap: () {
                    setState(() {
                      _prefixController.text = '"';
                      _suffixController.text = '"';
                    });
                  },
                ),
                _chip(
                  label: 'HTML <!-- -->',
                  onTap: () {
                    setState(() {
                      _prefixController.text = '<!-- ';
                      _suffixController.text = ' -->';
                    });
                  },
                ),
              ],
            ),
          ],
        );

      case ColumnSelectionMode.columnBlock:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startColController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.columnStartColLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endColController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.columnEndColLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _replaceBlockController,
              decoration: InputDecoration(
                labelText: l10n.columnReplaceLabel,
                hintText: l10n.columnReplaceHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.columnCopyBlockAction),
                  onPressed: _copyColumnBlock,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cut, size: 16),
                  label: Text(l10n.columnCutBlockAction),
                  onPressed: _cutColumnBlock,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n.columnDeleteBlockAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: _deleteColumnBlock,
                ),
              ],
            ),
          ],
        );

      case ColumnSelectionMode.insertAtCol:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _insertColController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.columnInsertColLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _insertTextController,
                    decoration: InputDecoration(
                      labelText: l10n.columnInsertTextLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.columnPadShorterLines,
                style: theme.textTheme.bodySmall,
              ),
              value: _padShorterLines,
              onChanged: (val) => setState(() => _padShorterLines = val),
            ),
            Wrap(
              spacing: 6,
              children: [
                _chip(
                  label: 'Col 1 (Start)',
                  onTap: () => setState(() => _insertColController.text = '1'),
                ),
                _chip(
                  label: 'Col 4',
                  onTap: () => setState(() => _insertColController.text = '4'),
                ),
                _chip(
                  label: 'Col 8',
                  onTap: () => setState(() => _insertColController.text = '8'),
                ),
                _chip(
                  label: 'Col 12',
                  onTap: () => setState(() => _insertColController.text = '12'),
                ),
              ],
            ),
          ],
        );

      case ColumnSelectionMode.numbering:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numStartController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.columnNumberStart,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _numStepController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.columnNumberStep,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _numPaddingController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.columnNumberPadding,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _numFormatController,
              decoration: InputDecoration(
                labelText: l10n.columnNumberFormat,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _chip(
                  label: '1. ',
                  onTap: () =>
                      setState(() => _numFormatController.text = '%d. '),
                ),
                _chip(
                  label: '[1] ',
                  onTap: () =>
                      setState(() => _numFormatController.text = '[%d] '),
                ),
                _chip(
                  label: '01. (Pad 2)',
                  onTap: () {
                    setState(() {
                      _numFormatController.text = '%d. ';
                      _numPaddingController.text = '2';
                    });
                  },
                ),
                _chip(
                  label: '#%d: ',
                  onTap: () =>
                      setState(() => _numFormatController.text = '#%d: '),
                ),
              ],
            ),
          ],
        );
    }
  }

  void _setPrefix(String prefix) {
    setState(() => _prefixController.text = prefix);
  }

  void _setSuffix(String suffix) {
    setState(() => _suffixController.text = suffix);
  }

  Widget _chip({required String label, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onTap,
    );
  }

  Widget _buildLivePreview(AppLocalizations l10n, ThemeData theme) {
    final result = _computeResult(forPreview: true);
    final List<String> previewLines = result.text.split(RegExp(r'\r?\n'));
    final int start = _startLineIndex;
    final int end = min(_endLineIndex, previewLines.length - 1);

    final List<String> displaySnippet = [];
    for (int i = start; i <= min(end, start + 6); i++) {
      if (i < previewLines.length) {
        displaySnippet.add(
          '${(i + 1).toString().padLeft(3)} | ${previewLines[i]}',
        );
      }
    }
    if (end > start + 6) {
      displaySnippet.add('... (${end - (start + 6)} more lines)');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.preview_outlined,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.columnLivePreview,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            displaySnippet.join('\n'),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.columnApplyAction),
            onPressed: _applyEdits,
          ),
        ),
      ],
    );
  }
}
