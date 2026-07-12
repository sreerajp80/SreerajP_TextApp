import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/txt/txt_content_sniff.dart';

void main() {
  Uint8List bytes(List<int> b) => Uint8List.fromList(b);

  test('plain ASCII text is not binary', () {
    expect(TxtContentSniff.looksBinary(bytes(utf8.encode('hello world\n'))),
        isFalse);
  });

  test('empty input is treated as text', () {
    expect(TxtContentSniff.looksBinary(Uint8List(0)), isFalse);
  });

  test('a NUL byte marks content as binary', () {
    expect(TxtContentSniff.looksBinary(bytes([0x68, 0x00, 0x69])), isTrue);
  });

  test('UTF-16 text (many NUL bytes) is not flagged as binary', () {
    // "hi" in UTF-16 LE with BOM.
    expect(
      TxtContentSniff.looksBinary(bytes([0xFF, 0xFE, 0x68, 0x00, 0x69, 0x00])),
      isFalse,
    );
  });

  test('a run of control bytes marks content as binary', () {
    final b = List<int>.filled(100, 0x01);
    expect(TxtContentSniff.looksBinary(bytes(b)), isTrue);
  });

  test('tabs and newlines do not count as binary control bytes', () {
    expect(
      TxtContentSniff.looksBinary(bytes(utf8.encode('a\tb\nc\r\nd'))),
      isFalse,
    );
  });
}
