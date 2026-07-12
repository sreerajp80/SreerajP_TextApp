import 'dart:typed_data';

/// A quick, cheap check of whether some opened bytes look like text rather than
/// binary data (task 4.4).
///
/// The codec never throws on bad input, so a binary file still "decodes" to
/// mojibake. This sniff lets the TXT module warn the user first ("this doesn't
/// look like text") instead of showing a screen full of garbage — while still
/// letting them view it raw if they insist. It is only a heuristic and is
/// deliberately conservative: it flags the clear binary cases, not edge cases.
class TxtContentSniff {
  const TxtContentSniff._();

  /// How many leading bytes to inspect. A binary header is enough to decide; we
  /// do not scan whole large files.
  static const int sampleSize = 8192;

  /// Returns true when [bytes] look like binary (non-text) content.
  ///
  /// Rules on the leading sample:
  /// - A NUL byte (`0x00`) that is **not** part of a UTF-16 pattern is a strong
  ///   binary signal (plain text never contains NUL).
  /// - A high proportion of other control bytes (outside tab / newline / return)
  ///   also marks it binary.
  ///
  /// Empty input is treated as text (an empty file opens as an empty document).
  static bool looksBinary(Uint8List bytes) {
    if (bytes.isEmpty) return false;

    final n = bytes.length < sampleSize ? bytes.length : sampleSize;

    // UTF-16 text is full of NUL bytes by design; don't misread it as binary.
    if (_looksLikeUtf16(bytes, n)) return false;

    var controls = 0;
    for (var i = 0; i < n; i++) {
      final b = bytes[i];
      if (b == 0x00) return true; // NUL → binary.
      if (b < 0x20 && b != 0x09 && b != 0x0A && b != 0x0D) {
        controls++;
      }
    }
    // More than ~10% odd control bytes → treat as binary.
    return controls > n ~/ 10;
  }

  /// True when the sample shows the alternating-zero-byte pattern of UTF-16.
  static bool _looksLikeUtf16(Uint8List bytes, int n) {
    if (n < 4) return false;
    // BOM check first.
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) return true;
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) return true;

    var zerosOdd = 0;
    var zerosEven = 0;
    for (var i = 0; i < n; i++) {
      if (bytes[i] == 0x00) {
        if (i.isEven) {
          zerosEven++;
        } else {
          zerosOdd++;
        }
      }
    }
    final threshold = n ~/ 4;
    return (zerosOdd > threshold && zerosOdd > zerosEven * 4) ||
        (zerosEven > threshold && zerosEven > zerosOdd * 4);
  }
}
