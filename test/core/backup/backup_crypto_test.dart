import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/backup/backup_constants.dart';
import 'package:sreerajp_textapp/core/backup/backup_crypto.dart';

void main() {
  group('BackupCrypto', () {
    test('deriveKey produces a 32-byte key from password and salt', () {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final key1 = BackupCrypto.deriveKey(
        'mySecretPassword123',
        salt,
        iterations: 1000,
      );
      final key2 = BackupCrypto.deriveKey(
        'mySecretPassword123',
        salt,
        iterations: 1000,
      );
      final key3 = BackupCrypto.deriveKey(
        'differentPassword',
        salt,
        iterations: 1000,
      );

      expect(key1.length, equals(32));
      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
    });

    test('encryptArchive and decryptArchive roundtrip with valid password', () {
      final original = utf8.encode(
        'Hello, this is a secret TextData backup payload!',
      );
      const password = 'StrongPassword!2026';

      final encrypted = BackupCrypto.encryptArchive(
        Uint8List.fromList(original),
        password,
      );

      expect(encrypted.length, greaterThan(original.length));
      expect(encrypted.sublist(0, 7), equals(BackupConstants.magicBytes));

      final decrypted = BackupCrypto.decryptArchive(encrypted, password);
      expect(
        utf8.decode(decrypted),
        equals('Hello, this is a secret TextData backup payload!'),
      );
    });

    test(
      'encryptArchive produces different ciphertext and salt on each run',
      () {
        final payload = Uint8List.fromList(utf8.encode('Same content'));
        const password = 'TestPassword123';

        final enc1 = BackupCrypto.encryptArchive(payload, password);
        final enc2 = BackupCrypto.encryptArchive(payload, password);

        // Both decrypt to the same content
        expect(BackupCrypto.decryptArchive(enc1, password), equals(payload));
        expect(BackupCrypto.decryptArchive(enc2, password), equals(payload));

        // But byte representations differ due to fresh random salt and nonce
        expect(enc1, isNot(equals(enc2)));
      },
    );

    test('decryptArchive with wrong password throws BackupCryptoException', () {
      final payload = Uint8List.fromList(utf8.encode('Confidential Data'));
      final encrypted = BackupCrypto.encryptArchive(
        payload,
        'CorrectPassword123',
      );

      expect(
        () => BackupCrypto.decryptArchive(encrypted, 'WrongPassword456'),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.message,
            'message',
            contains('Invalid password or corrupted backup archive'),
          ),
        ),
      );
    });

    test('decryptArchive on tampered archive throws BackupCryptoException', () {
      final payload = Uint8List.fromList(utf8.encode('Sensitive Note'));
      final encrypted = BackupCrypto.encryptArchive(payload, 'Password123');

      // Tamper with one byte in the ciphertext body
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 5] ^= 0xFF;

      expect(
        () => BackupCrypto.decryptArchive(tampered, 'Password123'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test(
      'decryptArchive on invalid magic header throws BackupCryptoException',
      () {
        final payload = Uint8List.fromList(utf8.encode('Test'));
        final encrypted = BackupCrypto.encryptArchive(payload, 'Password123');

        final badHeader = Uint8List.fromList(encrypted);
        badHeader[0] = 0x00; // corrupt first magic byte

        expect(
          () => BackupCrypto.decryptArchive(badHeader, 'Password123'),
          throwsA(
            isA<BackupCryptoException>().having(
              (e) => e.message,
              'message',
              contains('Not a valid TextData'),
            ),
          ),
        );
      },
    );

    test(
      'decryptArchive on truncated archive throws BackupCryptoException',
      () {
        final truncated = Uint8List.fromList([1, 2, 3]);
        expect(
          () => BackupCrypto.decryptArchive(truncated, 'Password123'),
          throwsA(
            isA<BackupCryptoException>().having(
              (e) => e.message,
              'message',
              contains('too small or truncated'),
            ),
          ),
        );
      },
    );

    test('encryptArchive with password shorter than 6 characters throws', () {
      final payload = Uint8List.fromList([1, 2, 3]);
      expect(
        () => BackupCrypto.encryptArchive(payload, '12345'),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.message,
            'message',
            contains('at least 6 characters'),
          ),
        ),
      );
    });
  });
}
