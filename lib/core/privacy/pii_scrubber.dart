import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:sreerajp_textapp/core/privacy/pii_detection.dart';
import 'package:sreerajp_textapp/core/privacy/pii_mask_mode.dart';
import 'package:sreerajp_textapp/core/privacy/pii_type.dart';

/// The result of a scrubbing operation on text.
class PiiScrubResult {
  final String originalText;
  final String scrubbedText;
  final PiiMaskMode mode;
  final int scrubbedCount;
  final Map<String, String> replacementMap;

  const PiiScrubResult({
    required this.originalText,
    required this.scrubbedText,
    required this.mode,
    required this.scrubbedCount,
    required this.replacementMap,
  });
}

/// Pure Dart transformation engine for masking sensitive PII tokens.
class PiiScrubber {
  static const String _defaultSalt = 'textdata_privacy_shield_salt';

  const PiiScrubber();

  /// Applies the specified [mode] to all selected matches in [scanResult].
  PiiScrubResult scrub(
    String text,
    PiiScanResult scanResult, {
    PiiMaskMode mode = PiiMaskMode.redact,
    String salt = _defaultSalt,
  }) {
    return scrubMatches(
      text,
      scanResult.matches.where((m) => m.isSelected).toList(),
      mode: mode,
      salt: salt,
    );
  }

  /// Applies [mode] to the given list of [selectedMatches].
  PiiScrubResult scrubMatches(
    String text,
    List<PiiMatch> selectedMatches, {
    PiiMaskMode mode = PiiMaskMode.redact,
    String salt = _defaultSalt,
  }) {
    if (text.isEmpty || selectedMatches.isEmpty) {
      return PiiScrubResult(
        originalText: text,
        scrubbedText: text,
        mode: mode,
        scrubbedCount: 0,
        replacementMap: const {},
      );
    }

    // Sort matches strictly by start index
    final sorted = List<PiiMatch>.from(selectedMatches)
      ..sort((a, b) => a.start.compareTo(b.start));

    final replacementMap = <String, String>{};
    final anonCounters = <PiiType, int>{};

    // First pass: generate consistent replacements for each unique raw value
    for (final match in sorted) {
      if (!replacementMap.containsKey(match.rawValue)) {
        final replacement = _createReplacement(
          match.type,
          match.rawValue,
          mode,
          salt,
          anonCounters,
        );
        replacementMap[match.rawValue] = replacement;
      }
    }

    // Second pass: construct scrubbed buffer
    final buffer = StringBuffer();
    int currentOffset = 0;
    int appliedCount = 0;

    for (final match in sorted) {
      if (match.start < currentOffset) {
        // Skip overlapping matches if any slipped through
        continue;
      }

      // Append un-modified text before this match
      buffer.write(text.substring(currentOffset, match.start));

      // Append replacement
      final replacement = replacementMap[match.rawValue]!;
      buffer.write(replacement);

      currentOffset = match.end;
      appliedCount++;
    }

    // Append remaining tail text
    if (currentOffset < text.length) {
      buffer.write(text.substring(currentOffset));
    }

    return PiiScrubResult(
      originalText: text,
      scrubbedText: buffer.toString(),
      mode: mode,
      scrubbedCount: appliedCount,
      replacementMap: replacementMap,
    );
  }

  /// Generates a masked string for a specific token according to [mode].
  static String _createReplacement(
    PiiType type,
    String rawValue,
    PiiMaskMode mode,
    String salt,
    Map<PiiType, int> anonCounters,
  ) {
    switch (mode) {
      case PiiMaskMode.redact:
        return _redactLabel(type);
      case PiiMaskMode.hash:
        return _hashValue(rawValue, salt);
      case PiiMaskMode.anonymize:
        return _anonymizeValue(type, anonCounters);
    }
  }

  static String _redactLabel(PiiType type) {
    switch (type) {
      case PiiType.email:
        return '[REDACTED: EMAIL]';
      case PiiType.phone:
        return '[REDACTED: PHONE]';
      case PiiType.creditCard:
        return '[REDACTED: CREDIT_CARD]';
      case PiiType.ipAddress:
        return '[REDACTED: IP_ADDRESS]';
      case PiiType.jwtToken:
        return '[REDACTED: JWT_TOKEN]';
      case PiiType.awsKey:
        return '[REDACTED: AWS_KEY]';
      case PiiType.privateKey:
        return '[REDACTED: PRIVATE_KEY]';
      case PiiType.apiKeySecret:
        return '[REDACTED: API_SECRET]';
    }
  }

  static String _hashValue(String rawValue, String salt) {
    final bytes = utf8.encode('$salt:$rawValue');
    final digest = sha256.convert(bytes);
    final shortHash = digest.toString().substring(0, 10);
    return '[HASH:$shortHash]';
  }

  static String _anonymizeValue(PiiType type, Map<PiiType, int> anonCounters) {
    final nextId = (anonCounters[type] ?? 0) + 1;
    anonCounters[type] = nextId;
    final paddedId = nextId.toString().padLeft(2, '0');

    switch (type) {
      case PiiType.email:
        return 'user_$paddedId@anonymized.local';
      case PiiType.phone:
        return '+1-555-01$paddedId';
      case PiiType.creditCard:
        return '4111-1111-1111-00$paddedId';
      case PiiType.ipAddress:
        return '10.0.0.$nextId';
      case PiiType.jwtToken:
        return 'eyJhbGciOiJub25lIn0.eyJhbm9uIjoi${paddedId}In0.anonymized_signature';
      case PiiType.awsKey:
        return 'AKIAANONYMIZED$paddedId';
      case PiiType.privateKey:
        return '-----BEGIN RSA PRIVATE KEY-----\nANONYMIZED_KEY_BLOCK_$paddedId\n-----END RSA PRIVATE KEY-----';
      case PiiType.apiKeySecret:
        return 'secret_token_anon_$paddedId';
    }
  }
}
