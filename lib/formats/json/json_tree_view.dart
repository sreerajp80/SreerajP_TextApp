import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'json_document_session.dart';
import 'json_node.dart';
import 'json_parser.dart';
import 'json_path.dart';
import 'json_tree_edits.dart';

/// The collapsible **tree** view of a JSON document (tasks 8.2, 8.5).
///
/// Shows each node with its key, value type, and — for containers — a child
/// count; supports expand/collapse (state kept on the session so it survives tab
/// switches), copy path / value / subtree, and, in edit mode, in-place edits
/// (edit value / key, add a child, delete) applied as precise source-span
/// changes (plan §3.3). A search filter narrows the tree to matching branches.
class JsonTreeView extends ConsumerWidget {
  final JsonDocumentSession session;
  final bool editing;

  const JsonTreeView({
    super.key,
    required this.session,
    required this.editing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final root = session.root;
    if (root == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.jsonNotValidTree),
        ),
      );
    }

    final filter = session.treeFilter.toLowerCase();
    final rows = <Widget>[];
    _build(context, ref, root, 0, filter, rows);
    if (rows.isEmpty) {
      return Center(child: Text(l10n.xmlNoMatches));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: rows,
    );
  }

  void _build(BuildContext context, WidgetRef ref, JsonNode node, int depth,
      String filter, List<Widget> out) {
    if (!_passesFilter(node, filter)) return;
    final path = pathOf(node);
    final expanded = filter.isNotEmpty ? true : session.isExpanded(path);

    out.add(_TreeRow(
      session: session,
      node: node,
      path: path,
      depth: depth,
      expanded: expanded,
      editing: editing,
    ));

    if (node.isContainer && expanded) {
      for (final child in node.children) {
        _build(context, ref, child, depth + 1, filter, out);
      }
    }
  }

  bool _passesFilter(JsonNode node, String filter) {
    if (filter.isEmpty) return true;
    final keyHit = (node.key ?? '').toLowerCase().contains(filter);
    final valueHit =
        !node.isContainer && node.valuePreview.toLowerCase().contains(filter);
    if (keyHit || valueHit) return true;
    return node.children.any((c) => _passesFilter(c, filter));
  }
}

class _TreeRow extends StatelessWidget {
  final JsonDocumentSession session;
  final JsonNode node;
  final String path;
  final int depth;
  final bool expanded;
  final bool editing;

  const _TreeRow({
    required this.session,
    required this.node,
    required this.path,
    required this.depth,
    required this.expanded,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = node.index != null
        ? '[${node.index}]'
        : (node.key != null ? node.key! : 'root');

    return InkWell(
      onTap: node.isContainer ? () => session.toggleExpanded(path) : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0 + depth * 16, 4, 8, 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: node.isContainer
                  ? Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : const SizedBox.shrink(),
            ),
            Flexible(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (node.isContainer)
                      TextSpan(
                        text: '  ${node.kind.label} · ${node.childCount}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      )
                    else
                      TextSpan(
                        text: '  ${node.valuePreview}',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                  ],
                ),
              ),
            ),
            _RowMenu(session: session, node: node, editing: editing),
          ],
        ),
      ),
    );
  }
}

enum _RowAction {
  copyPath,
  copyValue,
  copySubtree,
  editValue,
  editKey,
  addChild,
  delete,
}

class _RowMenu extends StatelessWidget {
  final JsonDocumentSession session;
  final JsonNode node;
  final bool editing;

  const _RowMenu({
    required this.session,
    required this.node,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_RowAction>(
      icon: const Icon(Icons.more_vert, size: 18),
      tooltip: l10n.xmlNodeActions,
      onSelected: (a) => _handle(context, a),
      itemBuilder: (context) => [
        PopupMenuItem(value: _RowAction.copyPath, child: Text(l10n.xmlCopyPath)),
        if (!node.isContainer)
          PopupMenuItem(
              value: _RowAction.copyValue, child: Text(l10n.jsonCopyValue)),
        PopupMenuItem(
            value: _RowAction.copySubtree, child: Text(l10n.jsonCopyJson)),
        if (editing) ...[
          const PopupMenuDivider(),
          if (!node.isContainer)
            PopupMenuItem(
                value: _RowAction.editValue, child: Text(l10n.jsonEditValue)),
          if (node.key != null)
            PopupMenuItem(
                value: _RowAction.editKey, child: Text(l10n.jsonEditKey)),
          if (node.isContainer)
            PopupMenuItem(
                value: _RowAction.addChild, child: Text(l10n.xmlAddChild)),
          if (node.parent != null)
            PopupMenuItem(
                value: _RowAction.delete, child: Text(l10n.xmlDelete)),
        ],
      ],
    );
  }

  Future<void> _handle(BuildContext context, _RowAction action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final source = session.code?.text ?? '';
    const edits = JsonTreeEdits();
    switch (action) {
      case _RowAction.copyPath:
        await Clipboard.setData(ClipboardData(text: pathOf(node)));
        messenger.showSnackBar(SnackBar(content: Text(l10n.xmlPathCopied)));
        break;
      case _RowAction.copyValue:
        final value = node.kind == JsonKind.string
            ? (node.stringValue ?? '')
            : node.rawText;
        await Clipboard.setData(ClipboardData(text: value));
        messenger.showSnackBar(SnackBar(content: Text(l10n.jsonValueCopied)));
        break;
      case _RowAction.copySubtree:
        final text = source.substring(node.start, node.end);
        await Clipboard.setData(ClipboardData(text: text));
        messenger.showSnackBar(SnackBar(content: Text(l10n.jsonJsonCopied)));
        break;
      case _RowAction.editValue:
        final input = await _prompt(context, l10n.jsonEditValue,
            initial: node.rawText, hint: l10n.jsonValueHint);
        if (input == null) return;
        if (!_isValidValue(input)) {
          messenger.showSnackBar(
              SnackBar(content: Text(l10n.jsonInvalidValue)));
          return;
        }
        session.applySource(edits.setScalarValue(source, node, input));
        break;
      case _RowAction.editKey:
        final input =
            await _prompt(context, l10n.jsonEditKey, initial: node.key ?? '');
        if (input == null) return;
        session.applySource(edits.setKey(source, node, input));
        break;
      case _RowAction.addChild:
        await _addChild(context, edits, source);
        break;
      case _RowAction.delete:
        session.applySource(edits.deleteNode(source, node));
        break;
    }
  }

  Future<void> _addChild(
      BuildContext context, JsonTreeEdits edits, String source) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    String? key;
    if (node.kind == JsonKind.object) {
      key = await _prompt(context, l10n.jsonNewKey, hint: l10n.jsonMemberKeyHint);
      if (key == null) return;
    }
    if (!context.mounted) return;
    final value = await _prompt(context, l10n.jsonNewValue,
        initial: 'null', hint: l10n.jsonValueHint);
    if (value == null) return;
    if (!_isValidValue(value)) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.jsonInvalidValue)));
      return;
    }
    session.applySource(edits.addChild(source, node, key: key, rawValue: value));
  }

  bool _isValidValue(String text) => const JsonParser().parse(text).ok;

  Future<String?> _prompt(BuildContext context, String title,
      {String initial = '', String? hint}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
                hintText: hint, border: const OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.actionOk),
            ),
          ],
        );
      },
    );
  }
}
