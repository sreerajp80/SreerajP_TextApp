import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../../l10n/app_localizations.dart';

/// The find / replace bar shown at the top of the editor when the user opens
/// search (task 4.2). `re_editor` supplies the [CodeFindController] with all the
/// logic (match navigation, case-sensitive + regex toggles, replace one / all);
/// this widget is the Material 3 panel that drives it.
///
/// Adapted from `re_editor`'s MIT-licensed example and themed to the app.
class TxtFindPanel extends StatelessWidget implements PreferredSizeWidget {
  final CodeFindController controller;
  final bool readOnly;

  const TxtFindPanel({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  static const double _findHeight = 48;

  @override
  Size get preferredSize {
    final value = controller.value;
    if (value == null) return Size.zero;
    return Size.fromHeight(value.replaceMode ? _findHeight * 2 : _findHeight);
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (value == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final String result;
    if (value.result == null) {
      result = l10n.txtNoResults;
    } else {
      result = '${value.result!.index + 1} / ${value.result!.matches.length}';
    }

    return Material(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _input(
                    context,
                    controller.findInputController,
                    controller.findInputFocusNode,
                    hint: l10n.txtFind,
                  ),
                ),
                _toggle(context, 'Aa', value.option.caseSensitive,
                    controller.toggleCaseSensitive, l10n.txtMatchCase),
                _toggle(context, '.*', value.option.regex,
                    controller.toggleRegex, l10n.txtUseRegex),
                Text(result, style: theme.textTheme.labelSmall),
                IconButton(
                  tooltip: l10n.txtPreviousMatch,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed:
                      value.result == null ? null : controller.previousMatch,
                ),
                IconButton(
                  tooltip: l10n.txtNextMatch,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: value.result == null ? null : controller.nextMatch,
                ),
                if (!readOnly)
                  IconButton(
                    key: const Key('txt-find-toggle-replace'),
                    tooltip: l10n.txtToggleReplace,
                    icon: const Icon(Icons.find_replace),
                    onPressed: controller.toggleMode,
                  ),
                IconButton(
                  tooltip: l10n.txtCloseFind,
                  icon: const Icon(Icons.close),
                  onPressed: controller.close,
                ),
              ],
            ),
            if (value.replaceMode && !readOnly)
              Row(
                children: [
                  Expanded(
                    child: _input(
                      context,
                      controller.replaceInputController,
                      controller.replaceInputFocusNode,
                      hint: l10n.txtReplaceWith,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.txtReplace,
                    icon: const Icon(Icons.done),
                    onPressed:
                        value.result == null ? null : controller.replaceMatch,
                  ),
                  IconButton(
                    tooltip: l10n.txtReplaceAll,
                    icon: const Icon(Icons.done_all),
                    onPressed: value.result == null
                        ? null
                        : controller.replaceAllMatches,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode, {
    required String hint,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    String label,
    bool checked,
    VoidCallback onTap,
    String tooltip,
  ) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: checked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: checked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
