import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:text_data/sync/sync_constants.dart';

/// Thrown when a direct file transfer payload is malformed, too large, or invalid.
class FileTransferException implements Exception {
  final String message;
  const FileTransferException(this.message);

  @override
  String toString() => 'FileTransferException: $message';
}

/// A parsed, validated payload representing a single document file streamed
/// directly between devices over local sockets.
@immutable
class FileTransferPayload {
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String fileContent;
  final String fileEncoding;
  final DateTime sentAt;

  const FileTransferPayload({
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.fileContent,
    required this.fileEncoding,
    required this.sentAt,
  });

  /// Serializes the file transfer payload to wire JSON.
  Map<String, dynamic> toJson() => {
    SyncConstants.keyApp: SyncConstants.appId,
    SyncConstants.keyPayloadVersion: SyncConstants.payloadVersion,
    SyncConstants.keyPayloadType: SyncConstants.payloadTypeFileTransfer,
    SyncConstants.keyFileName: fileName,
    SyncConstants.keyMimeType: mimeType,
    SyncConstants.keyFileSizeBytes: fileSizeBytes,
    SyncConstants.keyFileContent: fileContent,
    SyncConstants.keyFileEncoding: fileEncoding,
    'sentAt': sentAt.toUtc().toIso8601String(),
  };

  String toWireJson() => jsonEncode(toJson());

  /// Builds a [FileTransferPayload] with security validation.
  static FileTransferPayload build({
    required String rawFileName,
    required String mimeType,
    required String fileContent,
    String fileEncoding = 'utf-8',
  }) {
    final sanitizedName = _sanitizeFileName(rawFileName);
    final size = utf8.encode(fileContent).length;

    if (size > SyncConstants.maxFileTransferBytes) {
      throw FileTransferException(
        'File size ($size bytes) exceeds 50 MB maximum transfer limit.',
      );
    }

    return FileTransferPayload(
      fileName: sanitizedName,
      mimeType: mimeType,
      fileSizeBytes: size,
      fileContent: fileContent,
      fileEncoding: fileEncoding,
      sentAt: DateTime.now(),
    );
  }

  /// Parses and validates a received JSON string, treating it as hostile.
  static FileTransferPayload validateAndParse(String jsonString) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw const FileTransferException(
        'The received data was not valid JSON.',
      );
    }

    if (decoded is! Map<String, dynamic> && decoded is! Map<String, Object?>) {
      throw const FileTransferException(
        'The received data had an invalid structure.',
      );
    }

    final map = decoded as Map<String, Object?>;

    if (map[SyncConstants.keyApp] != SyncConstants.appId) {
      throw const FileTransferException(
        'This payload is from a different app.',
      );
    }

    final version = map[SyncConstants.keyPayloadVersion];
    if (version is! int || version > SyncConstants.payloadVersion) {
      throw const FileTransferException('Unsupported payload version.');
    }

    final type = map[SyncConstants.keyPayloadType];
    if (type != SyncConstants.payloadTypeFileTransfer) {
      throw const FileTransferException('Not a direct file transfer payload.');
    }

    final rawFileName = map[SyncConstants.keyFileName];
    if (rawFileName is! String || rawFileName.trim().isEmpty) {
      throw const FileTransferException('Missing or invalid file name.');
    }

    final sanitizedName = _sanitizeFileName(rawFileName);

    final mimeType =
        (map[SyncConstants.keyMimeType] as String?) ?? 'text/plain';
    final encoding = (map[SyncConstants.keyFileEncoding] as String?) ?? 'utf-8';

    final content = map[SyncConstants.keyFileContent];
    if (content is! String) {
      throw const FileTransferException('Missing or invalid file content.');
    }

    final size = utf8.encode(content).length;
    if (size > SyncConstants.maxFileTransferBytes) {
      throw const FileTransferException(
        'Payload exceeds maximum file transfer size.',
      );
    }

    DateTime sentAt = DateTime.now();
    final rawSentAt = map['sentAt'];
    if (rawSentAt is String) {
      sentAt = DateTime.tryParse(rawSentAt) ?? DateTime.now();
    }

    return FileTransferPayload(
      fileName: sanitizedName,
      mimeType: mimeType,
      fileSizeBytes: size,
      fileContent: content,
      fileEncoding: encoding,
      sentAt: sentAt,
    );
  }

  /// Sanitizes incoming file name to prevent path traversal (`../`) and illegal characters.
  static String _sanitizeFileName(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    cleaned = cleaned.replaceAll('..', '_');
    while (cleaned.startsWith('.') || cleaned.startsWith('_')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.isEmpty) return 'transferred_document.txt';
    return cleaned;
  }
}
