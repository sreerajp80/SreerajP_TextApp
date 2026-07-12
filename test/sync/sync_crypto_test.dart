import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/sync_constants.dart';
import 'package:text_data/sync/sync_crypto.dart';

void main() {
  group('pairing code', () {
    test('generated code is valid and the right length', () {
      final code = SyncCrypto.generatePairingCode();
      expect(code.length, SyncConstants.codeLength);
      expect(SyncCrypto.isValidCode(code), isTrue);
      for (final ch in code.split('')) {
        expect(SyncConstants.codeAlphabet.contains(ch), isTrue);
      }
    });

    test('two generated codes differ', () {
      expect(SyncCrypto.generatePairingCode(),
          isNot(SyncCrypto.generatePairingCode()));
    });

    test('normalize strips spaces/dashes and upper-cases', () {
      final code = SyncCrypto.generatePairingCode();
      final formatted = SyncCrypto.formatCode(code).toLowerCase();
      expect(SyncCrypto.normalizeCode(formatted), code);
    });

    test('a bad character makes a code invalid', () {
      // '0' is not in the alphabet.
      final bad = '0${SyncCrypto.generatePairingCode().substring(1)}';
      expect(SyncCrypto.isValidCode(bad), isFalse);
    });
  });

  group('wire crypto', () {
    test('round-trips a message', () {
      final salt = SyncCrypto.randomBytes(SyncConstants.saltLength);
      final key = SyncCrypto.deriveKey('SECRETCODE', salt);
      const message = 'hello {"a":1} 世界';
      final wire = SyncCrypto.encryptWire(key, message);
      expect(SyncCrypto.decryptWire(key, wire), message);
    });

    test('a wrong key fails the GCM tag and throws', () {
      final salt = SyncCrypto.randomBytes(SyncConstants.saltLength);
      final good = SyncCrypto.deriveKey('RIGHT', salt);
      final bad = SyncCrypto.deriveKey('WRONG', salt);
      final wire = SyncCrypto.encryptWire(good, 'secret payload');
      expect(() => SyncCrypto.decryptWire(bad, wire),
          throwsA(isA<SyncCryptoException>()));
    });

    test('a tampered ciphertext throws', () {
      final key = SyncCrypto.deriveKey('CODE', SyncCrypto.randomBytes(16));
      final wire = SyncCrypto.encryptWire(key, 'data');
      final raw = base64.decode(wire);
      raw[raw.length - 1] ^= 0xFF; // flip a tag byte
      final tampered = base64.encode(raw);
      expect(() => SyncCrypto.decryptWire(key, tampered),
          throwsA(isA<SyncCryptoException>()));
    });

    test('malformed wire throws', () {
      final key = SyncCrypto.deriveKey('CODE', SyncCrypto.randomBytes(16));
      expect(() => SyncCrypto.decryptWire(key, 'not base64!!'),
          throwsA(isA<SyncCryptoException>()));
      expect(() => SyncCrypto.decryptWire(key, base64.encode([1, 2, 3])),
          throwsA(isA<SyncCryptoException>()));
    });
  });

  group('QR URI', () {
    test('build then parse round-trips', () {
      final code = SyncCrypto.generatePairingCode();
      final uri = SyncCrypto.buildQrUri(
          QrPairing(host: '192.168.1.5', port: 45123, code: code));
      final parsed = SyncCrypto.parseQrUri(uri);
      expect(parsed.isOk, isTrue);
      expect(parsed.pairing!.host, '192.168.1.5');
      expect(parsed.pairing!.port, 45123);
      expect(parsed.pairing!.code, code);
    });

    test('rejects a foreign scheme', () {
      final parsed = SyncCrypto.parseQrUri('https://example.com/pair?c=x');
      expect(parsed.isOk, isFalse);
      expect(parsed.error, isNotNull);
    });

    test('rejects a malformed code', () {
      final uri =
          '${SyncConstants.qrScheme}://${SyncConstants.qrHost}?v=1&h=1.2.3.4&p=45000&c=SHORT';
      expect(SyncCrypto.parseQrUri(uri).isOk, isFalse);
    });

    test('rejects a bad port', () {
      final code = SyncCrypto.generatePairingCode();
      final uri =
          '${SyncConstants.qrScheme}://${SyncConstants.qrHost}?v=1&h=1.2.3.4&p=99999&c=$code';
      expect(SyncCrypto.parseQrUri(uri).isOk, isFalse);
    });

    test('rejects a wrong version', () {
      final code = SyncCrypto.generatePairingCode();
      final uri =
          '${SyncConstants.qrScheme}://${SyncConstants.qrHost}?v=999&h=1.2.3.4&p=45000&c=$code';
      expect(SyncCrypto.parseQrUri(uri).isOk, isFalse);
    });

    test('does not throw on random junk', () {
      expect(SyncCrypto.parseQrUri('::::not a uri::::').isOk, isFalse);
    });
  });

  group('SecretResealer', () {
    test('round-trips device-key -> session-key -> device-key', () {
      final deviceKey = SyncCrypto.randomBytes(32);
      final sessionKey = SyncCrypto.randomBytes(32);
      const secret = 'super-secret-token';

      // At rest under the device key.
      final atRest = SyncCrypto.encryptWire(deviceKey, secret);
      // Host re-seals under the session key for the wire.
      final onWire = SecretResealer.toSession(
        deviceKeyWire: atRest,
        deviceKey: deviceKey,
        sessionKey: sessionKey,
      );
      // The wire form must not decrypt under the device key.
      expect(() => SyncCrypto.decryptWire(deviceKey, onWire),
          throwsA(isA<SyncCryptoException>()));
      // Client re-encrypts under its own device key.
      final backAtRest = SecretResealer.toDevice(
        sessionKeyWire: onWire,
        sessionKey: sessionKey,
        deviceKey: deviceKey,
      );
      expect(SyncCrypto.decryptWire(deviceKey, backAtRest), secret);
    });
  });

  group('deriveKey', () {
    test('produces a 32-byte key', () {
      final key = SyncCrypto.deriveKey('CODE', Uint8List(16));
      expect(key.length, 32);
    });

    test('same code + salt -> same key; different salt -> different key', () {
      final salt = SyncCrypto.randomBytes(16);
      final a = SyncCrypto.deriveKey('CODE', salt);
      final b = SyncCrypto.deriveKey('CODE', salt);
      final c = SyncCrypto.deriveKey('CODE', SyncCrypto.randomBytes(16));
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
