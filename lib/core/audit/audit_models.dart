/// Immutable models for the tamper-evident audit log (Feature 8).
library;

/// One row in the `audit_log` table.
///
/// Immutable with a `copyWith` for the rare case a test needs to tweak a field.
/// The [entryHash] and [previousHash] together form the SHA-256 chain that makes
/// tampering detectable.
class AuditEntry {
  /// Auto-incremented row id (null before insertion).
  final int? id;

  /// What happened — one of the [AuditEventType] constants.
  final String eventType;

  /// Unix milliseconds when the event was recorded.
  final int timestamp;

  /// Display name of the affected file, if any.
  final String? fileName;

  /// [ContentFingerprint.key] of the affected file, if any.
  final String? fileFingerprint;

  /// SHA-256 hex of the file content *before* the event (nullable).
  final String? beforeHash;

  /// SHA-256 hex of the file content *after* the event (nullable).
  final String? afterHash;

  /// Short human-readable detail (e.g. 'exported as PDF').
  final String? detail;

  /// SHA-256 of the concatenation of [previousHash] and this entry's fields.
  /// This is what the next entry chains from.
  final String entryHash;

  /// The [entryHash] of the entry immediately before this one in the chain.
  /// For the first entry (or after a clear), this is [AuditConstants.genesisHash].
  final String previousHash;

  const AuditEntry({
    this.id,
    required this.eventType,
    required this.timestamp,
    this.fileName,
    this.fileFingerprint,
    this.beforeHash,
    this.afterHash,
    this.detail,
    required this.entryHash,
    required this.previousHash,
  });

  AuditEntry copyWith({
    int? id,
    String? eventType,
    int? timestamp,
    String? fileName,
    String? fileFingerprint,
    String? beforeHash,
    String? afterHash,
    String? detail,
    String? entryHash,
    String? previousHash,
  }) {
    return AuditEntry(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      fileName: fileName ?? this.fileName,
      fileFingerprint: fileFingerprint ?? this.fileFingerprint,
      beforeHash: beforeHash ?? this.beforeHash,
      afterHash: afterHash ?? this.afterHash,
      detail: detail ?? this.detail,
      entryHash: entryHash ?? this.entryHash,
      previousHash: previousHash ?? this.previousHash,
    );
  }

  /// Builds an [AuditEntry] from a SQLite row map.
  factory AuditEntry.fromRow(Map<String, dynamic> row) {
    return AuditEntry(
      id: row['id'] as int?,
      eventType: row['event_type'] as String,
      timestamp: row['timestamp'] as int,
      fileName: row['file_name'] as String?,
      fileFingerprint: row['file_fingerprint'] as String?,
      beforeHash: row['before_hash'] as String?,
      afterHash: row['after_hash'] as String?,
      detail: row['detail'] as String?,
      entryHash: row['entry_hash'] as String,
      previousHash: row['previous_hash'] as String,
    );
  }

  /// Converts to a map suitable for `db.insert`.
  Map<String, dynamic> toRow() {
    return {
      if (id != null) 'id': id,
      'event_type': eventType,
      'timestamp': timestamp,
      'file_name': fileName,
      'file_fingerprint': fileFingerprint,
      'before_hash': beforeHash,
      'after_hash': afterHash,
      'detail': detail,
      'entry_hash': entryHash,
      'previous_hash': previousHash,
    };
  }

  /// Converts to a JSON-friendly map for export.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventType': eventType,
      'timestamp': timestamp,
      if (fileName != null) 'fileName': fileName,
      if (fileFingerprint != null) 'fileFingerprint': fileFingerprint,
      if (beforeHash != null) 'beforeHash': beforeHash,
      if (afterHash != null) 'afterHash': afterHash,
      if (detail != null) 'detail': detail,
      'entryHash': entryHash,
      'previousHash': previousHash,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AuditEntry && other.id == id && other.entryHash == entryHash;

  @override
  int get hashCode => Object.hash(id, entryHash);

  @override
  String toString() =>
      'AuditEntry(id=$id, type=$eventType, hash=${entryHash.substring(0, 8)}…)';
}

/// The result of verifying the audit chain's integrity.
enum AuditChainStatus {
  /// Every entry's hash matches its recomputed value and chains correctly.
  verified,

  /// At least one entry's hash does not match — the log was tampered with.
  corrupted,

  /// The log is empty (no entries to verify).
  empty,
}

/// The full result of a chain verification, including the point of corruption.
class AuditVerificationResult {
  final AuditChainStatus status;

  /// The `id` of the first entry whose hash does not match. Null when the
  /// chain is [AuditChainStatus.verified] or [AuditChainStatus.empty].
  final int? corruptedEntryId;

  /// The 1-based position of the corrupted entry in the chain, for user display.
  final int? corruptedEntryIndex;

  /// Total number of entries verified.
  final int totalEntries;

  const AuditVerificationResult({
    required this.status,
    this.corruptedEntryId,
    this.corruptedEntryIndex,
    required this.totalEntries,
  });

  const AuditVerificationResult.verified(this.totalEntries)
    : status = AuditChainStatus.verified,
      corruptedEntryId = null,
      corruptedEntryIndex = null;

  const AuditVerificationResult.empty()
    : status = AuditChainStatus.empty,
      corruptedEntryId = null,
      corruptedEntryIndex = null,
      totalEntries = 0;

  bool get isVerified => status == AuditChainStatus.verified;
  bool get isCorrupted => status == AuditChainStatus.corrupted;
  bool get isEmpty => status == AuditChainStatus.empty;
}
