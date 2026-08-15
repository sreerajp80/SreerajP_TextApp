import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:text_data/airqr/airqr_codec.dart';
import 'package:text_data/airqr/airqr_constants.dart';
import 'package:text_data/airqr/airqr_payload.dart';

/// Guards security-rules: AirQR code must NEVER log the session code, the
/// derived key, the salt, or any frame or payload content — not even in debug
/// builds. A QR stream is already visible to anyone who can see the screen;
/// writing its contents to the log would put it somewhere the user cannot see
/// at all.
///
/// This mirrors `test/sync/no_secret_logging_test.dart`.
void main() {
  test('lib/airqr has no logging calls', () {
    final dir = Directory('lib/airqr');
    expect(dir.existsSync(), isTrue, reason: 'lib/airqr must exist');

    final offenders = <String>[];
    // Matches print(...), debugPrint(...), log(...), stdout/stderr writes.
    final logCall = RegExp(r'\b(print|debugPrint|log|stderr|stdout)\s*(\.|\()');

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Ignore comments.
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (logCall.hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'No logging is allowed in lib/airqr (security-rules). Found:\n'
          '${offenders.join('\n')}',
    );
  });

  test('no frame carries the session code or the plaintext', () {
    // The code is the out-of-band secret: it travels by voice or by hand, never
    // inside a QR. If a frame carried it, sealing would be pointless — anyone
    // who could scan the stream could also read the key. And no frame may carry
    // recognisable plaintext, which is the whole point of sealing.
    const code = 'PQRSTU';
    const secretText = 'PATIENT-RECORD-42-CONFIDENTIAL';

    final encoded = AirqrCodec.encode(
      payload: AirqrPayload.build(
        kind: AirqrConstants.kindDocument,
        name: 'secret-filename.txt',
        mime: 'text/plain',
        content: secretText,
      ),
      code: code,
    );

    for (final frame in encoded.allFrames) {
      expect(
        frame.contains(code),
        isFalse,
        reason: 'a frame leaked the session code',
      );
      expect(
        frame.contains(secretText),
        isFalse,
        reason: 'a frame leaked the document content',
      );
      expect(
        frame.contains('secret-filename'),
        isFalse,
        reason: 'a frame leaked the file name',
      );
    }
  });
}
