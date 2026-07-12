import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'saf_exceptions.dart';

/// A file the user picked through the system picker, with the info the app needs
/// to list and re-open it. [uri] is the persisted SAF URI used as the fast path
/// back to the file (architecture.md §11).
class SafFile {
  final String uri;
  final String displayName;
  final String? mimeType;
  final int? size;

  const SafFile({
    required this.uri,
    required this.displayName,
    this.mimeType,
    this.size,
  });
}

/// Scoped-storage file access over a Storage Access Framework (SAF) platform
/// channel.
///
/// The app opens files **only** through the system picker and "Open with" /
/// share intents — no broad storage permission and no in-app file browser
/// (CLAUDE.md §3.3). On pick, the native side takes a **persistable URI
/// permission** so the file can be re-opened later from its saved URI.
///
/// Every native error maps to a [SafException]; this wrapper never throws a raw
/// [PlatformException] at callers, and never crashes on a stale or revoked URI
/// (CLAUDE.md §3.4).
class SafService {
  /// Name of the method channel shared with the Android side.
  static const channelName = 'in.zohomail.sreerajp.text_data/saf';

  final MethodChannel _channel;

  SafService([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(channelName);

  /// Opens the system picker so the user can choose one file, and takes a
  /// persistable read/write permission on it.
  ///
  /// Throws [SafCancelled] if the user backs out, or another [SafException] on
  /// failure.
  Future<SafFile> pickFile({List<String> mimeTypes = const ['*/*']}) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'pickFile',
      {'mimeTypes': mimeTypes},
    );
    if (result == null) {
      // Native returned null → user cancelled.
      throw const SafCancelled();
    }
    return _fileFromMap(result);
  }

  /// Reads the whole file at [uri] as bytes.
  ///
  /// Throws [SafPermissionDenied] / [SafUriStale] / [SafIoFailure] as
  /// appropriate — never a raw platform error.
  Future<Uint8List> readBytes(String uri) async {
    final bytes = await _invoke<Uint8List>('readBytes', {'uri': uri});
    if (bytes == null) throw const SafIoFailure();
    return bytes;
  }

  /// Writes [bytes] to the document at [uri] (overwrite).
  ///
  /// Phase 1 only exposes this primitive; the atomic temp-write-then-replace
  /// flow is built on top of it in Phase 3 (architecture.md §6).
  Future<void> writeBytes(String uri, Uint8List bytes) async {
    await _invoke<void>('writeBytes', {'uri': uri, 'bytes': bytes});
  }

  /// Opens the system "create document" picker so the user chooses where to save
  /// a new file, writes [bytes] into it, and takes a persistable permission on
  /// the result. Used by "Save as a copy" (architecture.md §6).
  ///
  /// Throws [SafCancelled] if the user backs out, or another [SafException] on
  /// failure. The original file is never touched by this call.
  Future<SafFile> createDocument({
    required String suggestedName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    final result = await _invoke<Map<Object?, Object?>>('createDocument', {
      'suggestedName': suggestedName,
      'mimeType': mimeType,
      'bytes': bytes,
    });
    if (result == null) {
      throw const SafCancelled();
    }
    return _fileFromMap(result);
  }

  /// Whether the app holds a **write** grant for [uri]. A read-only grant
  /// returns `false`, so the editor offers only "Save as a copy" (architecture
  /// §6). Never throws — an unknown/stale URI returns `false`.
  Future<bool> isWritable(String uri) async {
    try {
      final ok = await _invoke<bool>('isWritable', {'uri': uri});
      return ok ?? false;
    } on SafException {
      return false;
    }
  }

  /// The document's last-modified time in epoch millis, or `null` when the
  /// provider does not report it. Used by the metadata service (task 3.9).
  Future<int?> modifiedTime(String uri) async {
    try {
      final millis = await _invoke<int>('modifiedTime', {'uri': uri});
      return (millis == null || millis <= 0) ? null : millis;
    } on SafException {
      return null;
    }
  }

  /// Returns `true` if [uri] still points at a reachable document the app may
  /// read. A moved/deleted file or a revoked grant returns `false` (it does not
  /// throw), so callers can mark a recent entry as unavailable.
  Future<bool> isAccessible(String uri) async {
    try {
      final ok = await _invoke<bool>('isAccessible', {'uri': uri});
      return ok ?? false;
    } on SafException {
      return false;
    }
  }

  /// Releases a previously persisted permission for [uri]. Safe to call even if
  /// the permission is already gone.
  Future<void> releasePermission(String uri) async {
    await _invoke<void>('releasePermission', {'uri': uri});
  }

  /// The URIs the app currently holds a persisted permission for.
  Future<List<String>> persistedUris() async {
    final list = await _invoke<List<Object?>>('persistedUris', const {});
    if (list == null) return const [];
    return list.whereType<String>().toList(growable: false);
  }

  SafFile _fileFromMap(Map<Object?, Object?> map) {
    return SafFile(
      uri: map['uri'] as String,
      displayName: (map['displayName'] as String?) ?? 'Untitled',
      mimeType: map['mimeType'] as String?,
      size: (map['size'] as num?)?.toInt(),
    );
  }

  /// Calls the channel and maps any [PlatformException] to a [SafException].
  Future<T?> _invoke<T>(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw _mapError(e.code);
    } on MissingPluginException {
      throw const SafUnknownFailure('File access is not available.');
    }
  }

  SafException _mapError(String code) {
    switch (code) {
      case 'cancelled':
        return const SafCancelled();
      case 'permission_denied':
        return const SafPermissionDenied();
      case 'uri_stale':
        return const SafUriStale();
      case 'io_failure':
        return const SafIoFailure();
      default:
        return const SafUnknownFailure();
    }
  }
}

/// App-wide [SafService] instance.
final safServiceProvider = Provider<SafService>((ref) => SafService());
