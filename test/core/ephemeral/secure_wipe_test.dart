import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/ephemeral/secure_wipe.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('secure_wipe_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  File fileWith(String name, List<int> bytes) {
    final file = File('${tempDir.path}/$name');
    file.writeAsBytesSync(bytes);
    return file;
  }

  group('wipeFile', () {
    test('deletes the file', () async {
      final file = fileWith('secret.txt', 'top secret notes'.codeUnits);
      expect(await SecureWipe.wipeFile(file), isTrue);
      expect(await file.exists(), isFalse);
    });

    test('the overwrite pass replaces every byte with 0x00', () async {
      const secret = 'top secret notes';
      final file = fileWith('secret.txt', secret.codeUnits);

      await SecureWipe.overwriteWithZeros(file);

      final after = await file.readAsBytes();
      expect(after.length, secret.length, reason: 'length is preserved');
      expect(after, everyElement(0), reason: 'no original byte survives');
    });

    test('the overwrite leaves nothing of the original text', () async {
      final file = fileWith('secret.txt', 'PASSWORD=hunter2'.codeUnits);
      await SecureWipe.overwriteWithZeros(file);
      expect(
        String.fromCharCodes(await file.readAsBytes()),
        isNot(contains('hunter2')),
      );
    });

    test('an empty file is deleted without error', () async {
      final file = fileWith('empty.txt', const []);
      expect(await SecureWipe.wipeFile(file), isTrue);
      expect(await file.exists(), isFalse);
    });

    test('a missing file is a no-op, not a failure', () async {
      final file = File('${tempDir.path}/never-existed.txt');
      expect(await SecureWipe.wipeFile(file), isTrue);
    });

    test('a large file is wiped in slices without error', () async {
      final big = Uint8List(SecureWipe.chunkSize * 2 + 17);
      for (var i = 0; i < big.length; i++) {
        big[i] = 0xAB;
      }
      final file = fileWith('big.bin', big);
      expect(await SecureWipe.wipeFile(file), isTrue);
      expect(await file.exists(), isFalse);
    });

    test('a directory in place of a file does not throw', () async {
      final dir = Directory('${tempDir.path}/a-directory')..createSync();
      // Never throws, whatever it returns — a burn must keep going.
      await SecureWipe.wipeFile(File(dir.path));
      expect(true, isTrue);
    });
  });

  group('zeroBytes', () {
    test('overwrites a mutable buffer in place', () {
      final bytes = Uint8List.fromList([1, 2, 3, 250]);
      SecureWipe.zeroBytes(bytes);
      expect(bytes, everyElement(0));
    });

    test('null and empty buffers are safe', () {
      SecureWipe.zeroBytes(null);
      SecureWipe.zeroBytes(Uint8List(0));
      expect(true, isTrue);
    });
  });
}
