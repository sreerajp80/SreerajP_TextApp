import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/print/print_service.dart';

class _FakeLauncher implements PrintLauncher {
  PrintJob? lastJob;

  @override
  Future<void> layoutPdf(PrintJob job) async {
    lastJob = job;
  }
}

void main() {
  test('PrintService builds a print job for a sample document', () async {
    final launcher = _FakeLauncher();
    final service = PrintService(launcher);
    final pdf = Uint8List.fromList('%PDF-1.4'.codeUnits);

    await service.printPdf(pdf, docName: 'notes');

    expect(launcher.lastJob!.pdfBytes, pdf);
    expect(launcher.lastJob!.docName, 'notes');
  });
}
