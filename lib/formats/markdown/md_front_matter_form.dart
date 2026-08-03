import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'md_document_session.dart';
import 'md_front_matter.dart';

/// The YAML front-matter form editor (roadmap §4.4.3).
///
/// Builds a form from whatever fields the file's front matter already has, with
/// friendlier inputs for the well-known ones: a date picker for `date`, a chip
/// editor for `tags`, plain text for everything else. New fields can be added,
/// and a file with no front matter can be given one.
///
/// The write-back goes through [MdFrontMatter.applyEdits], which only touches
/// the lines of the fields the user actually changed — so a YAML feature the
/// app's small parser does not understand survives an edit untouched.
Future<void> showMdFrontMatterForm(
  BuildContext context,
  MdDocumentSession session, {
  bool readOnly = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => _FrontMatterForm(
          session: session,
          scrollController: controller,
          readOnly: readOnly,
        ),
      ),
    ),
  );
}

class _FrontMatterForm extends StatefulWidget {
  final MdDocumentSession session;
  final ScrollController scrollController;
  final bool readOnly;

  const _FrontMatterForm({
    required this.session,
    required this.scrollController,
    required this.readOnly,
  });

  @override
  State<_FrontMatterForm> createState() => _FrontMatterFormState();
}

class _FrontMatterFormState extends State<_FrontMatterForm> {
  /// The fields being edited, keyed by lower-cased name, in display order.
  late final Map<String, String> _values = _initialValues();

  /// The order the fields are shown in.
  late final List<String> _order = _values.keys.toList();

  final Map<String, TextEditingController> _controllers = {};

  /// Fields the app knows how to present nicely. Anything else gets a plain
  /// text box, which is still better than editing raw YAML.
  static const List<String> _suggested = ['title', 'date', 'author', 'tags'];

  Map<String, String> _initialValues() {
    final fm = widget.session.frontMatter;
    final values = <String, String>{};
    for (final field in fm.parsedFields) {
      values[field.lowerKey] = field.value;
    }
    // A file with no front matter starts with the common fields, empty, so the
    // form is something to fill in rather than a blank screen.
    if (values.isEmpty) {
      for (final key in _suggested) {
        values[key] = '';
      }
    }
    return values;
  }

  TextEditingController _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: _values[key] ?? ''),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final source = widget.session.code?.text ?? '';
    final updated = MdFrontMatter.applyEdits(source, _values);
    if (updated != source) {
      // Written as a normal edit, so it lands on the undo stack and still has
      // to be saved — the form never writes to disk by itself.
      widget.session.applyEdit(updated, 0, 0);
    }
    Navigator.of(context).pop();
  }

  Future<void> _addField() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mdFrontMatterAddField),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.mdFrontMatterFieldName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.mdFrontMatterAdd),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final key = name.toLowerCase();
    if (_values.containsKey(key)) return;
    setState(() {
      _values[key] = '';
      _order.add(key);
    });
  }

  Future<void> _pickDate(String key) async {
    final current = DateTime.tryParse(_values[key] ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (picked == null) return;
    final text = DateFormat('yyyy-MM-dd').format(picked);
    setState(() {
      _values[key] = text;
      _controllerFor(key).text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final present = widget.session.frontMatter.present;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mdFrontMatterTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                present ? l10n.mdFrontMatterHelp : l10n.mdFrontMatterNone,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              for (final key in _order) _field(l10n, key),
              const SizedBox(height: 8),
              if (!widget.readOnly)
                OutlinedButton.icon(
                  key: const Key('md-front-matter-add'),
                  onPressed: _addField,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.mdFrontMatterAddField),
                ),
            ],
          ),
        ),
        if (!widget.readOnly)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('md-front-matter-save'),
                  onPressed: _save,
                  child: Text(l10n.mdFrontMatterApply),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _field(AppLocalizations l10n, String key) {
    if (key == 'tags') return _tagsField(l10n);

    final isDate = key == 'date';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: Key('md-front-matter-$key'),
        controller: _controllerFor(key),
        readOnly: widget.readOnly,
        decoration: InputDecoration(
          labelText: _label(key),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: isDate && !widget.readOnly
              ? IconButton(
                  tooltip: l10n.mdFrontMatterPickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  onPressed: () => _pickDate(key),
                )
              : null,
        ),
        onChanged: (value) => _values[key] = value,
      ),
    );
  }

  /// Tags get a chip editor, because typing commas in the right places is
  /// exactly the fiddly bit this form is meant to remove.
  Widget _tagsField(AppLocalizations l10n) {
    final tags = (_values['tags'] ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_label('tags'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var i = 0; i < tags.length; i++)
                InputChip(
                  label: Text(tags[i]),
                  visualDensity: VisualDensity.compact,
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    key: Key('md-front-matter-tag-remove-${tags[i]}'),
                  ),
                  onDeleted: widget.readOnly
                      ? null
                      : () => setState(() {
                            final next = List<String>.from(tags)..removeAt(i);
                            _values['tags'] = next.join(', ');
                          }),
                ),
            ],
          ),
          if (!widget.readOnly)
            TextField(
              key: const Key('md-front-matter-tag-input'),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.mdFrontMatterAddTag,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final tag = value.trim();
                if (tag.isEmpty) return;
                setState(() {
                  _values['tags'] = [...tags, tag].join(', ');
                });
              },
            ),
        ],
      ),
    );
  }

  /// A readable label: the key with its first letter capitalised.
  String _label(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }
}
