import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/sync/file_transfer_payload.dart';
import 'package:sreerajp_textapp/sync/sync_constants.dart';

void main() {
  group('FileTransferPayload', () {
    test('build and validateAndParse round-trip succeeds', () {
      final payload = FileTransferPayload.build(
        rawFileName: 'budget_2026.csv',
        mimeType: 'text/csv',
        fileContent: 'Quarter,Amount\nQ1,50000\nQ2,65000\n',
        fileEncoding: 'utf-8',
      );

      final wireJson = payload.toWireJson();
      final parsed = FileTransferPayload.validateAndParse(wireJson);

      expect(parsed.fileName, equals('budget_2026.csv'));
      expect(parsed.mimeType, equals('text/csv'));
      expect(
        parsed.fileContent,
        equals('Quarter,Amount\nQ1,50000\nQ2,65000\n'),
      );
      expect(parsed.fileEncoding, equals('utf-8'));
      expect(parsed.fileSizeBytes, equals(payload.fileSizeBytes));
    });

    test('sanitizes unsafe file names', () {
      final payload = FileTransferPayload.build(
        rawFileName: '../../sensitive/config.json',
        mimeType: 'application/json',
        fileContent: '{"key": "value"}',
      );

      expect(payload.fileName.contains('..'), isFalse);
      expect(payload.fileName.contains('/'), isFalse);
    });

    test('throws when payload has incorrect app id', () {
      const invalidJson =
          '''
      {
        "${SyncConstants.keyApp}": "other_app",
        "${SyncConstants.keyPayloadVersion}": 1,
        "${SyncConstants.keyPayloadType}": "${SyncConstants.payloadTypeFileTransfer}",
        "${SyncConstants.keyFileName}": "test.txt",
        "${SyncConstants.keyFileContent}": "hello"
      }
      ''';

      expect(
        () => FileTransferPayload.validateAndParse(invalidJson),
        throwsA(isA<FileTransferException>()),
      );
    });

    test('throws when payload has wrong type', () {
      const invalidJson =
          '''
      {
        "${SyncConstants.keyApp}": "${SyncConstants.appId}",
        "${SyncConstants.keyPayloadVersion}": 1,
        "${SyncConstants.keyPayloadType}": "metadata",
        "${SyncConstants.keyFileName}": "test.txt",
        "${SyncConstants.keyFileContent}": "hello"
      }
      ''';

      expect(
        () => FileTransferPayload.validateAndParse(invalidJson),
        throwsA(isA<FileTransferException>()),
      );
    });

    test('throws when payload JSON is malformed', () {
      expect(
        () => FileTransferPayload.validateAndParse('not-json'),
        throwsA(isA<FileTransferException>()),
      );
    });
  });
}
