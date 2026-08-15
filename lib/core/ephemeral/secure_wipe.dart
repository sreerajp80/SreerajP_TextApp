import 'dart:io';
import 'dart:typed_data';

/// Best-effort zero-fill wiping for app-private files (Feature 9).
///
/// ## What this really gives you
///
/// [wipeFile] overwrites a file's bytes with `0x00` before deleting it, so the
/// content cannot be read back through the **logical** file — an ordinary
/// undelete or a stale directory entry finds zeros, not text.
///
/// It is **not** a guarantee that the original bytes are gone from the device.
/// Android stores app data on flash, where wear-levelling and the filesystem's
/// journal may keep the old blocks alive somewhere the app cannot reach. The
/// real protection for app-private data is Android's per-app file-based
/// encryption; this overwrite is defence in depth on top of it. Nothing in the
/// app or its wording should promise more than that.
///
/// Pure `dart:io` with no Flutter dependency, so it is directly unit-testable.
class SecureWipe {
  const SecureWipe._();

  /// Size of the buffer used to overwrite a large file in slices, so wiping a
  /// big draft never allocates the whole file in memory.
  static const int chunkSize = 64 * 1024;

  /// Overwrites [file] with `0x00` and then deletes it.
  ///
  /// Returns true when the file is gone afterwards. Never throws: a missing
  /// file, a permission error, or a file another process holds open all return
  /// false (or true if the delete still succeeded), because a burn must keep
  /// going through the rest of its steps (see `EphemeralWiper`).
  static Future<bool> wipeFile(File file) async {
    try {
      if (!await file.exists()) return true;
      await overwriteWithZeros(file);
    } catch (_) {
      // Overwrite failed — still try the delete below, since removing the file
      // is better than leaving it fully readable.
    }
    try {
      if (await file.exists()) await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The overwrite half of [wipeFile], without the delete.
  ///
  /// Public only so a test can read the file back and prove every byte really
  /// is `0x00`. Application code should call [wipeFile], which also deletes.
  static Future<void> overwriteWithZeros(File file) async {
    final length = await file.length();
    if (length == 0) return;

    // `FileMode.write` positions at the start and truncates, so every byte the
    // file had is replaced by the zeros written below. Written in slices so a
    // large draft never allocates its whole length in memory.
    final sink = file.openWrite(mode: FileMode.write);
    try {
      final zeros = Uint8List(
        length < chunkSize ? length : chunkSize,
      ); // a fresh Uint8List is already all zero
      var written = 0;
      while (written < length) {
        final remaining = length - written;
        if (remaining >= zeros.length) {
          sink.add(zeros);
          written += zeros.length;
        } else {
          sink.add(Uint8List.sublistView(zeros, 0, remaining));
          written += remaining;
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Zero-fills a mutable byte buffer in place.
  ///
  /// This one *is* a real scrub: a [Uint8List] is mutable, so the bytes it held
  /// are genuinely overwritten. Use it for cached raw file bytes. It has no
  /// equivalent for a Dart [String], which is immutable and garbage-collected —
  /// the only thing an app can do there is drop every reference to it.
  static void zeroBytes(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return;
    bytes.fillRange(0, bytes.length, 0);
  }
}
