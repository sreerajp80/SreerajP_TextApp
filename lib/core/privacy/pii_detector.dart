import 'package:sreerajp_textapp/core/privacy/pii_detection.dart';
import 'package:sreerajp_textapp/core/privacy/pii_type.dart';

/// Pure offline detection engine for identifying sensitive Personally
/// Identifiable Information (PII), credentials, and secrets in text.
class PiiDetector {
  static final RegExp _emailRegex = RegExp(
    r'\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:(?:\+|00)\d{1,3}[-.\s]?)?(?:\(?\d{2,4}\)?[-.\s]?)?\d{3,4}[-.\s]?\d{3,4}(?:[-.\s]?\d{2,4})?',
  );

  static final RegExp _creditCardRegex = RegExp(
    r'\b(?:\d{4}[-\s]?){3}\d{1,7}\b|\b\d{13,19}\b',
  );

  static final RegExp _ipv4Regex = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\b',
  );

  static final RegExp _ipv6Regex = RegExp(
    r'\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b|\b(?:[0-9a-fA-F]{1,4}:){1,7}:[0-9a-fA-F]{1,4}\b',
  );

  static final RegExp _jwtRegex = RegExp(
    r'\beyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\b',
  );

  static final RegExp _awsKeyRegex = RegExp(
    r'\b(?:AKIA|ASIA|ABIA|ACCA)[0-9A-Z]{16}\b',
  );

  static final RegExp _privateKeyRegex = RegExp(
    r'-----BEGIN [A-Z0-9\s-]+PRIVATE KEY-----[\s\S]*?-----END [A-Z0-9\s-]+PRIVATE KEY-----',
  );

  static final RegExp _knownApiKeyTokens = RegExp(
    r'\b(?:ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36,}\b|\b(?:sk|pk)_(?:test|live)_[0-9a-zA-Z]{24,}\b|\bxox[baprs]-[0-9a-zA-Z]{10,}-[0-9a-zA-Z]{10,}-[0-9a-zA-Z]{10,}\b',
  );

  static final RegExp _keyedSecretRegex = RegExp(
    r'''\b(?:api[_-]?key|access[_-]?token|secret[_-]?key|client[_-]?secret|auth[_-]?token|bearer)\s*[:=]\s*['"]?([a-zA-Z0-9_\-\.]{16,})['"]?''',
    caseSensitive: false,
  );

  const PiiDetector();

  /// Scans the provided [text] and returns all detected sensitive matches.
  PiiScanResult scan(String text) {
    if (text.isEmpty) {
      return const PiiScanResult(matches: []);
    }

    final stopwatch = Stopwatch()..start();
    final lineStarts = _computeLineStarts(text);
    final rawMatches = <_IntermediateMatch>[];

    // 1. Private keys (Multi-line priority)
    for (final m in _privateKeyRegex.allMatches(text)) {
      rawMatches.add(
        _IntermediateMatch(
          type: PiiType.privateKey,
          rawValue: m.group(0)!,
          start: m.start,
          end: m.end,
        ),
      );
    }

    // 2. JWT tokens
    for (final m in _jwtRegex.allMatches(text)) {
      rawMatches.add(
        _IntermediateMatch(
          type: PiiType.jwtToken,
          rawValue: m.group(0)!,
          start: m.start,
          end: m.end,
        ),
      );
    }

    // 3. AWS keys
    for (final m in _awsKeyRegex.allMatches(text)) {
      rawMatches.add(
        _IntermediateMatch(
          type: PiiType.awsKey,
          rawValue: m.group(0)!,
          start: m.start,
          end: m.end,
        ),
      );
    }

    // 4. Known API Keys / tokens
    for (final m in _knownApiKeyTokens.allMatches(text)) {
      rawMatches.add(
        _IntermediateMatch(
          type: PiiType.apiKeySecret,
          rawValue: m.group(0)!,
          start: m.start,
          end: m.end,
        ),
      );
    }

    for (final m in _keyedSecretRegex.allMatches(text)) {
      final token = m.group(1);
      if (token != null && token.isNotEmpty) {
        final tokenStart = m.start + m.group(0)!.indexOf(token);
        rawMatches.add(
          _IntermediateMatch(
            type: PiiType.apiKeySecret,
            rawValue: token,
            start: tokenStart,
            end: tokenStart + token.length,
          ),
        );
      }
    }

    // 5. Emails
    for (final m in _emailRegex.allMatches(text)) {
      rawMatches.add(
        _IntermediateMatch(
          type: PiiType.email,
          rawValue: m.group(0)!,
          start: m.start,
          end: m.end,
        ),
      );
    }

    // 6. IP Addresses (IPv4 and IPv6)
    for (final m in _ipv4Regex.allMatches(text)) {
      final value = m.group(0)!;
      if (_isValidIpv4(value)) {
        rawMatches.add(
          _IntermediateMatch(
            type: PiiType.ipAddress,
            rawValue: value,
            start: m.start,
            end: m.end,
          ),
        );
      }
    }

    for (final m in _ipv6Regex.allMatches(text)) {
      rawMatches.add(
        _IntermediateMatch(
          type: PiiType.ipAddress,
          rawValue: m.group(0)!,
          start: m.start,
          end: m.end,
        ),
      );
    }

    // 7. Credit Cards (with Luhn algorithm filter)
    for (final m in _creditCardRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
      if (digits.length >= 13 && digits.length <= 19 && _isValidLuhn(digits)) {
        rawMatches.add(
          _IntermediateMatch(
            type: PiiType.creditCard,
            rawValue: raw,
            start: m.start,
            end: m.end,
          ),
        );
      }
    }

    // 8. Phone Numbers
    for (final m in _phoneRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      // Ensure phone numbers have at least 7 digits and reasonable structure
      if (digits.length >= 7 &&
          digits.length <= 15 &&
          (raw.contains('-') ||
              raw.contains(' ') ||
              raw.contains('(') ||
              raw.startsWith('+') ||
              digits.length == 10)) {
        rawMatches.add(
          _IntermediateMatch(
            type: PiiType.phone,
            rawValue: raw,
            start: m.start,
            end: m.end,
          ),
        );
      }
    }

    // Sort by start offset ascending, then by length descending
    rawMatches.sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return (b.end - b.start).compareTo(a.end - a.start);
    });

    // Remove overlapping matches (keep earlier / longer)
    final nonOverlapping = <_IntermediateMatch>[];
    int lastEnd = -1;
    for (final match in rawMatches) {
      if (match.start >= lastEnd) {
        nonOverlapping.add(match);
        lastEnd = match.end;
      }
    }

    // Convert to PiiMatch with line and column
    int idCounter = 1;
    final finalMatches = nonOverlapping.map((m) {
      final (line, col) = _getLineAndColumn(m.start, lineStarts);
      return PiiMatch(
        id: 'pii_${idCounter++}',
        type: m.type,
        rawValue: m.rawValue,
        start: m.start,
        end: m.end,
        line: line,
        column: col,
        isSelected: true,
      );
    }).toList();

    stopwatch.stop();
    return PiiScanResult(
      matches: finalMatches,
      scanDuration: stopwatch.elapsed,
    );
  }

  /// Validates IPv4 octets (0 <= octet <= 255).
  static bool _isValidIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  /// Validates a digit string with the Luhn checksum formula.
  static bool _isValidLuhn(String digits) {
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return (sum % 10) == 0;
  }

  /// Computes start indices of each line in [text].
  static List<int> _computeLineStarts(String text) {
    final starts = <int>[0];
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        starts.add(i + 1);
      }
    }
    return starts;
  }

  /// Returns 1-indexed (line, col) for a given string index.
  static (int, int) _getLineAndColumn(int index, List<int> lineStarts) {
    int low = 0;
    int high = lineStarts.length - 1;
    int line = 0;

    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lineStarts[mid] <= index) {
        line = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final col = (index - lineStarts[line]) + 1;
    return (line + 1, col);
  }
}

class _IntermediateMatch {
  final PiiType type;
  final String rawValue;
  final int start;
  final int end;

  const _IntermediateMatch({
    required this.type,
    required this.rawValue,
    required this.start,
    required this.end,
  });
}
