import 'dart:typed_data';

import 'package:printing/printing.dart';

/// A print job, captured as a value so tests can verify what would be printed
/// without opening the system print dialog.
class PrintJob {
  final Uint8List pdfBytes;
  final String docName;

  const PrintJob({required this.pdfBytes, required this.docName});
}

/// The platform side of printing, behind an interface so the [PrintService]
/// logic stays host-testable (arch §12). The real implementation calls
/// `printing`; tests inject a fake that records the job.
abstract class PrintLauncher {
  Future<void> layoutPdf(PrintJob job);
}

/// Default [PrintLauncher] backed by `printing` (task 5.3).
class PrintingLauncher implements PrintLauncher {
  const PrintingLauncher();

  @override
  Future<void> layoutPdf(PrintJob job) {
    return Printing.layoutPdf(
      name: job.docName,
      onLayout: (_) async => job.pdfBytes,
    );
  }
}

/// Shared print service (task 5.3).
///
/// A format prints by handing over the PDF bytes of its "natural" output; the
/// TXT toolbar builds those with the export [PdfWriter] first. The platform
/// call sits behind [PrintLauncher] so the job-building logic is unit-tested.
class PrintService {
  final PrintLauncher _launcher;

  const PrintService(this._launcher);

  /// Sends [pdfBytes] to the system print dialog under [docName].
  Future<void> printPdf(Uint8List pdfBytes, {required String docName}) {
    return _launcher.layoutPdf(PrintJob(pdfBytes: pdfBytes, docName: docName));
  }
}
