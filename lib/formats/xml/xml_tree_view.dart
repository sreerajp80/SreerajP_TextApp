import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart';

import '../../l10n/app_localizations.dart';
import 'xml_document_session.dart';
import 'xml_path.dart';
import 'xml_tree_edits.dart';

/// The collapsible **element tree** view of an XML document (tasks 9.2, 9.5).
///
/// Shows each element with its tag name, attributes, a child count (or a text
/// preview for a leaf), comments and CDATA as dim rows; supports expand/collapse
/// (state kept on the session so it survives tab switches), copy path / value /
/// subtree, and, in edit mode, in-place edits (text, attributes, rename, add
/// child, delete, move) applied by mutating the DOM and re-serializing (plan
/// §3.4). A search filter narrows the tree to matching branches.
class XmlTreeView extends ConsumerWidget {
  final XmlDocumentSession session;
  final bool editing;

  const XmlTreeView({
    super.key,
    required this.session,
    required this.editing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final document = session.document;
    if (document == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.xmlNotWellFormedTree),
        ),
      );
    }

    final filter = session.treeFilter.toLowerCase();
    final rows = <Widget>[];
    _build(document.rootElement, 0, filter, rows);
    if (rows.isEmpty) {
      return Center(child: Text(l10n.xmlNoMatches));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: rows,
    );
  }

  void _build(XmlNode node, int depth, String filter, List<Widget> out) {
    if (!_passesFilter(node, filter)) return;
    final path = xmlPathOf(node);
    final childNodes = _renderableChildren(node);
    final expandable = childNodes.isNotEmpty;
    final expanded = filter.isNotEmpty ? true : session.isExpanded(path);

    out.add(_TreeRow(
      session: session,
      node: node,
      path: path,
      depth: depth,
      expandable: expandable,
      expanded: expanded,
      editing: editing,
    ));

    if (expandable && expanded) {
      for (final child in childNodes) {
        _build(child, depth + 1, filter, out);
      }
    }
  }

  /// Elements, comments, and CDATA children (skips whitespace-only text — a leaf
  /// element's text is shown inline in its own row).
  static List<XmlNode> _renderableChildren(XmlNode node) {
    return node.children
        .where((c) => c is XmlElement || c is XmlComment || c is XmlCDATA)
        .toList();
  }

  bool _passesFilter(XmlNode node, String filter) {
    if (filter.isEmpty) return true;
    if (node is XmlElement) {
      if (node.name.qualified.toLowerCase().contains(filter)) return true;
      for (final a in node.attributes) {
        if (a.name.qualified.toLowerCase().contains(filter) ||
            a.value.toLowerCase().contains(filter)) {
          return true;
        }
      }
      if (node.childElements.isEmpty &&
          node.innerText.toLowerCase().contains(filter)) {
        return true;
      }
    } else if (node is XmlComment || node is XmlCDATA) {
      if ((node.value ?? '').toLowerCase().contains(filter)) {
        return true;
      }
    }
    return _renderableChildren(node).any((c) => _passesFilter(c, filter));
  }
}

class _TreeRow extends StatelessWidget {
  final XmlDocumentSession session;
  final XmlNode node;
  final String path;
  final int depth;
  final bool expandable;
  final bool expanded;
  final bool editing;

  const _TreeRow({
    required this.session,
    required this.node,
    required this.path,
    required this.depth,
    required this.expandable,
    required this.expanded,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: expandable ? () => session.toggleExpanded(path) : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0 + depth * 16, 4, 8, 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: expandable
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
                  children: _label(theme),
                ),
              ),
            ),
            _RowMenu(session: session, node: node, editing: editing),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _label(ThemeData theme) {
    final node = this.node;
    if (node is XmlComment) {
      return [
        TextSpan(
          text: '<!-- comment -->',
          style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic),
        ),
      ];
    }
    if (node is XmlCDATA) {
      return [
        TextSpan(
          text: 'CDATA',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ];
    }
    final element = node as XmlElement;
    final spans = <TextSpan>[
      TextSpan(
        text: element.name.qualified,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
    if (element.attributes.isNotEmpty) {
      final attrs = element.attributes
          .map((a) => '${a.name.qualified}="${a.value}"')
          .join(' ');
      spans.add(TextSpan(
        text: '  $attrs',
        style: TextStyle(color: theme.colorScheme.secondary),
      ));
    }
    if (element.childElements.isEmpty) {
      final text = element.innerText.trim();
      if (text.isNotEmpty) {
        spans.add(TextSpan(
          text: '  $text',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: '  · ${element.childElements.length}',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ));
    }
    return spans;
  }
}

enum _RowAction {
  copyPath,
  copyValue,
  copySubtree,
  editText,
  setAttribute,
  removeAttribute,
  rename,
  addChild,
  delete,
  moveUp,
  moveDown,
}

class _RowMenu extends StatelessWidget {
  final XmlDocumentSession session;
  final XmlNode node;
  final bool editing;

  const _RowMenu({
    required this.session,
    required this.node,
    required this.editing,
  });

  bool get _isElement => node is XmlElement;
  bool get _isLeafElement =>
      node is XmlElement && (node as XmlElement).childElements.isEmpty;
  bool get _canMove => node is XmlElement && node.parent is XmlElement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_RowAction>(
      icon: const Icon(Icons.more_vert, size: 18),
      tooltip: l10n.xmlNodeActions,
      onSelected: (a) => _handle(context, a),
      itemBuilder: (context) => [
        PopupMenuItem(value: _RowAction.copyPath, child: Text(l10n.xmlCopyPath)),
        PopupMenuItem(
            value: _RowAction.copyValue, child: Text(l10n.xmlCopyText)),
        PopupMenuItem(
            value: _RowAction.copySubtree, child: Text(l10n.xmlCopyXml)),
        if (editing && _isElement) ...[
          const PopupMenuDivider(),
          if (_isLeafElement)
            PopupMenuItem(
                value: _RowAction.editText, child: Text(l10n.xmlEditText)),
          PopupMenuItem(
              value: _RowAction.setAttribute, child: Text(l10n.xmlSetAttribute)),
          PopupMenuItem(
              value: _RowAction.removeAttribute,
              child: Text(l10n.xmlRemoveAttribute)),
          PopupMenuItem(value: _RowAction.rename, child: Text(l10n.xmlRename)),
          PopupMenuItem(
              value: _RowAction.addChild, child: Text(l10n.xmlAddChild)),
          if (_canMove) ...[
            PopupMenuItem(value: _RowAction.moveUp, child: Text(l10n.xmlMoveUp)),
            PopupMenuItem(
                value: _RowAction.moveDown, child: Text(l10n.xmlMoveDown)),
          ],
        ],
        if (editing && node.parent != null && node.parent is! XmlDocument)
          PopupMenuItem(value: _RowAction.delete, child: Text(l10n.xmlDelete)),
      ],
    );
  }

  Future<void> _handle(BuildContext context, _RowAction action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final document = session.document;
    if (document == null) return;
    const edits = XmlTreeEdits();
    final element = node is XmlElement ? node as XmlElement : null;

    switch (action) {
      case _RowAction.copyPath:
        await Clipboard.setData(ClipboardData(text: xmlPathOf(node)));
        messenger.showSnackBar(SnackBar(content: Text(l10n.xmlPathCopied)));
        break;
      case _RowAction.copyValue:
        final value =
            element != null ? element.innerText : (node.value ?? '');
        await Clipboard.setData(ClipboardData(text: value));
        messenger.showSnackBar(SnackBar(content: Text(l10n.xmlTextCopied)));
        break;
      case _RowAction.copySubtree:
        await Clipboard.setData(ClipboardData(text: node.toXmlString()));
        messenger.showSnackBar(SnackBar(content: Text(l10n.xmlXmlCopied)));
        break;
      case _RowAction.editText:
        if (element == null) return;
        final input = await _prompt(context, l10n.xmlEditTextTitle,
            initial: element.innerText.trim());
        if (input == null) return;
        session.applySource(edits.setText(document, element, input));
        break;
      case _RowAction.setAttribute:
        if (element == null) return;
        final name = await _prompt(context, l10n.xmlAttributeName);
        if (name == null || name.trim().isEmpty) return;
        if (!context.mounted) return;
        final value = await _prompt(context, l10n.xmlAttributeValue);
        if (value == null) return;
        session.applySource(
            edits.setAttribute(document, element, name.trim(), value));
        break;
      case _RowAction.removeAttribute:
        if (element == null) return;
        if (element.attributes.isEmpty) {
          messenger.showSnackBar(
              SnackBar(content: Text(l10n.xmlNoAttributes)));
          return;
        }
        final name = await _pickAttribute(context, element);
        if (name == null) return;
        session.applySource(edits.removeAttribute(document, element, name));
        break;
      case _RowAction.rename:
        if (element == null) return;
        final name = await _prompt(context, l10n.xmlRenameElementTitle,
            initial: element.name.qualified);
        if (name == null) return;
        session.applySource(edits.renameElement(document, element, name));
        break;
      case _RowAction.addChild:
        if (element == null) return;
        final name = await _prompt(context, l10n.xmlNewChildElement);
        if (name == null || name.trim().isEmpty) return;
        if (!context.mounted) return;
        final text = await _prompt(context, l10n.xmlTextOptional);
        session.applySource(
            edits.addChild(document, element, name.trim(), text: text ?? ''));
        break;
      case _RowAction.delete:
        session.applySource(edits.deleteNode(document, node));
        break;
      case _RowAction.moveUp:
        if (element == null) return;
        session.applySource(edits.moveSibling(document, element, -1));
        break;
      case _RowAction.moveDown:
        if (element == null) return;
        session.applySource(edits.moveSibling(document, element, 1));
        break;
    }
  }

  Future<String?> _pickAttribute(BuildContext context, XmlElement element) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context).xmlRemoveWhichAttribute),
        children: [
          for (final a in element.attributes)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(a.name.qualified),
              child: Text('${a.name.qualified}="${a.value}"'),
            ),
        ],
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, String title,
      {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(AppLocalizations.of(context).actionOk),
          ),
        ],
      ),
    );
  }
}
