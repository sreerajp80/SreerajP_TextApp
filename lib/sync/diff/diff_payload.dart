import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:text_data/sync/sync_constants.dart';

/// Thrown when a diff session payload is invalid or malformed.
class DiffPayloadException implements Exception {
  final String message;
  const DiffPayloadException(this.message);

  @override
  String toString() => 'DiffPayloadException: $message';
}

/// Action types for P2P Live Diff wire protocol.
enum DiffPayloadAction { init, offer, deltaUpdate, resolveHunk, ack, close }

/// A parsed and validated payload for bidirectional P2P live diff sessions.
@immutable
class DiffSessionPayload {
  final DiffPayloadAction action;
  final String sessionId;
  final String fileName;
  final String mimeType;
  final String content;
  final String? hunkId;
  final String? resolution;
  final DateTime sentAt;

  const DiffSessionPayload({
    required this.action,
    required this.sessionId,
    required this.fileName,
    required this.mimeType,
    required this.content,
    this.hunkId,
    this.resolution,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    SyncConstants.keyApp: SyncConstants.appId,
    SyncConstants.keyPayloadVersion: SyncConstants.payloadVersion,
    SyncConstants.keyPayloadType: SyncConstants.payloadTypeDiffSession,
    'action': action.name,
    'sessionId': sessionId,
    SyncConstants.keyFileName: fileName,
    SyncConstants.keyMimeType: mimeType,
    'content': content,
    if (hunkId != null) 'hunkId': hunkId,
    if (resolution != null) 'resolution': resolution,
    'sentAt': sentAt.toUtc().toIso8601String(),
  };

  String toWireJson() => jsonEncode(toJson());

  /// Builds a [DiffSessionPayload] with security limits.
  static DiffSessionPayload build({
    required DiffPayloadAction action,
    required String sessionId,
    required String fileName,
    String mimeType = 'text/plain',
    String content = '',
    String? hunkId,
    String? resolution,
  }) {
    final sanitizedName = _sanitizeFileName(fileName);
    final size = utf8.encode(content).length;

    if (size > SyncConstants.maxFileTransferBytes) {
      throw const DiffPayloadException(
        'Document content exceeds transfer size limit.',
      );
    }

    return DiffSessionPayload(
      action: action,
      sessionId: sessionId,
      fileName: sanitizedName,
      mimeType: mimeType,
      content: content,
      hunkId: hunkId,
      resolution: resolution,
      sentAt: DateTime.now(),
    );
  }

  /// Parses and validates received JSON string.
  static DiffSessionPayload validateAndParse(String jsonString) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw const DiffPayloadException('Invalid JSON payload.');
    }

    if (decoded is! Map<String, dynamic> && decoded is! Map<String, Object?>) {
      throw const DiffPayloadException('Malformed payload structure.');
    }

    final map = decoded as Map<String, Object?>;

    if (map[SyncConstants.keyApp] != SyncConstants.appId) {
      throw const DiffPayloadException('Payload from different application.');
    }

    final type = map[SyncConstants.keyPayloadType];
    if (type != SyncConstants.payloadTypeDiffSession) {
      throw const DiffPayloadException('Not a diff session payload.');
    }

    final rawAction = map['action'];
    if (rawAction is! String) {
      throw const DiffPayloadException('Missing or invalid action.');
    }

    final action = DiffPayloadAction.values.firstWhere(
      (a) => a.name == rawAction,
      orElse: () => DiffPayloadAction.deltaUpdate,
    );

    final sessionId = (map['sessionId'] as String?) ?? 'default_session';
    final fileName = _sanitizeFileName(
      (map[SyncConstants.keyFileName] as String?) ?? 'document.txt',
    );
    final mimeType =
        (map[SyncConstants.keyMimeType] as String?) ?? 'text/plain';
    final content = (map['content'] as String?) ?? '';

    final size = utf8.encode(content).length;
    if (size > SyncConstants.maxFileTransferBytes) {
      throw const DiffPayloadException('Content size exceeds safety limits.');
    }

    DateTime sentAt = DateTime.now();
    final rawSentAt = map['sentAt'];
    if (rawSentAt is String) {
      sentAt = DateTime.tryParse(rawSentAt) ?? DateTime.now();
    }

    return DiffSessionPayload(
      action: action,
      sessionId: sessionId,
      fileName: fileName,
      mimeType: mimeType,
      content: content,
      hunkId: map['hunkId'] as String?,
      resolution: map['resolution'] as String?,
      sentAt: sentAt,
    );
  }

  static String _sanitizeFileName(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    cleaned = cleaned.replaceAll('..', '_');
    while (cleaned.startsWith('.') || cleaned.startsWith('_')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.isEmpty) return 'document.txt';
    return cleaned;
  }
}
