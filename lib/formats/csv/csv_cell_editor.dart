import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A small dialog to edit one cell or a header name (task 7.5). Returns the new
/// value, or null if the user cancels.
Future<String?> showCsvCellEditor(
  BuildContext context, {
  required String title,
  required String initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _CsvCellEditorDialog(
      title: title,
      initialValue: initialValue,
    ),
  );
}

class _CsvCellEditorDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _CsvCellEditorDialog({required this.title, required this.initialValue});

  @override
  State<_CsvCellEditorDialog> createState() => _CsvCellEditorDialogState();
}

class _CsvCellEditorDialogState extends State<_CsvCellEditorDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(AppLocalizations.of(context).actionOk),
        ),
      ],
    );
  }
}
