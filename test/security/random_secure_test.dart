import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/sync_constants.dart';
import 'package:text_data/sync/sync_crypto.dart';

/// Guards security-rules: "Use Random.secure() for all security-relevant
/// randomness." A regression to a plain `Random()` (predictable) would silently
/// weaken the pairing code and GCM nonces, so this test locks both the source
/// shape and the runtime invariants in place.
void main() {
  group('sync_crypto source', () {
    final source = File('lib/sync/sync_crypto.dart').readAsStringSync();

    test('uses Random.secure()', () {
      expect(
        source.contains('Random.secure()'),
        isTrue,
        reason: 'sync crypto must seed from Random.secure() (security-rules).',
      );
    });

    test('has no predictable Random() constructor', () {
      // A bare `Random(` (with or without a seed) is a non-secure PRNG. Only
      // `Random.secure()` is allowed here, so scan the source with the secure
      // spelling removed first.
      final withoutSecure = source.replaceAll('Random.secure()', '');
      final bareRandom = RegExp(r'\bRandom\s*\(');
      expect(
        bareRandom.hasMatch(withoutSecure),
        isFalse,
        reason: 'Only Random.secure() may be used in sync crypto.',
      );
    });
  });

  group('pairing code entropy invariants', () {
    test('alphabet excludes the look-alike characters 0 O 1 I L', () {
      for (final ch in ['0', 'O', '1', 'I', 'L']) {
        expect(
          SyncConstants.codeAlphabet.contains(ch),
          isFalse,
          reason: '$ch must not be in the code alphabet.',
        );
      }
    });

    test('code carries at least ~320 bits of entropy', () {
      // Each character carries log2(alphabetSize) bits.
      final bitsPerChar =
          math.log(SyncConstants.codeAlphabet.length) / math.log(2);
      final totalBits = bitsPerChar * SyncConstants.codeLength;
      expect(
        totalBits,
        greaterThanOrEqualTo(310.0),
        reason: 'The pairing code must keep ~320 bits of entropy '
            '(security-rules §P2P).',
      );
    });

    test('generated codes are unique across many draws', () {
      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        final code = SyncCrypto.generatePairingCode();
        expect(seen.add(code), isTrue, reason: 'a code repeated: $code');
      }
    });
  });
}
