import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Compress-for-sharing service (task 5.2).
///
/// Pure Dart on top of the `archive` package — no I/O and no platform channel,
/// so it is fully host-testable. Used to zip the current file or an exported
/// output before handing it to the [ShareService], and available to every
/// format.
class ZipService {
  const ZipService();

  /// Packs [entries] (map of in-archive file name → bytes) into a single ZIP
  /// archive and returns its bytes.
  ///
  /// Names are used verbatim as the stored path; keep them relative (no leading
  /// slash) so the archive extracts cleanly.
  Uint8List zipEntries(Map<String, Uint8List> entries) {
    final archive = Archive();
    entries.forEach((name, bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Convenience: zip a single named file.
  Uint8List zipOne(String name, Uint8List bytes) =>
      zipEntries({name: bytes});

  /// Unpacks a ZIP archive back into a map of file name → bytes. Round-trips
  /// with [zipEntries] (used by the test and by any future import path).
  Map<String, Uint8List> unzip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final result = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.isFile) {
        result[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }
    return result;
  }
}
