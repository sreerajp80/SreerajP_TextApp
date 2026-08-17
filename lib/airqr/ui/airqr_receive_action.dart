import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/airqr/airqr_payload.dart';
import 'package:sreerajp_textapp/airqr/ui/airqr_receive_screen.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/open_file_action.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';

/// Opens the receive screen and saves whatever comes back.
///
/// The received text is written through the **system file picker**, so the user
/// picks the name and the folder. The sending device has no say in where a file
/// lands — it only suggests a name, and even that is sanitised in
/// [AirqrPayload]. That is what keeps optical transfer inside the app's
/// scoped-storage rule (CLAUDE.md §3 rule 3).
class AirqrReceiveAction {
  final WidgetRef ref;

  const AirqrReceiveAction(this.ref);

  /// Runs the whole receive flow. Returns silently if the user backs out.
  Future<void> receive(BuildContext context) async {
    final payload = await Navigator.of(context).push<AirqrPayload>(
      MaterialPageRoute(builder: (_) => const AirqrReceiveScreen()),
    );
    if (payload == null || !context.mounted) return;
    await saveToFile(context, payload);
  }

  /// Writes [payload] to a file the user chooses, then opens it in a tab.
  Future<void> saveToFile(BuildContext context, AirqrPayload payload) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saf = ref.read(safServiceProvider);

    SafFile file;
    try {
      file = await saf.createDocument(
        suggestedName: payload.name,
        bytes: Uint8List.fromList(utf8.encode(payload.content)),
        mimeType: payload.mime,
      );
    } on SafCancelled {
      return;
    } on SafException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.airqrSavedAs(file.displayName))),
    );
    if (!context.mounted) return;
    await OpenFileAction(
      ref,
    ).openFile(context, file, initialViewMode: TabViewMode.edit);
  }
}
