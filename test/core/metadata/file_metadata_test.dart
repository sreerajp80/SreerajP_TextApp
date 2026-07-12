import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/core/metadata/file_metadata.dart';
import 'package:text_data/core/storage/saf_service.dart';

void main() {
  final service = MetadataService(SafService());
  const codec = TextCodecService();

  test('metadata for a sample file matches expected values', () {
    const file = SafFile(
      uri: 'content://sample',
      displayName: 'notes.txt',
      mimeType: 'text/plain',
      size: 11,
    );
    final decoded = codec.detectAndDecode(
      List<int>.from('Hello world'.codeUnits),
    );

    final meta = service.build(file: file, decoded: decoded);
    expect(meta.name, 'notes.txt');
    expect(meta.size, 11);
    expect(meta.encoding, TextEncodingType.ascii);
    expect(meta.lineEnding, LineEndingStyle.lf);
    expect(meta.formatFields, isEmpty);
  });

  test('falls back to decoded length when size is unknown', () {
    const file = SafFile(uri: 'content://x', displayName: 'x.txt');
    final decoded = DecodedText(
      text: 'abcd',
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.lf,
    );
    final meta = service.build(file: file, decoded: decoded);
    expect(meta.size, 4);
  });

  test('per-format fields are carried through', () {
    const file = SafFile(uri: 'content://x', displayName: 'data.csv');
    final decoded = DecodedText(
      text: 'a,b',
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.crlf,
    );
    final meta = service.build(
      file: file,
      decoded: decoded,
      formatFields: const {'Rows': '10', 'Columns': '3'},
    );
    expect(meta.formatFields['Rows'], '10');
    expect(meta.formatFields['Columns'], '3');
    expect(meta.lineEnding, LineEndingStyle.crlf);
  });
}
