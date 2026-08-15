/// Audit certificate export — builds and signs a JSON document (Feature 8).
///
/// The certificate contains the full chain in insertion order plus a trailing
/// HMAC-SHA256 computed over the entries JSON using a device-specific key from
/// `SecureStore`. This lets a recipient with the same device install verify the
/// export was not modified after it left the app.
///
/// Nothing in this file logs entries, hashes, or the signing key.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:text_data/core/audit/audit_service.dart';
import 'package:text_data/core/storage/secure_store.dart';
import 'package:text_data/sync/sync_crypto.dart';

/// Builds the exportable audit certificate as a JSON string.
class AuditExport {
  const AuditExport._();

  /// The key in `SecureStore` under which the HMAC signing key is stored.
  /// Registered in [SecureStoreKeys.all] in `app_constants.dart`.
  static const String signingKeyStorageKey = 'audit_export_key';

  /// Signing key length in bytes (256 bits).
  static const int signingKeyLength = 32;

  /// Builds the certificate JSON.
  ///
  /// [service] provides the entries. [secureStore] provides (or generates) the
  /// HMAC signing key. [appName] and [appVersion] are included for provenance.
  static Future<String> buildCertificate({
    required AuditService service,
    required SecureStore secureStore,
    required String appName,
    required String appVersion,
  }) async {
    // 1. Collect all entries in chain order.
    final entries = await service.getEntriesForExport();
    final entriesJson = entries.map((e) => e.toJson()).toList();

    // 2. Verify the chain so the certificate includes the status.
    final verification = await service.verifyChain();

    // 3. Get or generate the signing key.
    final signingKey = await _getOrCreateSigningKey(secureStore);

    // 4. Build the entries JSON string for HMAC.
    final entriesString = jsonEncode(entriesJson);

    // 5. Compute HMAC-SHA256 over the entries.
    final hmacValue = _computeHmac(signingKey, entriesString);

    // 6. Build the certificate envelope.
    final certificate = {
      'version': 1,
      'appName': appName,
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'chainStatus': verification.status.name,
      'totalEntries': entries.length,
      if (verification.isCorrupted)
        'corruptedAtEntry': verification.corruptedEntryIndex,
      'entries': entriesJson,
      'hmac': hmacValue,
    };

    // Pretty-print for readability.
    return const JsonEncoder.withIndent('  ').convert(certificate);
  }

  /// Verifies that a certificate JSON was signed with the key on this device.
  ///
  /// Returns `true` if the HMAC matches, `false` otherwise. Returns `false`
  /// if the certificate is malformed or the key is missing.
  static Future<bool> verifyCertificate({
    required String certificateJson,
    required SecureStore secureStore,
  }) async {
    try {
      final cert = jsonDecode(certificateJson) as Map<String, dynamic>;
      final storedHmac = cert['hmac'] as String?;
      if (storedHmac == null) return false;

      final entriesJson = cert['entries'];
      if (entriesJson == null) return false;

      final signingKey = await secureStore.read(signingKeyStorageKey);
      if (signingKey == null) return false;

      final entriesString = jsonEncode(entriesJson);
      final computed = _computeHmac(signingKey, entriesString);
      return computed == storedHmac;
    } catch (_) {
      return false;
    }
  }

  /// Returns the signing key from secure storage, or generates and stores one
  /// if it does not exist yet.
  static Future<String> _getOrCreateSigningKey(SecureStore secureStore) async {
    final existing = await secureStore.read(signingKeyStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Generate a fresh 256-bit key using Random.secure().
    final keyBytes = SyncCrypto.randomBytes(signingKeyLength);
    final keyHex = keyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await secureStore.write(signingKeyStorageKey, keyHex);
    return keyHex;
  }

  /// HMAC-SHA256 of [data] using [key] (hex string).
  static String _computeHmac(String keyHex, String data) {
    final keyBytes = _hexToBytes(keyHex);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(utf8.encode(data));
    return digest.toString();
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
