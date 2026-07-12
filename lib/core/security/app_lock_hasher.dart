import 'dart:convert';
import 'dart:typed_data';

import '../../sync/sync_constants.dart';
import '../../sync/sync_crypto.dart';

/// Salted hashing for the app-lock PIN and recovery code, plus recovery-code
/// generation. Pure and platform-free, so it is fully unit-testable (task 13.2).
///
/// Security (security-rules): the PIN and recovery code are **never** stored in
/// the clear. We keep only a salted PBKDF2-HMAC-SHA256 digest (the same slow KDF
/// the sync layer uses), so a stolen secure-storage entry does not reveal the
/// secret. The stored form is `base64(salt):base64(digest)`.
class AppLockHasher {
  AppLockHasher._();

  /// Salt length in bytes for a stored hash.
  static const int saltLength = 16;

  /// Default recovery-code length in characters (~59 bits over the 31-symbol
  /// alphabet — long enough to resist guessing, short enough to write down).
  static const int recoveryCodeLength = 12;

  /// Hashes [secret] under a fresh random salt. Returns the storable string.
  static String hash(String secret) {
    final salt = SyncCrypto.randomBytes(saltLength);
    final digest = SyncCrypto.deriveKey(secret, salt);
    return '${base64.encode(salt)}:${base64.encode(digest)}';
  }

  /// True if [secret] matches [stored] (produced by [hash]). Constant-time
  /// digest compare so a timing side-channel does not leak how many bytes match.
  static bool verify(String secret, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    Uint8List salt;
    Uint8List expected;
    try {
      salt = base64.decode(parts[0]);
      expected = base64.decode(parts[1]);
    } catch (_) {
      return false;
    }
    final actual = SyncCrypto.deriveKey(secret, salt);
    return _constantTimeEquals(actual, expected);
  }

  /// A fresh recovery code drawn uniformly (rejection-sampled to avoid modulo
  /// bias) from the look-alike-free alphabet, using Random.secure().
  static String generateRecoveryCode({int length = recoveryCodeLength}) {
    const alphabet = SyncConstants.codeAlphabet;
    final n = alphabet.length;
    final limit = 256 - (256 % n);
    final buf = StringBuffer();
    while (buf.length < length) {
      final b = SyncCrypto.randomBytes(1)[0];
      if (b >= limit) continue; // reject to keep the distribution flat
      buf.write(alphabet[b % n]);
    }
    return buf.toString();
  }

  /// Groups a recovery code for display only (e.g. `ABCD-EFGH-JKMN`).
  static String formatRecoveryCode(String code) {
    const group = 4;
    final parts = <String>[];
    for (var i = 0; i < code.length; i += group) {
      final end = i + group > code.length ? code.length : i + group;
      parts.add(code.substring(i, end));
    }
    return parts.join('-');
  }

  /// Cleans a typed recovery code: upper-case, drop spaces/dashes.
  static String normalizeRecoveryCode(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
