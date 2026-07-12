import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A stable identity for a file's *content*.
///
/// It combines the byte length with a SHA-256 hash of the bytes. Two files with
/// the same bytes get the same fingerprint; changing a single byte changes it.
/// The app keys reading positions, bookmarks, and drafts to this so they survive
/// a move or rename, and a modified file is treated as a new document
/// (architecture.md §11).
class ContentFingerprint {
  /// Number of bytes in the content.
  final int size;

  /// Lower-case hex SHA-256 of the content.
  final String sha256Hex;

  const ContentFingerprint({required this.size, required this.sha256Hex});

  /// Builds a fingerprint from bytes already in memory.
  factory ContentFingerprint.fromBytes(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return ContentFingerprint(size: bytes.length, sha256Hex: digest.toString());
  }

  /// Builds a fingerprint from a byte stream without holding the whole file in
  /// memory. Use this for large files so memory stays bounded (architecture.md
  /// §11).
  static Future<ContentFingerprint> fromStream(
    Stream<List<int>> byteStream,
  ) async {
    var size = 0;
    final sink = _DigestSink();
    final input = sha256.startChunkedConversion(sink);
    await for (final chunk in byteStream) {
      size += chunk.length;
      input.add(chunk);
    }
    input.close();
    return ContentFingerprint(size: size, sha256Hex: sink.value.toString());
  }

  /// A short, stable string form: `"<size>-<sha256>"`. Handy as a DB key.
  String get key => '$size-$sha256Hex';

  /// Parses the [key] form back into a fingerprint. Returns `null` if the text
  /// is not a valid fingerprint key (never throws).
  static ContentFingerprint? tryParse(String key) {
    final dash = key.indexOf('-');
    if (dash <= 0 || dash == key.length - 1) return null;
    final size = int.tryParse(key.substring(0, dash));
    if (size == null || size < 0) return null;
    final hash = key.substring(dash + 1);
    if (hash.length != 64 || !_isHex(hash)) return null;
    return ContentFingerprint(size: size, sha256Hex: hash);
  }

  static bool _isHex(String s) {
    for (final c in s.codeUnits) {
      final isDigit = c >= 0x30 && c <= 0x39;
      final isLower = c >= 0x61 && c <= 0x66;
      if (!isDigit && !isLower) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is ContentFingerprint &&
      other.size == size &&
      other.sha256Hex == sha256Hex;

  @override
  int get hashCode => Object.hash(size, sha256Hex);

  @override
  String toString() => 'ContentFingerprint($key)';
}

/// Collects the final digest from a chunked hash conversion.
class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// Kept for readability at call sites that pass a UTF-8 string.
Uint8List utf8Bytes(String text) => Uint8List.fromList(utf8.encode(text));
