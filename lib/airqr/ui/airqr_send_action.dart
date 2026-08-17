import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/airqr/airqr_constants.dart';
import 'package:sreerajp_textapp/airqr/airqr_payload.dart';
import 'package:sreerajp_textapp/airqr/ui/airqr_send_screen.dart';
import 'package:sreerajp_textapp/airqr/ui/airqr_size_warning.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Starts an optical transfer from whatever the user is looking at.
///
/// Every format toolbar routes through here so the size gate, the payload
/// validation, and the failure messages stay identical across TXT, Markdown,
/// CSV, JSON, and XML. Widgets never build an [AirqrPayload] themselves.
class AirqrSendAction {
  const AirqrSendAction._();

  /// Sends a whole document.
  static Future<void> sendDocument({
    required BuildContext context,
    required String name,
    required String mimeType,
    required String content,
  }) => _send(
    context: context,
    kind: AirqrConstants.kindDocument,
    name: name,
    mimeType: mimeType,
    content: content,
  );

  /// Sends a piece of a document: a selection, a column, a subtree.
  static Future<void> sendSnippet({
    required BuildContext context,
    required String name,
    required String content,
  }) => _send(
    context: context,
    kind: AirqrConstants.kindSnippet,
    name: name,
    mimeType: 'text/plain',
    content: content,
  );

  static Future<void> _send({
    required BuildContext context,
    required String kind,
    required String name,
    required String mimeType,
    required String content,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    if (content.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.airqrNothingToSend)));
      return;
    }

    // Gate on size before building anything, so an oversized document fails
    // instantly instead of after a pointless compress-and-encode.
    final byteCount = utf8.encode(content).length;
    final proceed = await AirqrSizeWarning.confirm(
      context: context,
      byteCount: byteCount,
    );
    if (!proceed || !context.mounted) return;

    final AirqrPayload payload;
    try {
      payload = AirqrPayload.build(
        kind: kind,
        name: name,
        mime: mimeType,
        content: content,
      );
    } on AirqrPayloadException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AirqrSendScreen(payload: payload)),
    );
  }
}
