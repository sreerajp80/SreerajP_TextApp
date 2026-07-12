import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/zip/zip_service.dart';

void main() {
  const zip = ZipService();

  Uint8List bytes(List<int> b) => Uint8List.fromList(b);

  group('ZipService', () {
    test('zip then unzip reproduces the exact bytes', () {
      final entries = {
        'notes.txt': bytes('hello world'.codeUnits),
        'data/raw.bin': bytes([0, 1, 2, 3, 255, 254, 128]),
        'empty.txt': bytes(const []),
      };

      final archive = zip.zipEntries(entries);
      final restored = zip.unzip(archive);

      expect(restored.keys.toSet(), entries.keys.toSet());
      for (final name in entries.keys) {
        expect(restored[name], entries[name], reason: name);
      }
    });

    test('zipOne round-trips a single file', () {
      final original = bytes('line1\nline2\n'.codeUnits);
      final restored = zip.unzip(zip.zipOne('a.txt', original));
      expect(restored['a.txt'], original);
    });

    test('produces a valid ZIP local-file signature', () {
      final out = zip.zipOne('x.txt', bytes('x'.codeUnits));
      // ZIP local file header magic: "PK\x03\x04".
      expect(out.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
    });
  });
}
