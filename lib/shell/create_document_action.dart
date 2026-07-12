import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/saf_exceptions.dart';
import '../core/storage/saf_service.dart';
import '../l10n/app_localizations.dart';
import 'open_file_action.dart';
import 'tabs/document_tab.dart';

/// A supported blank-document type and the safe starter file created for it.
enum NewDocumentFormat {
  txt(
    suggestedName: 'untitled.txt',
    mimeType: 'text/plain',
    starterText: '',
    icon: Icons.description_outlined,
  ),
  markdown(
    suggestedName: 'untitled.md',
    mimeType: 'text/markdown',
    starterText: '',
    icon: Icons.article_outlined,
  ),
  csv(
    suggestedName: 'untitled.csv',
    mimeType: 'text/csv',
    starterText: '',
    icon: Icons.table_chart_outlined,
  ),
  json(
    suggestedName: 'untitled.json',
    mimeType: 'application/json',
    starterText: '{}\n',
    icon: Icons.data_object,
  ),
  xml(
    suggestedName: 'untitled.xml',
    mimeType: 'application/xml',
    starterText: '<?xml version="1.0" encoding="UTF-8"?>\n<root></root>\n',
    icon: Icons.code_outlined,
  );

  final String suggestedName;
  final String mimeType;
  final String starterText;
  final IconData icon;

  const NewDocumentFormat({
    required this.suggestedName,
    required this.mimeType,
    required this.starterText,
    required this.icon,
  });

  Uint8List get starterBytes => Uint8List.fromList(utf8.encode(starterText));

  String label(AppLocalizations l10n) => switch (this) {
    NewDocumentFormat.txt => l10n.newDocumentTxt,
    NewDocumentFormat.markdown => l10n.newDocumentMarkdown,
    NewDocumentFormat.csv => l10n.newDocumentCsv,
    NewDocumentFormat.json => l10n.newDocumentJson,
    NewDocumentFormat.xml => l10n.newDocumentXml,
  };
}

/// Creates a supported file through Android's system picker, then sends the
/// result through the app's normal open-file flow.
class CreateDocumentAction {
  final WidgetRef ref;

  const CreateDocumentAction(this.ref);

  Future<void> showFormatPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final format = await showModalBottomSheet<NewDocumentFormat>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l10n.newDocumentChooseFormat,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final choice in NewDocumentFormat.values)
                ListTile(
                  leading: Icon(choice.icon),
                  title: Text(choice.label(l10n)),
                  subtitle: Text('.${choice.suggestedName.split('.').last}'),
                  onTap: () => Navigator.of(context).pop(choice),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (format == null || !context.mounted) return;
    await create(context, format);
  }

  Future<void> create(BuildContext context, NewDocumentFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final saf = ref.read(safServiceProvider);
    SafFile file;
    try {
      file = await saf.createDocument(
        suggestedName: format.suggestedName,
        bytes: format.starterBytes,
        mimeType: format.mimeType,
      );
    } on SafCancelled {
      return;
    } on SafException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!context.mounted) return;
    await OpenFileAction(
      ref,
    ).openFile(context, file, initialViewMode: TabViewMode.edit);
  }
}
