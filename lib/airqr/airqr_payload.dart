// Phase 18 — Optical air-gap transfer (AirQR): the payload envelope.
//
// The envelope is what actually travels: what kind of thing this is, what to
// call it, and the text itself. It is JSON so a future version can add fields
// without breaking an older receiver.
//
// EVERY received envelope is treated as hostile (CLAUDE.md §3 rule 4,
// security-rules). [validateAndParse] checks the app id, the version, the kind,
// and every cap BEFORE the content reaches the UI or a file. A bad envelope
// produces a user-safe message, never a crash and never a stack trace on screen.
//
// Nothing here logs envelope content.
library;

import 'dart:convert';

import 'package:sreerajp_textapp/airqr/airqr_constants.dart';

/// Thrown when an envelope is malformed or breaks a cap. The message is
/// user-safe and carries no payload content.
class AirqrPayloadException implements Exception {
  final String message;
  const AirqrPayloadException(this.message);
  @override
  String toString() => 'AirqrPayloadException: $message';
}

/// One thing being transferred: a snippet of text, or a whole document.
class AirqrPayload {
  /// [AirqrConstants.kindSnippet] or [AirqrConstants.kindDocument].
  final String kind;

  /// Suggested file name for a document, or a short label for a snippet. The
  /// receiver may change it — for a document it is only the name pre-filled in
  /// the SAF save dialog, never a path.
  final String name;

  /// MIME type, used to pre-select the format on the receiving side.
  final String mime;

  /// The text itself.
  final String content;

  const AirqrPayload({
    required this.kind,
    required this.name,
    required this.mime,
    required this.content,
  });

  bool get isSnippet => kind == AirqrConstants.kindSnippet;
  bool get isDocument => kind == AirqrConstants.kindDocument;

  Map<String, Object?> toJson() => {
    AirqrConstants.envelopeApp: AirqrConstants.appId,
    AirqrConstants.envelopeVersion: AirqrConstants.payloadVersion,
    AirqrConstants.envelopeKind: kind,
    AirqrConstants.envelopeName: name,
    AirqrConstants.envelopeMime: mime,
    AirqrConstants.envelopeContent: content,
  };

  /// The bytes that get compressed, sealed, and split into frames.
  List<int> toWireBytes() => utf8.encode(jsonEncode(toJson()));

  /// Builds an outgoing payload, checking the caps before any work is done so
  /// an oversized transfer fails immediately rather than after compression.
  static AirqrPayload build({
    required String kind,
    required String name,
    required String mime,
    required String content,
  }) {
    if (!AirqrConstants.allKinds.contains(kind)) {
      throw AirqrPayloadException('Unknown transfer type: $kind');
    }
    if (content.isEmpty) {
      throw const AirqrPayloadException('There is nothing to send.');
    }
    final cleanName = _sanitizeName(name);
    final size = utf8.encode(content).length;
    if (size > AirqrConstants.hardCapBytes) {
      throw const AirqrPayloadException(
        'This is too large to send by QR code. Use LAN sync instead.',
      );
    }
    return AirqrPayload(
      kind: kind,
      name: cleanName,
      mime: mime,
      content: content,
    );
  }

  /// Parses a received envelope, treating it as hostile.
  static AirqrPayload validateAndParse(String json) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw const AirqrPayloadException('The received data was not valid.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AirqrPayloadException(
        'The received data had the wrong shape.',
      );
    }
    final map = decoded;

    if (map[AirqrConstants.envelopeApp] != AirqrConstants.appId) {
      throw const AirqrPayloadException('This data is from a different app.');
    }
    final version = map[AirqrConstants.envelopeVersion];
    if (version is! int || version > AirqrConstants.payloadVersion) {
      throw const AirqrPayloadException(
        'This data is a newer, unsupported version.',
      );
    }
    final kind = map[AirqrConstants.envelopeKind];
    if (kind is! String || !AirqrConstants.allKinds.contains(kind)) {
      throw const AirqrPayloadException(
        'The data has an unknown transfer type.',
      );
    }
    final content = map[AirqrConstants.envelopeContent];
    if (content is! String) {
      throw const AirqrPayloadException('The data had no readable content.');
    }
    if (utf8.encode(content).length > AirqrConstants.hardCapBytes) {
      throw const AirqrPayloadException('The received data was too large.');
    }

    final rawName = map[AirqrConstants.envelopeName];
    final rawMime = map[AirqrConstants.envelopeMime];
    return AirqrPayload(
      kind: kind,
      name: _sanitizeName(rawName is String ? rawName : ''),
      mime: rawMime is String && rawMime.isNotEmpty ? rawMime : 'text/plain',
      content: content,
    );
  }

  /// Strips anything that could turn a suggested name into a path, and caps the
  /// length. A sender is not trusted to pick where a file lands — the receiver
  /// always chooses through its own SAF picker, and this is the second guard.
  static String _sanitizeName(String raw) {
    final flattened = raw
        .replaceAll(RegExp(r'[\\/\x00-\x1f]'), '')
        .replaceAll('..', '')
        .trim();
    if (flattened.isEmpty) return 'received.txt';
    return flattened.length > AirqrConstants.maxNameLength
        ? flattened.substring(0, AirqrConstants.maxNameLength)
        : flattened;
  }
}
