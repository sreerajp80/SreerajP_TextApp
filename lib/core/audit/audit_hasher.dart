/// Pure-Dart SHA-256 chain hashing for the audit log (Feature 8).
///
/// Stateless and platform-free, so it is fully unit-testable. Uses
/// `package:crypto` (already a dependency for [ContentFingerprint] and
/// [AppLockHasher]).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:sreerajp_textapp/core/audit/audit_constants.dart';

/// Computes the tamper-evident hash for one audit-log entry.
///
/// The hash is SHA-256 over the UTF-8 bytes of:
/// ```
/// previousHash|eventType|timestamp|beforeHash|afterHash|detail
/// ```
/// Null fields are represented as the empty string. The `|` separator prevents
/// field-boundary shifting ('a|b' can never collide with 'ab|').
class AuditHasher {
  const AuditHasher._();

  /// Computes the `entry_hash` for one audit row.
  ///
  /// [previousHash] is the `entry_hash` of the preceding row, or
  /// [AuditConstants.genesisHash] for the first entry.
  static String computeEntryHash({
    required String previousHash,
    required String eventType,
    required int timestamp,
    String? beforeHash,
    String? afterHash,
    String? detail,
  }) {
    const sep = AuditConstants.hashSeparator;
    final preimage = StringBuffer()
      ..write(previousHash)
      ..write(sep)
      ..write(eventType)
      ..write(sep)
      ..write(timestamp)
      ..write(sep)
      ..write(beforeHash ?? '')
      ..write(sep)
      ..write(afterHash ?? '')
      ..write(sep)
      ..write(detail ?? '');

    final bytes = utf8.encode(preimage.toString());
    return sha256.convert(bytes).toString();
  }

  /// Recomputes and checks the `entry_hash` of a single row against its stored
  /// value. Returns `true` when they match.
  static bool verifyEntry({
    required String storedEntryHash,
    required String previousHash,
    required String eventType,
    required int timestamp,
    String? beforeHash,
    String? afterHash,
    String? detail,
  }) {
    final expected = computeEntryHash(
      previousHash: previousHash,
      eventType: eventType,
      timestamp: timestamp,
      beforeHash: beforeHash,
      afterHash: afterHash,
      detail: detail,
    );
    return expected == storedEntryHash;
  }
}
