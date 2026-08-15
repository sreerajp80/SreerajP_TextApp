import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:text_data/core/vault/vault_constants.dart';

/// The decrypted contents and metadata stored inside a `.txvault` envelope.
@immutable
class VaultPayload {
  final String originalFileName;
  final String mimeType;
  final String encoding;
  final String content;
  final DateTime createdAt;

  const VaultPayload({
    required this.originalFileName,
    required this.mimeType,
    required this.encoding,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'appId': VaultConstants.appId,
    'version': VaultConstants.formatVersion,
    'originalFileName': originalFileName,
    'mimeType': mimeType,
    'encoding': encoding,
    'content': content,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory VaultPayload.fromJson(Map<String, dynamic> json) {
    return VaultPayload(
      originalFileName: json['originalFileName'] as String? ?? 'document.txt',
      mimeType: json['mimeType'] as String? ?? 'text/plain',
      encoding: json['encoding'] as String? ?? 'utf-8',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toWireJson() => jsonEncode(toJson());

  factory VaultPayload.fromWireJson(String wireJson) {
    final decoded = jsonDecode(wireJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid vault payload JSON structure');
    }
    return VaultPayload.fromJson(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultPayload &&
          runtimeType == other.runtimeType &&
          originalFileName == other.originalFileName &&
          mimeType == other.mimeType &&
          encoding == other.encoding &&
          content == other.content &&
          createdAt.millisecondsSinceEpoch ==
              other.createdAt.millisecondsSinceEpoch;

  @override
  int get hashCode => Object.hash(
    originalFileName,
    mimeType,
    encoding,
    content,
    createdAt.millisecondsSinceEpoch,
  );
}
