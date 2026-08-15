import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:text_data/airqr/airqr_constants.dart';
import 'package:text_data/airqr/airqr_payload.dart';

void main() {
  group('build', () {
    test('accepts a normal document', () {
      final payload = AirqrPayload.build(
        kind: AirqrConstants.kindDocument,
        name: 'notes.md',
        mime: 'text/markdown',
        content: 'hello',
      );
      expect(payload.isDocument, isTrue);
      expect(payload.isSnippet, isFalse);
      expect(payload.name, 'notes.md');
    });

    test('refuses an unknown kind', () {
      expect(
        () => AirqrPayload.build(
          kind: 'everything',
          name: 'x',
          mime: 'text/plain',
          content: 'hello',
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('refuses empty content', () {
      expect(
        () => AirqrPayload.build(
          kind: AirqrConstants.kindSnippet,
          name: 'x',
          mime: 'text/plain',
          content: '',
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('refuses content over the hard cap', () {
      expect(
        () => AirqrPayload.build(
          kind: AirqrConstants.kindDocument,
          name: 'big.txt',
          mime: 'text/plain',
          content: 'x' * (AirqrConstants.hardCapBytes + 1),
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });
  });

  group('name sanitising', () {
    test('strips path separators so a sender cannot suggest a path', () {
      final payload = AirqrPayload.build(
        kind: AirqrConstants.kindDocument,
        name: '../../etc/passwd',
        mime: 'text/plain',
        content: 'hello',
      );
      expect(payload.name, isNot(contains('/')));
      expect(payload.name, isNot(contains('..')));
    });

    test('strips backslashes and control characters', () {
      final payload = AirqrPayload.build(
        kind: AirqrConstants.kindDocument,
        name: 'C:\\Windows\\evil\u0000.txt',
        mime: 'text/plain',
        content: 'hello',
      );
      expect(payload.name, isNot(contains('\\')));
      expect(payload.name, isNot(contains('\u0000')));
    });

    test('falls back to a safe default when the name is empty', () {
      final payload = AirqrPayload.build(
        kind: AirqrConstants.kindDocument,
        name: '   ',
        mime: 'text/plain',
        content: 'hello',
      );
      expect(payload.name, 'received.txt');
    });

    test('caps a very long name', () {
      final payload = AirqrPayload.build(
        kind: AirqrConstants.kindDocument,
        name: 'a' * 1000,
        mime: 'text/plain',
        content: 'hello',
      );
      expect(payload.name.length, AirqrConstants.maxNameLength);
    });
  });

  group('validateAndParse treats every envelope as hostile', () {
    String envelope(Map<String, Object?> overrides) {
      final base = <String, Object?>{
        AirqrConstants.envelopeApp: AirqrConstants.appId,
        AirqrConstants.envelopeVersion: AirqrConstants.payloadVersion,
        AirqrConstants.envelopeKind: AirqrConstants.kindDocument,
        AirqrConstants.envelopeName: 'notes.txt',
        AirqrConstants.envelopeMime: 'text/plain',
        AirqrConstants.envelopeContent: 'hello',
      }..addAll(overrides);
      return jsonEncode(base);
    }

    test('round trips a good envelope', () {
      final parsed = AirqrPayload.validateAndParse(envelope({}));
      expect(parsed.content, 'hello');
      expect(parsed.name, 'notes.txt');
    });

    test('rejects text that is not JSON', () {
      expect(
        () => AirqrPayload.validateAndParse('not json at all'),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('rejects JSON that is not an object', () {
      expect(
        () => AirqrPayload.validateAndParse('[1,2,3]'),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('rejects a payload from another app', () {
      expect(
        () => AirqrPayload.validateAndParse(
          envelope({AirqrConstants.envelopeApp: 'some_other_app'}),
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('rejects a newer payload version', () {
      expect(
        () => AirqrPayload.validateAndParse(
          envelope({
            AirqrConstants.envelopeVersion: AirqrConstants.payloadVersion + 1,
          }),
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('rejects an unknown kind', () {
      expect(
        () => AirqrPayload.validateAndParse(
          envelope({AirqrConstants.envelopeKind: 'executable'}),
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('rejects missing or non-string content', () {
      expect(
        () => AirqrPayload.validateAndParse(
          envelope({AirqrConstants.envelopeContent: 42}),
        ),
        throwsA(isA<AirqrPayloadException>()),
      );
    });

    test('sanitises a hostile name on the way in', () {
      final parsed = AirqrPayload.validateAndParse(
        envelope({AirqrConstants.envelopeName: '../../../secret.txt'}),
      );
      expect(parsed.name, isNot(contains('/')));
    });

    test('falls back to text/plain when the MIME type is missing', () {
      final parsed = AirqrPayload.validateAndParse(
        envelope({AirqrConstants.envelopeMime: null}),
      );
      expect(parsed.mime, 'text/plain');
    });
  });
}
