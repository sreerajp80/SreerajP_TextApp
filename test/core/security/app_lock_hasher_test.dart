import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/security/app_lock_hasher.dart';
import 'package:text_data/sync/sync_constants.dart';

void main() {
  group('hash / verify', () {
    test('a hash verifies against its own secret', () {
      final stored = AppLockHasher.hash('1234');
      expect(AppLockHasher.verify('1234', stored), isTrue);
    });

    test('a wrong secret does not verify', () {
      final stored = AppLockHasher.hash('1234');
      expect(AppLockHasher.verify('9999', stored), isFalse);
    });

    test('the stored form never contains the plaintext', () {
      final stored = AppLockHasher.hash('secretpin');
      expect(stored.contains('secretpin'), isFalse);
    });

    test('the same secret hashes differently each time (random salt)', () {
      final a = AppLockHasher.hash('1234');
      final b = AppLockHasher.hash('1234');
      expect(a, isNot(b));
      // ...but both still verify.
      expect(AppLockHasher.verify('1234', a), isTrue);
      expect(AppLockHasher.verify('1234', b), isTrue);
    });

    test('a malformed stored value does not verify and does not throw', () {
      expect(AppLockHasher.verify('1234', 'garbage'), isFalse);
      expect(AppLockHasher.verify('1234', ''), isFalse);
      expect(AppLockHasher.verify('1234', 'only:onepart:extra'), isFalse);
    });
  });

  group('recovery code', () {
    test('has the requested length and uses the safe alphabet', () {
      final code = AppLockHasher.generateRecoveryCode();
      expect(code.length, AppLockHasher.recoveryCodeLength);
      for (final ch in code.split('')) {
        expect(SyncConstants.codeAlphabet.contains(ch), isTrue);
      }
    });

    test('excludes look-alike characters', () {
      for (var i = 0; i < 50; i++) {
        final code = AppLockHasher.generateRecoveryCode(length: 20);
        for (final bad in ['0', 'O', '1', 'I', 'L']) {
          expect(code.contains(bad), isFalse);
        }
      }
    });

    test('two codes differ', () {
      expect(
        AppLockHasher.generateRecoveryCode(),
        isNot(AppLockHasher.generateRecoveryCode()),
      );
    });

    test('normalize reverses formatting (upper-case, drop dashes/spaces)', () {
      final code = AppLockHasher.generateRecoveryCode();
      final formatted = AppLockHasher.formatRecoveryCode(code).toLowerCase();
      expect(AppLockHasher.normalizeRecoveryCode(formatted), code);
    });

    test('a hashed recovery code round-trips through verify', () {
      final code = AppLockHasher.generateRecoveryCode();
      final stored = AppLockHasher.hash(code);
      expect(AppLockHasher.verify(code, stored), isTrue);
      expect(AppLockHasher.verify('WRONGCODE', stored), isFalse);
    });
  });
}
