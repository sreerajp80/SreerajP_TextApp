import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/encoding.dart';

void main() {
  const codec = TextCodecService();

  group('detectAndDecode', () {
    test('plain ASCII', () {
      final bytes = Uint8List.fromList(utf8.encode('Hello world'));
      final result = codec.detectAndDecode(bytes);
      expect(result.encoding, TextEncodingType.ascii);
      expect(result.text, 'Hello world');
      expect(result.lineEnding, LineEndingStyle.lf);
    });

    test('UTF-8 with multibyte characters', () {
      final bytes = Uint8List.fromList(utf8.encode('Café — malayāḷam'));
      final result = codec.detectAndDecode(bytes);
      expect(result.encoding, TextEncodingType.utf8);
      expect(result.text, 'Café — malayāḷam');
    });

    test('UTF-8 BOM is detected and stripped', () {
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('hi')]);
      final result = codec.detectAndDecode(bytes);
      expect(result.encoding, TextEncodingType.utf8Bom);
      expect(result.text, 'hi');
    });

    test('UTF-16 LE with BOM', () {
      final bytes = codec.encode('Hi ✓', TextEncodingType.utf16le, LineEndingStyle.lf);
      final result = codec.detectAndDecode(bytes);
      expect(result.encoding, TextEncodingType.utf16le);
      expect(result.text, 'Hi ✓');
    });

    test('UTF-16 BE with BOM', () {
      final bytes = codec.encode('Hi ✓', TextEncodingType.utf16be, LineEndingStyle.lf);
      final result = codec.detectAndDecode(bytes);
      expect(result.encoding, TextEncodingType.utf16be);
      expect(result.text, 'Hi ✓');
    });

    test('Windows-1252 high bytes (smart quotes, euro)', () {
      // 0x93/0x94 = curly quotes, 0x80 = euro, 0x96 = en dash.
      final bytes = Uint8List.fromList([0x93, 0x80, 0x35, 0x96, 0x94]);
      final result = codec.detectAndDecode(bytes);
      expect(result.encoding, TextEncodingType.windows1252);
      expect(result.text, '“€5–”');
    });

    test('line endings: CRLF detected and normalized to \\n', () {
      final bytes = Uint8List.fromList(utf8.encode('a\r\nb\r\nc'));
      final result = codec.detectAndDecode(bytes);
      expect(result.lineEnding, LineEndingStyle.crlf);
      expect(result.text, 'a\nb\nc');
    });

    test('line endings: bare CR', () {
      final bytes = Uint8List.fromList(utf8.encode('a\rb'));
      final result = codec.detectAndDecode(bytes);
      expect(result.lineEnding, LineEndingStyle.cr);
      expect(result.text, 'a\nb');
    });

    test('empty input never throws', () {
      final result = codec.detectAndDecode(Uint8List(0));
      expect(result.text, '');
      expect(result.encoding, TextEncodingType.ascii);
    });

    test('truncated UTF-8 multibyte decodes without throwing', () {
      // Lead byte of a 2-byte sequence with no continuation.
      final bytes = Uint8List.fromList([0x48, 0x69, 0xC3]);
      final result = codec.detectAndDecode(bytes);
      // Not valid UTF-8 → falls back to a single-byte codec; must not throw.
      expect(result.text.startsWith('Hi'), isTrue);
    });
  });

  group('round-trip encode/decode', () {
    const sample = 'line1\nline2\nEnd';

    for (final encoding in [
      TextEncodingType.utf8,
      TextEncodingType.utf8Bom,
      TextEncodingType.ascii,
      TextEncodingType.latin1,
      TextEncodingType.windows1252,
      TextEncodingType.utf16le,
      TextEncodingType.utf16be,
    ]) {
      test('$encoding preserves text (LF)', () {
        final bytes = codec.encode(sample, encoding, LineEndingStyle.lf);
        final decoded = codec.detectAndDecode(bytes);
        expect(decoded.text, sample);
      });
    }

    for (final style in LineEndingStyle.values) {
      test('$style line ending re-applied on encode', () {
        final bytes = codec.encode('a\nb', TextEncodingType.utf8, style);
        final text = utf8.decode(bytes);
        expect(text, 'a${style.sequence}b');
      });
    }

    test('windows-1252 special characters round-trip', () {
      const text = '“quote” €5 – dash';
      final bytes = codec.encode(text, TextEncodingType.windows1252, LineEndingStyle.lf);
      final decoded = codec.detectAndDecode(bytes);
      expect(decoded.text, text);
    });
  });
}
