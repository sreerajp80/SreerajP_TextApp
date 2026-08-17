import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/security/biometric_service.dart';
import 'package:sreerajp_textapp/core/storage/secure_store.dart';
import 'package:sreerajp_textapp/core/vault/vault_constants.dart';
import 'package:sreerajp_textapp/core/vault/vault_crypto.dart';
import 'package:sreerajp_textapp/core/vault/vault_models.dart';
import 'package:sreerajp_textapp/core/vault/vault_service.dart';

class FakeBiometricService implements BiometricService {
  bool available;
  BiometricResult result;

  FakeBiometricService({
    this.available = true,
    this.result = BiometricResult.success,
  });

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate(String reason) async => result;
}

void main() {
  group('VaultCrypto', () {
    final testKey = VaultCrypto.generateMasterKey();

    test('generateMasterKey creates 32-byte AES-256 key', () {
      expect(testKey.length, equals(VaultConstants.keyLengthBytes));
    });

    test(
      'encryptVaultFile and decryptVaultFile round-trip preserves all payload data',
      () {
        final payload = VaultPayload(
          originalFileName: 'confidential.csv',
          mimeType: 'text/csv',
          encoding: 'utf-8',
          content: 'id,name,salary\n1,Alice,150000\n2,Bob,120000\n',
          createdAt: DateTime.utc(2026, 8, 15, 12, 0, 0),
        );

        final encryptedBytes = VaultCrypto.encryptVaultFile(payload, testKey);

        expect(VaultCrypto.hasVaultMagic(encryptedBytes), isTrue);
        expect(encryptedBytes.length, greaterThan(VaultCrypto.headerLength));

        // Ensure ciphertext has no plaintext leak
        final rawUtf8 = utf8.decode(encryptedBytes, allowMalformed: true);
        expect(rawUtf8.contains('Alice'), isFalse);
        expect(rawUtf8.contains('salary'), isFalse);

        final decrypted = VaultCrypto.decryptVaultFile(encryptedBytes, testKey);

        expect(decrypted.originalFileName, equals('confidential.csv'));
        expect(decrypted.mimeType, equals('text/csv'));
        expect(decrypted.encoding, equals('utf-8'));
        expect(
          decrypted.content,
          equals('id,name,salary\n1,Alice,150000\n2,Bob,120000\n'),
        );
        expect(
          decrypted.createdAt.toUtc(),
          equals(DateTime.utc(2026, 8, 15, 12, 0, 0)),
        );
      },
    );

    test('decryptVaultFile throws on invalid magic header', () {
      final payload = VaultPayload(
        originalFileName: 'doc.txt',
        mimeType: 'text/plain',
        encoding: 'utf-8',
        content: 'Hello World',
        createdAt: DateTime.now(),
      );

      final bytes = VaultCrypto.encryptVaultFile(payload, testKey);
      bytes[0] = 0x00; // corrupt magic byte

      expect(
        () => VaultCrypto.decryptVaultFile(bytes, testKey),
        throwsA(isA<VaultCryptoException>()),
      );
    });

    test('decryptVaultFile throws on truncated byte array', () {
      final truncatedBytes = Uint8List(10);
      expect(
        () => VaultCrypto.decryptVaultFile(truncatedBytes, testKey),
        throwsA(isA<VaultCryptoException>()),
      );
    });

    test('decryptVaultFile throws on wrong key', () {
      final payload = VaultPayload(
        originalFileName: 'doc.txt',
        mimeType: 'text/plain',
        encoding: 'utf-8',
        content: 'Secret',
        createdAt: DateTime.now(),
      );

      final bytes = VaultCrypto.encryptVaultFile(payload, testKey);
      final wrongKey = VaultCrypto.generateMasterKey();

      expect(
        () => VaultCrypto.decryptVaultFile(bytes, wrongKey),
        throwsA(isA<VaultCryptoException>()),
      );
    });

    test('decryptVaultFile throws on tampered ciphertext', () {
      final payload = VaultPayload(
        originalFileName: 'doc.txt',
        mimeType: 'text/plain',
        encoding: 'utf-8',
        content: 'Secret',
        createdAt: DateTime.now(),
      );

      final bytes = VaultCrypto.encryptVaultFile(payload, testKey);
      bytes[bytes.length - 1] ^= 0xFF; // tamper with ciphertext/tag

      expect(
        () => VaultCrypto.decryptVaultFile(bytes, testKey),
        throwsA(isA<VaultCryptoException>()),
      );
    });
  });

  group('VaultService', () {
    late InMemorySecureStore secureStore;
    late FakeBiometricService fakeBio;
    late VaultService vaultService;

    setUp(() {
      secureStore = InMemorySecureStore();
      fakeBio = FakeBiometricService();
      vaultService = VaultService(
        secureStore: secureStore,
        biometrics: fakeBio,
      );
    });

    test(
      'lockDocument and unlockDocument workflow with biometric success',
      () async {
        final payload = VaultPayload(
          originalFileName: 'finance.json',
          mimeType: 'application/json',
          encoding: 'utf-8',
          content: '{"budget": 50000}',
          createdAt: DateTime.now(),
        );

        final lockedBytes = await vaultService.lockDocument(payload: payload);
        expect(VaultCrypto.hasVaultMagic(lockedBytes), isTrue);

        final unlockedPayload = await vaultService.unlockDocument(
          fileBytes: lockedBytes,
        );
        expect(unlockedPayload.originalFileName, equals('finance.json'));
        expect(unlockedPayload.content, equals('{"budget": 50000}'));
      },
    );

    test('lockDocument fails if biometric auth is rejected', () async {
      fakeBio.result = BiometricResult.failed;
      final payload = VaultPayload(
        originalFileName: 'finance.json',
        mimeType: 'application/json',
        encoding: 'utf-8',
        content: '{"budget": 50000}',
        createdAt: DateTime.now(),
      );

      expect(
        () => vaultService.lockDocument(payload: payload),
        throwsA(isA<VaultCryptoException>()),
      );
    });

    test('unlockDocument fails if biometric auth is rejected', () async {
      final payload = VaultPayload(
        originalFileName: 'finance.json',
        mimeType: 'application/json',
        encoding: 'utf-8',
        content: '{"budget": 50000}',
        createdAt: DateTime.now(),
      );

      final lockedBytes = await vaultService.lockDocument(payload: payload);

      fakeBio.result = BiometricResult.failed;
      expect(
        () => vaultService.unlockDocument(fileBytes: lockedBytes),
        throwsA(isA<VaultCryptoException>()),
      );
    });
  });
}
