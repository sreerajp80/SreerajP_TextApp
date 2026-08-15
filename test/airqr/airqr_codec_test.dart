import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:text_data/airqr/airqr_codec.dart';
import 'package:text_data/airqr/airqr_constants.dart';
import 'package:text_data/airqr/airqr_payload.dart';

/// Encodes, then decodes straight back through the codec, as a receiver that
/// caught every frame on the first pass would.
AirqrPayload _roundTrip(AirqrEncoded encoded, {String? code}) {
  final manifest = AirqrCodec.parseFrame(encoded.manifestFrame).manifest!;
  final chunks = <Uint8List>[
    for (final f in encoded.dataFrames) AirqrCodec.parseFrame(f).data!.bytes,
  ];
  return AirqrCodec.assemble(
    manifest: manifest,
    orderedChunks: chunks,
    code: code,
  );
}

/// High-entropy text, so gzip cannot collapse it and the payload really does
/// span several frames. Seeded, so the test is deterministic.
String _incompressible(int length) {
  final random = Random(42);
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes([
    for (var i = 0; i < length; i++)
      alphabet.codeUnitAt(random.nextInt(alphabet.length)),
  ]);
}

AirqrPayload _samplePayload({String? content}) => AirqrPayload.build(
  kind: AirqrConstants.kindDocument,
  name: 'notes.md',
  mime: 'text/markdown',
  content: content ?? '# Heading\n\nSome text with unicode: മലയാളം and é.\n',
);

void main() {
  group('session code', () {
    test('generates a code of the requested length from the alphabet', () {
      final code = AirqrCodec.generateSessionCode();
      expect(code.length, AirqrConstants.shortCodeLength);
      for (final ch in code.split('')) {
        expect(AirqrConstants.codeAlphabet.contains(ch), isTrue);
      }
    });

    test('excludes the look-alike characters', () {
      // Sample enough codes that a stray character would almost certainly show.
      for (var i = 0; i < 200; i++) {
        final code = AirqrCodec.generateSessionCode(
          length: AirqrConstants.longCodeLength,
        );
        expect(RegExp(r'[01OIL]').hasMatch(code), isFalse);
      }
    });

    test('normalize strips separators and upper-cases', () {
      expect(AirqrCodec.normalizeCode('abc-def'), 'ABCDEF');
      expect(AirqrCodec.normalizeCode(' ab c def '), 'ABCDEF');
    });

    test('format groups for display without changing the value', () {
      expect(AirqrCodec.formatCode('ABCDEF'), 'ABC-DEF');
      expect(
        AirqrCodec.normalizeCode(AirqrCodec.formatCode('ABCDEF')),
        'ABCDEF',
      );
    });

    test('validates length and alphabet', () {
      expect(AirqrCodec.isValidCode('ABCDEF'), isTrue);
      expect(AirqrCodec.isValidCode('ABCDE'), isFalse, reason: 'too short');
      expect(
        AirqrCodec.isValidCode('ABCDEFGHJKMNPQ'),
        isFalse,
        reason: 'too long',
      );
      expect(
        AirqrCodec.isValidCode('ABCDE0'),
        isFalse,
        reason: '0 is not in the alphabet',
      );
    });
  });

  group('round trip', () {
    test('sealed and compressed payload survives', () {
      final code = AirqrCodec.generateSessionCode();
      final payload = _samplePayload();
      final encoded = AirqrCodec.encode(payload: payload, code: code);
      final out = _roundTrip(encoded, code: code);

      expect(out.content, payload.content);
      expect(out.name, 'notes.md');
      expect(out.mime, 'text/markdown');
      expect(out.kind, AirqrConstants.kindDocument);
    });

    test('unsealed payload survives', () {
      final payload = _samplePayload();
      final encoded = AirqrCodec.encode(payload: payload);
      expect(_roundTrip(encoded).content, payload.content);
    });

    test('uncompressed payload survives', () {
      final code = AirqrCodec.generateSessionCode();
      final payload = _samplePayload();
      final encoded = AirqrCodec.encode(
        payload: payload,
        code: code,
        compress: false,
      );
      expect(_roundTrip(encoded, code: code).content, payload.content);
    });

    test('a large payload splits into many frames and still survives', () {
      final code = AirqrCodec.generateSessionCode();
      // Deliberately low-entropy so gzip works, which is the realistic case.
      final big = List.generate(
        400,
        (i) => 'Line $i of the document.',
      ).join('\n');
      final payload = _samplePayload(content: big);
      final encoded = AirqrCodec.encode(payload: payload, code: code);

      expect(encoded.totalFrames, greaterThan(1));
      expect(_roundTrip(encoded, code: code).content, big);
    });

    test('compression actually shrinks repetitive text', () {
      final payload = _samplePayload(content: 'the same line\n' * 500);
      final compressed = AirqrCodec.encode(payload: payload);
      final plain = AirqrCodec.encode(payload: payload, compress: false);
      expect(compressed.wireBytes, lessThan(plain.wireBytes));
    });

    test('every frame stays inside the raw frame cap', () {
      final code = AirqrCodec.generateSessionCode();
      final payload = _samplePayload(content: 'x' * 20000);
      final encoded = AirqrCodec.encode(payload: payload, code: code);
      for (final f in encoded.allFrames) {
        expect(f.length, lessThanOrEqualTo(AirqrConstants.maxRawFrameLength));
      }
    });
  });

  group('rejects bad input without throwing to the UI', () {
    test('wrong code fails the GCM tag', () {
      final payload = _samplePayload();
      final encoded = AirqrCodec.encode(payload: payload, code: 'ABCDEF');
      expect(
        () => _roundTrip(encoded, code: 'ZZZZZZ'),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('a sealed transfer with no code is refused', () {
      final encoded = AirqrCodec.encode(
        payload: _samplePayload(),
        code: 'ABCDEF',
      );
      expect(() => _roundTrip(encoded), throwsA(isA<AirqrFrameException>()));
    });

    test('a foreign QR is rejected', () {
      expect(
        () => AirqrCodec.parseFrame('https://example.com/hello'),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('the LAN pairing QR is rejected by the AirQR parser', () {
      // The two features both use QR codes; neither must accept the other's.
      expect(
        () => AirqrCodec.parseFrame(
          'textdatasync://pair?v=1&h=1.2.3.4&p=45000&c=AB',
        ),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('a version mismatch is rejected', () {
      const future = AirqrConstants.protocolVersion + 1;
      expect(
        () => AirqrCodec.parseFrame('textdataqr://f?v=$future&i=0&n=1&d=AAAA'),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('an over-long scan is rejected before parsing', () {
      final huge = 'textdataqr://f?v=1&i=0&n=1&d=${'A' * 20000}';
      expect(
        () => AirqrCodec.parseFrame(huge),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('a frame index outside the total is rejected', () {
      expect(
        () => AirqrCodec.parseFrame('textdataqr://f?v=1&i=5&n=2&d=AAAA'),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('a manifest with a malformed digest is rejected', () {
      expect(
        () => AirqrCodec.parseFrame(
          'textdataqr://m?v=1&n=1&k=document&h=notadigest&z=1&e=0',
        ),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('a manifest with an unknown kind is rejected', () {
      final digest = 'a' * 64;
      expect(
        () => AirqrCodec.parseFrame(
          'textdataqr://m?v=1&n=1&k=malware&h=$digest&z=1&e=0',
        ),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('a corrupted chunk is caught rather than returned as content', () {
      final code = AirqrCodec.generateSessionCode();
      final encoded = AirqrCodec.encode(
        payload: _samplePayload(content: _incompressible(6000)),
        code: code,
      );
      final manifest = AirqrCodec.parseFrame(encoded.manifestFrame).manifest!;
      final chunks = <Uint8List>[
        for (final f in encoded.dataFrames)
          AirqrCodec.parseFrame(f).data!.bytes,
      ];
      expect(
        chunks.length,
        greaterThan(1),
        reason: 'the test needs a mid-stream chunk to corrupt',
      );
      // Flip the contents of one chunk, mid-stream.
      chunks[1] = Uint8List.fromList(utf8.encode('A' * chunks[1].length));

      expect(
        () => AirqrCodec.assemble(
          manifest: manifest,
          orderedChunks: chunks,
          code: code,
        ),
        throwsA(isA<AirqrFrameException>()),
      );
    });

    test('an incomplete chunk list is refused', () {
      final encoded = AirqrCodec.encode(
        payload: _samplePayload(content: 'x' * 5000),
      );
      final manifest = AirqrCodec.parseFrame(encoded.manifestFrame).manifest!;
      expect(
        () => AirqrCodec.assemble(manifest: manifest, orderedChunks: const []),
        throwsA(isA<AirqrFrameException>()),
      );
    });
  });
}
