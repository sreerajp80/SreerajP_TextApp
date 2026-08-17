import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/core/editor/encoding.dart';
import 'package:sreerajp_textapp/core/export/export_service.dart';
import 'package:sreerajp_textapp/core/export/export_target.dart';
import 'package:sreerajp_textapp/core/print/print_service.dart';
import 'package:sreerajp_textapp/core/share/share_service.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/zip/zip_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/markdown/md_document_session.dart';

/// UI actions for the shared output services on a Markdown document: share,
/// share as zip, print, and export/convert (task 6.5). Mirrors
/// `TxtOutputActions`; the services are shared and host-tested, so these helpers
/// only gather the current content and route it to the right service, reporting
/// the outcome with a snackbar.
class MdOutputActions {
  static const formatId = 'md';

  final ShareService share;
  final ZipService zip;
  final PrintService print;
  final ExportService export;
  final SafService saf;
  final TextCodecService codec;

  /// Called after a **successful** share, print, or export of this document.
  /// Drives "burn after export" on a self-destructing tab (Feature 9), so a
  /// cancelled or failed output can never destroy the document.
  final void Function()? onOutputCompleted;

  const MdOutputActions({
    required this.share,
    required this.zip,
    required this.print,
    required this.export,
    required this.saf,
    this.codec = const TextCodecService(),
    this.onOutputCompleted,
  });

  Uint8List _bytes(MdDocumentSession session) => codec.encode(
    session.textContent.text,
    session.encoding,
    session.lineEnding,
  );

  Future<void> shareFile(
    BuildContext context,
    MdDocumentSession session,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await share.shareFileBytes(
        name: session.tab.displayName,
        mimeType: session.tab.mimeType ?? 'text/markdown',
        bytes: _bytes(session),
      );
      onOutputCompleted?.call();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.outShareFileFailed)));
    }
  }

  Future<void> shareAsZip(
    BuildContext context,
    MdDocumentSession session,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final content = session.textContent;
      final zipped = zip.zipOne(session.tab.displayName, _bytes(session));
      await share.shareFileBytes(
        name: '${content.baseName}.zip',
        mimeType: 'application/zip',
        bytes: zipped,
      );
      onOutputCompleted?.call();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.outShareZipFailed)));
    }
  }

  Future<void> printDoc(BuildContext context, MdDocumentSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final result = await export.export(
        formatId,
        ExportTarget.pdf,
        session.textContent,
      );
      await print.printPdf(result.bytes, docName: session.textContent.baseName);
      onOutputCompleted?.call();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.outPrintFailed)));
    }
  }

  Future<ExportResult?> runExport(
    BuildContext context,
    MdDocumentSession session,
    ExportTarget target,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      return await export.export(formatId, target, session.textContent);
    } on UnsupportedExportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.outExportFailed)));
      return null;
    }
  }

  Future<void> saveExport(BuildContext context, ExportResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final file = await saf.createDocument(
        suggestedName: result.suggestedName,
        bytes: result.bytes,
        mimeType: result.mimeType,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outSaved(file.displayName))),
      );
      onOutputCompleted?.call();
    } on SafCancelled {
      // User backed out — nothing to report.
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> shareExport(BuildContext context, ExportResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await share.shareFileBytes(
        name: result.suggestedName,
        mimeType: result.mimeType,
        bytes: result.bytes,
      );
      onOutputCompleted?.call();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outShareExportFailed)),
      );
    }
  }
}
