import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(SafService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = SafService(channel);

  void handleWith(Future<Object?>? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('SafService error mapping', () {
    test('permission_denied maps to SafPermissionDenied', () {
      handleWith((_) async => throw PlatformException(code: 'permission_denied'));
      expect(
        () => service.readBytes('content://x'),
        throwsA(isA<SafPermissionDenied>()),
      );
    });

    test('uri_stale maps to SafUriStale', () {
      handleWith((_) async => throw PlatformException(code: 'uri_stale'));
      expect(
        () => service.readBytes('content://x'),
        throwsA(isA<SafUriStale>()),
      );
    });

    test('io_failure maps to SafIoFailure', () {
      handleWith((_) async => throw PlatformException(code: 'io_failure'));
      expect(
        () => service.writeBytes('content://x', Uint8List(0)),
        throwsA(isA<SafIoFailure>()),
      );
    });

    test('cancelled pick maps to SafCancelled', () {
      handleWith((call) async {
        if (call.method == 'pickFile') {
          throw PlatformException(code: 'cancelled');
        }
        return null;
      });
      expect(() => service.pickFile(), throwsA(isA<SafCancelled>()));
    });

    test('null pick result is treated as cancelled', () {
      handleWith((_) async => null);
      expect(() => service.pickFile(), throwsA(isA<SafCancelled>()));
    });

    test('unknown code maps to SafUnknownFailure', () {
      handleWith((_) async => throw PlatformException(code: 'weird'));
      expect(
        () => service.readBytes('content://x'),
        throwsA(isA<SafUnknownFailure>()),
      );
    });
  });

  group('SafService happy paths', () {
    test('pickFile returns a SafFile from the native map', () async {
      handleWith((call) async {
        expect(call.method, 'pickFile');
        return {
          'uri': 'content://doc/1',
          'displayName': 'notes.txt',
          'mimeType': 'text/plain',
          'size': 42,
        };
      });
      final file = await service.pickFile(mimeTypes: const ['text/plain']);
      expect(file.uri, 'content://doc/1');
      expect(file.displayName, 'notes.txt');
      expect(file.mimeType, 'text/plain');
      expect(file.size, 42);
    });

    test('isAccessible returns false instead of throwing on error', () async {
      handleWith((_) async => throw PlatformException(code: 'uri_stale'));
      expect(await service.isAccessible('content://gone'), isFalse);
    });

    test('persistedUris returns only string entries', () async {
      handleWith((_) async => ['content://a', 'content://b']);
      expect(await service.persistedUris(), ['content://a', 'content://b']);
    });

    test('missing plugin maps to SafUnknownFailure', () {
      handleWith((_) async => throw MissingPluginException());
      expect(
        () => service.readBytes('content://x'),
        throwsA(isA<SafUnknownFailure>()),
      );
    });
  });
}
