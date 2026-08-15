import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/diff/diff_payload.dart';

void main() {
  group('DiffSessionPayload serialization tests', () {
    test('serializes and deserializes payload correctly', () {
      final payload = DiffSessionPayload.build(
        action: DiffPayloadAction.offer,
        sessionId: 'test_session_123',
        fileName: 'notes.md',
        mimeType: 'text/markdown',
        content: '# Hello World\nDelta sync is working!',
        hunkId: 'hunk_1',
        resolution: 'acceptLocal',
      );

      final jsonString = payload.toWireJson();
      final parsed = DiffSessionPayload.validateAndParse(jsonString);

      expect(parsed.action, DiffPayloadAction.offer);
      expect(parsed.sessionId, 'test_session_123');
      expect(parsed.fileName, 'notes.md');
      expect(parsed.mimeType, 'text/markdown');
      expect(parsed.content, '# Hello World\nDelta sync is working!');
      expect(parsed.hunkId, 'hunk_1');
      expect(parsed.resolution, 'acceptLocal');
    });

    test('sanitizes filename against path traversal', () {
      final payload = DiffSessionPayload.build(
        action: DiffPayloadAction.deltaUpdate,
        sessionId: 'session_1',
        fileName: '../../../../etc/passwd',
        content: 'content',
      );

      expect(payload.fileName.contains('..'), isFalse);
      expect(payload.fileName.contains('/'), isFalse);
    });

    test('rejects malformed or invalid json', () {
      expect(
        () => DiffSessionPayload.validateAndParse('not a json'),
        throwsA(isA<DiffPayloadException>()),
      );

      expect(
        () => DiffSessionPayload.validateAndParse('{"app":"wrong_app"}'),
        throwsA(isA<DiffPayloadException>()),
      );
    });
  });
}
