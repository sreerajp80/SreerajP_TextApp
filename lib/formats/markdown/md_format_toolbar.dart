import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/markdown/md_document_session.dart';
import 'package:sreerajp_textapp/formats/markdown/md_source_edits.dart';
import 'package:sreerajp_textapp/formats/markdown/md_table_builder_dialog.dart';
import 'package:sreerajp_textapp/formats/markdown/md_table_source.dart';

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
            _btn(
              l10n.mdBold,
              Icons.format_bold,
              () => _apply(MdSourceEdits.bold),
            ),
            _btn(
              l10n.mdItalic,
              Icons.format_italic,
              () => _apply(MdSourceEdits.italic),
            ),
            _btn(
              l10n.mdStrikethrough,
              Icons.strikethrough_s,
              () => _apply(MdSourceEdits.strikethrough),
            ),
            _headingMenu(l10n),
            _btn(
              l10n.mdBulletList,
              Icons.format_list_bulleted,
              () => _apply(MdSourceEdits.bulletList),
            ),
            _btn(
              l10n.mdNumberedList,
              Icons.format_list_numbered,
              () => _apply(MdSourceEdits.numberedList),
            ),
            _btn(
              l10n.mdTaskList,
              Icons.checklist,
              () => _apply(MdSourceEdits.taskList),
            ),
            _btn(
              l10n.mdQuote,
              Icons.format_quote,
              () => _apply(MdSourceEdits.blockquote),
            ),
            _btn(
              l10n.mdInlineCode,
              Icons.code,
              () => _apply(MdSourceEdits.inlineCode),
            ),
            _btn(
              l10n.mdCodeBlock,
              Icons.data_object,
              () => _apply(MdSourceEdits.codeBlock),
            ),
            _btn(l10n.mdLink, Icons.link, () => _apply(MdSourceEdits.link)),
            // Roadmap §4.4.2: the table button opens the visual builder rather
            // than dropping a skeleton the user has to align by hand.
            _btn(l10n.mdTable, Icons.grid_on, () => _editTable(context)),
          ],
        ),
      ),
    );
  }

  /// Opens the table builder (roadmap §4.4.2).
  ///
  /// When the cursor sits inside a table, that table is loaded into the builder
  /// and the result replaces it; otherwise a new table is inserted where the
  /// cursor is.
  Future<void> _editTable(BuildContext context) async {
    final code = session.code;
    if (code == null) return;
    final text = code.text;
    final (start, end) = session.selectionRange;

    final span = MdTableData.findTableAt(text, start);
    final existing = span == null
        ? null
        : MdTableData.parse(text.substring(span.start, span.end));

    final result = await showMdTableBuilder(context, initial: existing);
    if (result == null) return;

    if (span != null) {
      final newText = text.replaceRange(span.start, span.end, result);
      session.applyEdit(newText, span.start, span.start + result.length);
      return;
    }

    // Insert on its own lines, so the table is a block of its own.
    final before = start > 0 && text[start - 1] != '\n' ? '\n\n' : '';
    final after = end < text.length && text[end] != '\n' ? '\n\n' : '\n';
    final insert = '$before$result$after';
    final newText = text.replaceRange(start, end, insert);
    session.applyEdit(
      newText,
      start + before.length,
      start + before.length + result.length,
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
      onSelected: (level) => _apply(
        (text, start, end) => MdSourceEdits.heading(text, start, end, level),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: 1, child: Text(l10n.mdHeading1)),
        PopupMenuItem(value: 2, child: Text(l10n.mdHeading2)),
        PopupMenuItem(value: 3, child: Text(l10n.mdHeading3)),
      ],
    );
  }
}
