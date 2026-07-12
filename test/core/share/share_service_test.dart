import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/share/share_service.dart';

class _FakeLauncher implements ShareLauncher {
  List<ShareFileRequest>? lastFiles;
  String? lastSubject;
  String? lastText;

  @override
  Future<void> shareFiles(
    List<ShareFileRequest> requests, {
    String? subject,
  }) async {
    lastFiles = requests;
    lastSubject = subject;
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    lastText = text;
    lastSubject = subject;
  }
}

void main() {
  group('ShareService', () {
    test('builds a file request with the right name, MIME, and bytes', () async {
      final launcher = _FakeLauncher();
      final service = ShareService(launcher);
      final bytes = Uint8List.fromList('data'.codeUnits);

      await service.shareFileBytes(
        name: 'export.pdf',
        mimeType: 'application/pdf',
        bytes: bytes,
        subject: 'My export',
      );

      final req = launcher.lastFiles!.single;
      expect(req.name, 'export.pdf');
      expect(req.mimeType, 'application/pdf');
      expect(req.bytes, bytes);
      expect(launcher.lastSubject, 'My export');
    });

    test('shares raw text', () async {
      final launcher = _FakeLauncher();
      await ShareService(launcher).shareText('hello', subject: 'note');
      expect(launcher.lastText, 'hello');
      expect(launcher.lastSubject, 'note');
    });
  });
}
