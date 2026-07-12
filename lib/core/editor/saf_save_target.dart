import 'dart:io';
import 'dart:typed_data';

import '../storage/saf_exceptions.dart';
import '../storage/saf_service.dart';
import 'atomic_saver.dart';

/// A [SaveTarget] that writes through the app's SAF file access.
///
/// The overwrite path first writes the fully-encoded bytes to a **private temp
/// file** and verifies its length, then pushes them to the SAF URI. So a failed
/// or partial local write never reaches the original document (CLAUDE.md §3.5,
/// architecture.md §6). "Save as a copy" goes through the system create-document
/// picker, leaving the original untouched.
class SafSaveTarget implements SaveTarget {
  final SafService _saf;
  final String _uri;
  final bool _canOverwrite;
  final Directory _tempDir;
  final String _mimeType;

  SafSaveTarget({
    required SafService saf,
    required String uri,
    required bool canOverwrite,
    required Directory tempDir,
    String mimeType = 'application/octet-stream',
  })  : _saf = saf,
        _uri = uri,
        _canOverwrite = canOverwrite,
        _tempDir = tempDir,
        _mimeType = mimeType;

  @override
  bool get canOverwrite => _canOverwrite;

  @override
  Future<void> writeOverwrite(Uint8List bytes) async {
    // Materialize + verify locally before touching the real document.
    if (!await _tempDir.exists()) {
      await _tempDir.create(recursive: true);
    }
    final temp = File(
      '${_tempDir.path}/save_${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temp.writeAsBytes(bytes, flush: true);
      final written = await temp.length();
      if (written != bytes.length) {
        throw const SafIoFailure('The file could not be fully written.');
      }
      // Only now push the verified bytes through the SAF URI.
      await _saf.writeBytes(_uri, bytes);
    } finally {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } on FileSystemException {
          // A leftover temp file is harmless; ignore.
        }
      }
    }
  }

  @override
  Future<SaveDestination> writeCopy(String suggestedName, Uint8List bytes) async {
    final file = await _saf.createDocument(
      suggestedName: suggestedName,
      bytes: bytes,
      mimeType: _mimeType,
    );
    return SaveDestination(uri: file.uri, displayName: file.displayName);
  }
}
