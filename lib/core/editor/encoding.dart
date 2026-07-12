import 'dart:convert';
import 'dart:typed_data';

/// The text encodings the app can detect, read, and write.
///
/// Covers the common cases an Android user meets: UTF-8 (with or without a byte
/// order mark), UTF-16 in both byte orders, plain ASCII, ISO-8859-1 (Latin-1),
/// and Windows-1252 — the usual "Windows code page" for Western text
/// (architecture.md §6). Detection never throws: a file that fits nothing else
/// still decodes through the single-byte fallback, so the app never crashes on a
/// bad or unknown encoding (CLAUDE.md §3.4).
enum TextEncodingType {
  /// UTF-8 with no byte order mark.
  utf8,

  /// UTF-8 that begins with the EF BB BF byte order mark.
  utf8Bom,

  /// UTF-16, little-endian (FF FE mark).
  utf16le,

  /// UTF-16, big-endian (FE FF mark).
  utf16be,

  /// 7-bit ASCII (a strict subset of UTF-8).
  ascii,

  /// ISO-8859-1 (Latin-1), one byte per character.
  latin1,

  /// Windows-1252, one byte per character (Latin-1 plus a few printable bytes
  /// in the 0x80–0x9F range).
  windows1252,
}

/// The line-ending style a file uses.
enum LineEndingStyle {
  /// `\n` — Unix / Android / macOS.
  lf,

  /// `\r\n` — Windows.
  crlf,

  /// `\r` — classic Mac (rare).
  cr,
}

extension LineEndingStyleText on LineEndingStyle {
  /// The literal characters this style writes.
  String get sequence {
    switch (this) {
      case LineEndingStyle.lf:
        return '\n';
      case LineEndingStyle.crlf:
        return '\r\n';
      case LineEndingStyle.cr:
        return '\r';
    }
  }
}

/// The result of decoding a file: the text plus what it was decoded as, so a
/// later save can preserve the encoding and line endings by default (arch §6).
class DecodedText {
  /// The decoded characters with **line endings normalized to `\n`**, which is
  /// what the editor works with in memory. The original [lineEnding] is kept so
  /// a save can restore it.
  final String text;

  final TextEncodingType encoding;
  final LineEndingStyle lineEnding;

  const DecodedText({
    required this.text,
    required this.encoding,
    required this.lineEnding,
  });
}

/// Detects, decodes, and re-encodes text for every format in the app.
///
/// This is the single place encodings and line endings are handled, shared by
/// all formats (arch §6). It is pure Dart with no Flutter dependency, so it can
/// be unit-tested on the host.
class TextCodecService {
  const TextCodecService();

  /// Detects the encoding and line-ending style of [bytes] and returns the
  /// decoded text (line endings normalized to `\n`). Never throws.
  DecodedText detectAndDecode(List<int> bytes) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final encoding = _detectEncoding(data);
    final raw = _decode(data, encoding);
    final lineEnding = _detectLineEnding(raw);
    final normalized = _normalizeNewlines(raw);
    return DecodedText(
      text: normalized,
      encoding: encoding,
      lineEnding: lineEnding,
    );
  }

  /// Decodes [bytes] using a **specific** [encoding] rather than auto-detecting
  /// it (used when the user overrides the detected encoding from the UI). Line
  /// endings are normalized to `\n`. Never throws.
  String decodeAs(List<int> bytes, TextEncodingType encoding) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    return _normalizeNewlines(_decode(data, encoding));
  }

  /// Encodes [text] (whose newlines are `\n`) back to bytes in [encoding],
  /// rewriting newlines to [lineEnding]. Adds the byte order mark for the BOM /
  /// UTF-16 encodings.
  Uint8List encode(
    String text,
    TextEncodingType encoding,
    LineEndingStyle lineEnding,
  ) {
    final withEndings = _applyLineEnding(text, lineEnding);
    switch (encoding) {
      case TextEncodingType.ascii:
        // Fall back to UTF-8 for any non-ASCII character rather than throwing,
        // so a save can never crash on content the user typed.
        return Uint8List.fromList(utf8.encode(withEndings));
      case TextEncodingType.latin1:
        return _encodeLatin1(withEndings);
      case TextEncodingType.windows1252:
        return _encodeWindows1252(withEndings);
      case TextEncodingType.utf16le:
        return _encodeUtf16(withEndings, bigEndian: false, bom: true);
      case TextEncodingType.utf16be:
        return _encodeUtf16(withEndings, bigEndian: true, bom: true);
      case TextEncodingType.utf8Bom:
        return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(withEndings)]);
      case TextEncodingType.utf8:
        return Uint8List.fromList(utf8.encode(withEndings));
    }
  }

  // --- detection ---------------------------------------------------------

  TextEncodingType _detectEncoding(Uint8List b) {
    // 1) Byte order marks are unambiguous.
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      return TextEncodingType.utf8Bom;
    }
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
      return TextEncodingType.utf16le;
    }
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
      return TextEncodingType.utf16be;
    }

    // 2) No BOM. Pure ASCII if every byte is < 0x80.
    if (_isAllAscii(b)) return TextEncodingType.ascii;

    // 3) Valid UTF-8 (multi-byte sequences check out)?
    if (_isValidUtf8(b)) return TextEncodingType.utf8;

    // 4) A UTF-16 file without a BOM often shows a strong pattern of alternating
    //    zero bytes. Detect that before giving up to a single-byte codec.
    final utf16 = _sniffBomlessUtf16(b);
    if (utf16 != null) return utf16;

    // 5) Single-byte fallback. Windows-1252 is the common Western default and a
    //    strict superset of the printable Latin-1 range, so it never fails.
    return TextEncodingType.windows1252;
  }

  bool _isAllAscii(Uint8List b) {
    for (final byte in b) {
      if (byte > 0x7F) return false;
    }
    return true;
  }

  /// Strict UTF-8 validation (no allocation of the decoded string).
  bool _isValidUtf8(Uint8List b) {
    var i = 0;
    final n = b.length;
    while (i < n) {
      final c = b[i];
      if (c < 0x80) {
        i += 1;
      } else if (c >= 0xC2 && c <= 0xDF) {
        if (i + 1 >= n || !_isCont(b[i + 1])) return false;
        i += 2;
      } else if (c == 0xE0) {
        if (i + 2 >= n || b[i + 1] < 0xA0 || b[i + 1] > 0xBF || !_isCont(b[i + 2])) {
          return false;
        }
        i += 3;
      } else if (c >= 0xE1 && c <= 0xEC || c == 0xEE || c == 0xEF) {
        if (i + 2 >= n || !_isCont(b[i + 1]) || !_isCont(b[i + 2])) return false;
        i += 3;
      } else if (c == 0xED) {
        // Exclude UTF-16 surrogate range.
        if (i + 2 >= n || b[i + 1] < 0x80 || b[i + 1] > 0x9F || !_isCont(b[i + 2])) {
          return false;
        }
        i += 3;
      } else if (c == 0xF0) {
        if (i + 3 >= n ||
            b[i + 1] < 0x90 ||
            b[i + 1] > 0xBF ||
            !_isCont(b[i + 2]) ||
            !_isCont(b[i + 3])) {
          return false;
        }
        i += 4;
      } else if (c >= 0xF1 && c <= 0xF3) {
        if (i + 3 >= n || !_isCont(b[i + 1]) || !_isCont(b[i + 2]) || !_isCont(b[i + 3])) {
          return false;
        }
        i += 4;
      } else if (c == 0xF4) {
        if (i + 3 >= n ||
            b[i + 1] < 0x80 ||
            b[i + 1] > 0x8F ||
            !_isCont(b[i + 2]) ||
            !_isCont(b[i + 3])) {
          return false;
        }
        i += 4;
      } else {
        return false;
      }
    }
    return true;
  }

  bool _isCont(int byte) => byte >= 0x80 && byte <= 0xBF;

  /// Looks for a BOM-less UTF-16 file by counting zero bytes in even vs odd
  /// positions. Western text in UTF-16 has one zero byte per character. Returns
  /// null when the pattern is not strong enough to be confident.
  TextEncodingType? _sniffBomlessUtf16(Uint8List b) {
    if (b.length < 4 || b.length.isOdd) return null;
    var zerosAtEven = 0;
    var zerosAtOdd = 0;
    final sample = b.length < 512 ? b.length : 512;
    for (var i = 0; i < sample; i++) {
      if (b[i] == 0x00) {
        if (i.isEven) {
          zerosAtEven++;
        } else {
          zerosAtOdd++;
        }
      }
    }
    final threshold = sample ~/ 4;
    if (zerosAtOdd > threshold && zerosAtOdd > zerosAtEven * 4) {
      // Zeros in the high byte → little-endian (e.g. 'A' == 41 00).
      return TextEncodingType.utf16le;
    }
    if (zerosAtEven > threshold && zerosAtEven > zerosAtOdd * 4) {
      return TextEncodingType.utf16be;
    }
    return null;
  }

  // --- decoding ----------------------------------------------------------

  String _decode(Uint8List b, TextEncodingType encoding) {
    switch (encoding) {
      case TextEncodingType.utf8Bom:
        return utf8.decode(b.sublist(3), allowMalformed: true);
      case TextEncodingType.utf8:
      case TextEncodingType.ascii:
        return utf8.decode(b, allowMalformed: true);
      case TextEncodingType.latin1:
        return latin1.decode(b, allowInvalid: true);
      case TextEncodingType.windows1252:
        return _decodeWindows1252(b);
      case TextEncodingType.utf16le:
        return _decodeUtf16(b, bigEndian: false);
      case TextEncodingType.utf16be:
        return _decodeUtf16(b, bigEndian: true);
    }
  }

  String _decodeUtf16(Uint8List b, {required bool bigEndian}) {
    var start = 0;
    // Skip a leading BOM if present.
    if (b.length >= 2) {
      if (!bigEndian && b[0] == 0xFF && b[1] == 0xFE) start = 2;
      if (bigEndian && b[0] == 0xFE && b[1] == 0xFF) start = 2;
    }
    final units = <int>[];
    for (var i = start; i + 1 < b.length; i += 2) {
      final unit = bigEndian ? (b[i] << 8) | b[i + 1] : (b[i + 1] << 8) | b[i];
      units.add(unit);
    }
    // String.fromCharCodes joins UTF-16 code units (including surrogate pairs).
    return String.fromCharCodes(units);
  }

  String _decodeWindows1252(Uint8List b) {
    final buffer = StringBuffer();
    for (final byte in b) {
      buffer.writeCharCode(_windows1252ToUnicode(byte));
    }
    return buffer.toString();
  }

  int _windows1252ToUnicode(int byte) {
    // 0x00–0x7F and 0xA0–0xFF match Unicode directly (Latin-1). Only 0x80–0x9F
    // map to a handful of printable characters; the five unused slots fall back
    // to the C1 control code of the same value.
    if (byte >= 0x80 && byte <= 0x9F) {
      final mapped = _cp1252High[byte - 0x80];
      return mapped == 0 ? byte : mapped;
    }
    return byte;
  }

  // --- encoding helpers --------------------------------------------------

  Uint8List _encodeLatin1(String s) {
    final out = Uint8List(s.length);
    var i = 0;
    for (final rune in s.runes) {
      // Any character above Latin-1 range degrades to '?' rather than throwing.
      out[i++] = rune <= 0xFF ? rune : 0x3F;
    }
    return out.sublist(0, i);
  }

  Uint8List _encodeWindows1252(String s) {
    final bytes = <int>[];
    for (final rune in s.runes) {
      if (rune <= 0x7F || (rune >= 0xA0 && rune <= 0xFF)) {
        bytes.add(rune);
        continue;
      }
      final high = _unicodeToCp1252High(rune);
      bytes.add(high ?? 0x3F); // '?' when the character has no 1252 byte.
    }
    return Uint8List.fromList(bytes);
  }

  Uint8List _encodeUtf16(String s, {required bool bigEndian, required bool bom}) {
    final units = s.codeUnits;
    final out = Uint8List((bom ? 1 : 0) * 2 + units.length * 2);
    var p = 0;
    if (bom) {
      if (bigEndian) {
        out[p++] = 0xFE;
        out[p++] = 0xFF;
      } else {
        out[p++] = 0xFF;
        out[p++] = 0xFE;
      }
    }
    for (final u in units) {
      if (bigEndian) {
        out[p++] = (u >> 8) & 0xFF;
        out[p++] = u & 0xFF;
      } else {
        out[p++] = u & 0xFF;
        out[p++] = (u >> 8) & 0xFF;
      }
    }
    return out;
  }

  int? _unicodeToCp1252High(int rune) {
    for (var i = 0; i < _cp1252High.length; i++) {
      if (_cp1252High[i] == rune) return 0x80 + i;
    }
    return null;
  }

  // --- line endings ------------------------------------------------------

  LineEndingStyle _detectLineEnding(String s) {
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x0D) {
        // \r
        if (i + 1 < s.length && s.codeUnitAt(i + 1) == 0x0A) {
          return LineEndingStyle.crlf;
        }
        return LineEndingStyle.cr;
      }
      if (c == 0x0A) {
        // \n
        return LineEndingStyle.lf;
      }
    }
    return LineEndingStyle.lf; // No newline at all → default.
  }

  String _normalizeNewlines(String s) {
    if (!s.contains('\r')) return s;
    return s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  String _applyLineEnding(String s, LineEndingStyle style) {
    if (style == LineEndingStyle.lf) return s;
    return s.replaceAll('\n', style.sequence);
  }
}

/// Windows-1252 characters for bytes 0x80–0x9F. A value of `0` marks an
/// undefined slot (0x81, 0x8D, 0x8F, 0x90, 0x9D), which round-trips as its own
/// byte value. All other bytes (0x00–0x7F, 0xA0–0xFF) equal their Unicode code
/// point, so only this small window needs a table.
const List<int> _cp1252High = [
  0x20AC, // 0x80 €
  0x0000, // 0x81 (undefined)
  0x201A, // 0x82 ‚
  0x0192, // 0x83 ƒ
  0x201E, // 0x84 „
  0x2026, // 0x85 …
  0x2020, // 0x86 †
  0x2021, // 0x87 ‡
  0x02C6, // 0x88 ˆ
  0x2030, // 0x89 ‰
  0x0160, // 0x8A Š
  0x2039, // 0x8B ‹
  0x0152, // 0x8C Œ
  0x0000, // 0x8D (undefined)
  0x017D, // 0x8E Ž
  0x0000, // 0x8F (undefined)
  0x0000, // 0x90 (undefined)
  0x2018, // 0x91 ‘
  0x2019, // 0x92 ’
  0x201C, // 0x93 “
  0x201D, // 0x94 ”
  0x2022, // 0x95 •
  0x2013, // 0x96 –
  0x2014, // 0x97 —
  0x02DC, // 0x98 ˜
  0x2122, // 0x99 ™
  0x0161, // 0x9A š
  0x203A, // 0x9B ›
  0x0153, // 0x9C œ
  0x0000, // 0x9D (undefined)
  0x017E, // 0x9E ž
  0x0178, // 0x9F Ÿ
];
