import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'md_document_session.dart';
import 'md_source_edits.dart';

/// The Markdown formatting toolbar shown in edit mode (task 6.4).
///
/// Each button transforms the current selection (or inserts syntax at the
/// cursor) using the pure [MdSourceEdits] functions, then writes the result back
/// to the source editor through the session. No formatting logic lives here —
/// this is only the button strip.
class MdFormatToolbar extends StatelessWidget {
  final MdDocumentSession session;

  const MdFormatToolbar({super.key, required this.session});

  void _apply(MdEdit Function(String text, int start, int end) op) {
    final code = session.code;
    if (code == null) return;
    final (start, end) = session.selectionRange;
    final result = op(code.text, start, end);
    session.applyEdit(result.text, result.selectionStart, result.selectionEnd);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(l10n.mdBold, Icons.format_bold,
                () => _apply(MdSourceEdits.bold)),
            _btn(l10n.mdItalic, Icons.format_italic,
                () => _apply(MdSourceEdits.italic)),
            _btn(l10n.mdStrikethrough, Icons.strikethrough_s,
                () => _apply(MdSourceEdits.strikethrough)),
            _headingMenu(l10n),
            _btn(l10n.mdBulletList, Icons.format_list_bulleted,
                () => _apply(MdSourceEdits.bulletList)),
            _btn(l10n.mdNumberedList, Icons.format_list_numbered,
                () => _apply(MdSourceEdits.numberedList)),
            _btn(l10n.mdTaskList, Icons.checklist,
                () => _apply(MdSourceEdits.taskList)),
            _btn(l10n.mdQuote, Icons.format_quote,
                () => _apply(MdSourceEdits.blockquote)),
            _btn(l10n.mdInlineCode, Icons.code,
                () => _apply(MdSourceEdits.inlineCode)),
            _btn(l10n.mdCodeBlock, Icons.data_object,
                () => _apply(MdSourceEdits.codeBlock)),
            _btn(l10n.mdLink, Icons.link, () => _apply(MdSourceEdits.link)),
            _btn(l10n.mdTable, Icons.grid_on,
                () => _apply(MdSourceEdits.table)),
          ],
        ),
      ),
    );
  }

  Widget _btn(String tooltip, IconData icon, VoidCallback onPressed) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _headingMenu(AppLocalizations l10n) {
    return PopupMenuButton<int>(
      tooltip: l10n.mdHeading,
      icon: const Icon(Icons.title),
      onSelected: (level) =>
          _apply((text, start, end) => MdSourceEdits.heading(text, start, end, level)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 1, child: Text(l10n.mdHeading1)),
        PopupMenuItem(value: 2, child: Text(l10n.mdHeading2)),
        PopupMenuItem(value: 3, child: Text(l10n.mdHeading3)),
      ],
    );
  }
}
