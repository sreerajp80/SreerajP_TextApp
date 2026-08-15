import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:text_data/airqr/airqr_codec.dart';
import 'package:text_data/airqr/airqr_constants.dart';
import 'package:text_data/airqr/airqr_payload.dart';
import 'package:text_data/airqr/airqr_receiver.dart';
import 'package:text_data/airqr/airqr_sender.dart';

AirqrPayload _payload(String content) => AirqrPayload.build(
  kind: AirqrConstants.kindDocument,
  name: 'notes.txt',
  mime: 'text/plain',
  content: content,
);

/// High-entropy text, so gzip cannot collapse the payload into a single frame.
/// Seeded, so every run splits the same way.
String _incompressible(int length) {
  final random = Random(7);
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes([
    for (var i = 0; i < length; i++)
      alphabet.codeUnitAt(random.nextInt(alphabet.length)),
  ]);
}

/// A payload big enough to need several frames even after gzip.
AirqrEncoded _multiFrame(String code) =>
    AirqrCodec.encode(payload: _payload(_incompressible(9000)), code: code);

void main() {
  group('collecting frames', () {
    test('a clean first pass completes the transfer', () {
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final receiver = AirqrReceiver();

      for (final frame in encoded.allFrames) {
        receiver.offer(frame);
      }

      expect(receiver.isComplete, isTrue);
      expect(receiver.framesReceived, encoded.totalFrames);
      expect(receiver.needsCode, isTrue);
      expect(
        receiver.assemble(code: code).content,
        _payloadContentOf(encoded, code),
      );
    });

    test('duplicate frames are ignored and do not move progress', () {
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final receiver = AirqrReceiver();

      receiver.offer(encoded.manifestFrame);
      expect(
        receiver.offer(encoded.dataFrames.first).outcome,
        AirqrOfferOutcome.accepted,
      );
      final after = receiver.framesReceived;

      expect(
        receiver.offer(encoded.dataFrames.first).outcome,
        AirqrOfferOutcome.duplicate,
      );
      expect(receiver.framesReceived, after);
      expect(
        receiver.offer(encoded.manifestFrame).outcome,
        AirqrOfferOutcome.duplicate,
      );
    });

    test('frames arriving out of order still reassemble', () {
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final expected = _payloadContentOf(encoded, code);
      final receiver = AirqrReceiver();

      final shuffled = [...encoded.dataFrames].reversed;
      for (final frame in shuffled) {
        receiver.offer(frame);
      }
      receiver.offer(encoded.manifestFrame);

      expect(receiver.isComplete, isTrue);
      expect(receiver.assemble(code: code).content, expected);
    });

    test('data frames seen before the manifest are kept', () {
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final receiver = AirqrReceiver();

      // The user starts scanning mid-cycle, so the manifest comes last.
      for (final frame in encoded.dataFrames) {
        receiver.offer(frame);
      }
      expect(receiver.hasManifest, isFalse);
      expect(
        receiver.isComplete,
        isFalse,
        reason: 'without the manifest it cannot be complete',
      );

      receiver.offer(encoded.manifestFrame);
      expect(receiver.isComplete, isTrue);
    });
  });

  group('dropped frames', () {
    test('a frame missed on the first pass is recovered on the second', () {
      // This is the core claim of the design: cyclic repetition replaces
      // cross-frame erasure coding. Simulate a camera that misses every third
      // frame on pass one, then catches up on pass two.
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final expected = _payloadContentOf(encoded, code);
      final sender = AirqrSender(encoded);
      final receiver = AirqrReceiver();

      // Bounded so a broken implementation fails the test instead of hanging.
      final maxScans = encoded.allFrames.length * 10;
      var scan = 0;
      var guard = 0;
      while (!receiver.isComplete && guard < maxScans) {
        if (scan % 3 != 0) {
          receiver.offer(sender.currentFrame);
        }
        sender.advance();
        scan++;
        guard++;
      }
      expect(guard, lessThan(maxScans), reason: 'it must not loop forever');

      expect(
        receiver.isComplete,
        isTrue,
        reason: 'looping must eventually deliver every frame',
      );
      expect(
        sender.passesCompleted,
        greaterThanOrEqualTo(1),
        reason: 'recovery should have needed more than one pass',
      );
      expect(receiver.assemble(code: code).content, expected);
    });

    test('a drop pattern aligned to the cycle still completes', () {
      // Regression test. The sender used to repeat the same frame order every
      // pass, so a camera dropping frames on a period equal to the cycle length
      // missed the SAME frame forever and the transfer never finished. The
      // sender now rotates the data frames each pass, which breaks that
      // alignment. Without the rotation this test hangs until the guard trips.
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final sender = AirqrSender(encoded);
      final receiver = AirqrReceiver();
      final period = sender.cycleLength;

      final maxScans = period * 20;
      var scan = 0;
      while (!receiver.isComplete && scan < maxScans) {
        // Drop one scan every full cycle — the worst case for a fixed order.
        if (scan % period != 0) {
          receiver.offer(sender.currentFrame);
        }
        sender.advance();
        scan++;
      }

      expect(
        receiver.isComplete,
        isTrue,
        reason: 'rotation must break a cycle-aligned drop pattern',
      );
      expect(
        receiver.assemble(code: code).content,
        _payloadContentOf(encoded, code),
      );
    });

    test('every small drop period completes', () {
      // Regression test for the third aliasing failure. A rotate-by-one sender
      // dies whenever the drop period and the cycle length line up (a 16-frame
      // cycle losing every 3rd scan loses every 3rd frame forever, because the
      // +1 shift cancels exactly). Sweep the small periods so no single shift
      // trick can pass this by luck.
      const code = 'ABCDEF';
      for (var period = 2; period <= 8; period++) {
        final encoded = _multiFrame(code);
        final sender = AirqrSender(encoded);
        final receiver = AirqrReceiver();

        final maxScans = sender.cycleLength * 30;
        var scan = 0;
        while (!receiver.isComplete && scan < maxScans) {
          if (scan % period != 0) {
            receiver.offer(sender.currentFrame);
          }
          sender.advance();
          scan++;
        }

        expect(
          receiver.isComplete,
          isTrue,
          reason: 'a drop every $period scans must still complete',
        );
      }
    });

    test('missingFrames lists exactly what has not arrived', () {
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final receiver = AirqrReceiver();

      receiver.offer(encoded.manifestFrame);
      for (var i = 0; i < encoded.totalFrames; i++) {
        if (i == 2) continue; // drop one
        receiver.offer(encoded.dataFrames[i]);
      }

      expect(receiver.missingFrames, [2]);
      expect(receiver.isComplete, isFalse);
      expect(
        () => receiver.assemble(code: code),
        throwsA(isA<AirqrFrameException>()),
      );

      receiver.offer(encoded.dataFrames[2]);
      expect(receiver.missingFrames, isEmpty);
      expect(receiver.isComplete, isTrue);
    });

    test('progress reflects how much has arrived', () {
      const code = 'ABCDEF';
      final encoded = _multiFrame(code);
      final receiver = AirqrReceiver();

      expect(receiver.progress, 0);
      receiver.offer(encoded.manifestFrame);
      for (final frame in encoded.dataFrames) {
        receiver.offer(frame);
      }
      expect(receiver.progress, 1.0);
    });
  });

  group('hostile and mixed input', () {
    test('a foreign QR is reported and otherwise ignored', () {
      final receiver = AirqrReceiver();
      final result = receiver.offer('https://example.com');

      expect(result.outcome, AirqrOfferOutcome.rejected);
      expect(result.message, isNotNull);
      expect(receiver.framesReceived, 0);
    });

    test('a manifest for a different transfer restarts collection', () {
      const code = 'ABCDEF';
      final first = _multiFrame(code);
      final second = AirqrCodec.encode(
        payload: _payload('a completely different document'),
        code: code,
      );
      final receiver = AirqrReceiver();

      receiver.offer(first.manifestFrame);
      receiver.offer(first.dataFrames.first);
      expect(receiver.framesReceived, 1);

      final result = receiver.offer(second.manifestFrame);
      expect(result.outcome, AirqrOfferOutcome.restarted);
      expect(
        receiver.framesReceived,
        0,
        reason: 'frames from the old transfer must not be mixed in',
      );

      for (final frame in second.dataFrames) {
        receiver.offer(frame);
      }
      expect(
        receiver.assemble(code: code).content,
        'a completely different document',
      );
    });

    test('a frame from a differently sized transfer is rejected', () {
      const code = 'ABCDEF';
      final small = AirqrCodec.encode(payload: _payload('tiny'), code: code);
      final big = _multiFrame(code);
      final receiver = AirqrReceiver();

      receiver.offer(small.manifestFrame);
      final result = receiver.offer(big.dataFrames.first);

      expect(result.outcome, AirqrOfferOutcome.rejected);
    });

    test('the wrong code is reported when assembling', () {
      final encoded = _multiFrame('ABCDEF');
      final receiver = AirqrReceiver();
      for (final frame in encoded.allFrames) {
        receiver.offer(frame);
      }

      expect(
        () => receiver.assemble(code: 'ZZZZZZ'),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('reset clears everything', () {
      final encoded = _multiFrame('ABCDEF');
      final receiver = AirqrReceiver();
      receiver.offer(encoded.manifestFrame);
      receiver.offer(encoded.dataFrames.first);

      receiver.reset();

      expect(receiver.framesReceived, 0);
      expect(receiver.hasManifest, isFalse);
      expect(receiver.totalFrames, isNull);
      expect(receiver.isComplete, isFalse);
    });
  });

  group('sender cycle', () {
    test('loops through the manifest and every data frame', () {
      final encoded = _multiFrame('ABCDEF');
      final sender = AirqrSender(encoded);
      final seen = <String>{};

      for (var i = 0; i < sender.cycleLength; i++) {
        seen.add(sender.currentFrame);
        sender.advance();
      }

      expect(seen.length, encoded.allFrames.length);
      expect(sender.passesCompleted, 1);
      expect(sender.position, 0, reason: 'it wraps back to the manifest');
    });

    test('the manifest appears exactly once in every pass', () {
      // A receiver starting late must never wait more than one cycle for the
      // manifest, even though the cycle rotates.
      final encoded = _multiFrame('ABCDEF');
      final sender = AirqrSender(encoded);

      for (var pass = 0; pass < 5; pass++) {
        var manifestSeen = 0;
        final seen = <String>{};
        for (var i = 0; i < sender.cycleLength; i++) {
          if (sender.currentFrame == encoded.manifestFrame) manifestSeen++;
          seen.add(sender.currentFrame);
          sender.advance();
        }
        expect(manifestSeen, 1, reason: 'pass $pass');
        expect(
          seen.length,
          encoded.allFrames.length,
          reason: 'pass $pass must still show every frame',
        );
      }
    });
  });
}

/// Decodes an encoded set the direct way, to get the expected content without
/// depending on the receiver under test.
String _payloadContentOf(AirqrEncoded encoded, String code) {
  final manifest = AirqrCodec.parseFrame(encoded.manifestFrame).manifest!;
  return AirqrCodec.assemble(
    manifest: manifest,
    orderedChunks: [
      for (final f in encoded.dataFrames) AirqrCodec.parseFrame(f).data!.bytes,
    ],
    code: code,
  ).content;
}
