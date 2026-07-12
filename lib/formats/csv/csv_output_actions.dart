import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../core/export/export_service.dart';
import '../../core/export/export_target.dart';
import '../../core/print/print_service.dart';
import '../../core/share/share_service.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../core/zip/zip_service.dart';
import '../../l10n/app_localizations.dart';
import 'csv_document_session.dart';

/// UI actions for the shared output services on a CSV document: share, share as
/// zip, print, and export/convert (task 7.6). Mirrors `MdOutputActions`; the
/// services are shared and host-tested, so these helpers only gather the current
/// content and route it to the right service, reporting the outcome with a
/// snackbar.
class CsvOutputActions {
  static const formatId = 'csv';

  final ShareService share;
  final ZipService zip;
  final PrintService print;
  final ExportService export;
  final SafService saf;
  final TextCodecService codec;

  const CsvOutputActions({
    required this.share,
    required this.zip,
    required this.print,
    required this.export,
    required this.saf,
    this.codec = const TextCodecService(),
  });

  Uint8List _bytes(CsvDocumentSession session) => codec.encode(
        session.currentText,
        session.encoding,
        session.lineEnding,
      );

  Future<void> shareFile(
    BuildContext context,
    CsvDocumentSession session,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await share.shareFileBytes(
        name: session.tab.displayName,
        mimeType: session.tab.mimeType ?? 'text/csv',
        bytes: _bytes(session),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outShareFileFailed)),
      );
    }
  }

  Future<void> shareAsZip(
    BuildContext context,
    CsvDocumentSession session,
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
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outShareZipFailed)),
      );
    }
  }

  Future<void> printDoc(
    BuildContext context,
    CsvDocumentSession session,
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
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outPrintFailed)),
      );
    }
  }

  /// Runs an export for [target]. When [content] is given it exports only that
  /// content (e.g. the selected / filtered rows); otherwise the whole document.
  Future<ExportResult?> runExport(
    BuildContext context,
    CsvDocumentSession session,
    ExportTarget target, {
    TextContent? content,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      return await export.export(
        formatId,
        target,
        content ?? session.textContent,
      );
    } on UnsupportedExportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outExportFailed)),
      );
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
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outShareExportFailed)),
      );
    }
  }
}
