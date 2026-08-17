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
import 'package:sreerajp_textapp/formats/txt/txt_document_session.dart';

/// UI actions for the Phase 5 output services on a TXT document: share, share
/// as zip, print, and export/convert. The services are shared and host-tested;
/// these helpers gather the current content and route it to the right service,
/// reporting the outcome with a snackbar.
class TxtOutputActions {
  static const formatId = 'txt';

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

  const TxtOutputActions({
    required this.share,
    required this.zip,
    required this.print,
    required this.export,
    required this.saf,
    this.codec = const TextCodecService(),
    this.onOutputCompleted,
  });

  /// The current text encoded to file bytes, preserving the session's encoding
  /// and line ending.
  Uint8List _bytes(TxtDocumentSession session) => codec.encode(
    session.textContent.text,
    session.encoding,
    session.lineEnding,
  );

  /// Shares the file (its current text) through the Android share sheet.
  Future<void> shareFile(
    BuildContext context,
    TxtDocumentSession session,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await share.shareFileBytes(
        name: session.tab.displayName,
        mimeType: session.tab.mimeType ?? 'text/plain',
        bytes: _bytes(session),
      );
      onOutputCompleted?.call();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.outShareFileFailed)));
    }
  }

  /// Zips the file, then shares the zip.
  Future<void> shareAsZip(
    BuildContext context,
    TxtDocumentSession session,
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

  /// Prints the document using its PDF rendering (the "natural" output for TXT).
  Future<void> printDoc(
    BuildContext context,
    TxtDocumentSession session,
  ) async {
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

  /// Runs an export to [target] and returns the produced result, or `null` on
  /// failure (with a snackbar).
  Future<ExportResult?> runExport(
    BuildContext context,
    TxtDocumentSession session,
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

  /// Saves an already-produced [result] to a new file the user picks.
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

  /// Shares an already-produced [result] through the share sheet.
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
