/// High-level audit-log service (Feature 8).
///
/// Sits between the hooks/UI and the repository. Checks the enabled flag,
/// builds timestamps, and wraps every call in a try/catch so the audit log
/// can never break the operation it observes.
library;

import 'package:text_data/core/audit/audit_constants.dart';
import 'package:text_data/core/audit/audit_models.dart';
import 'package:text_data/core/audit/audit_repository.dart';

/// Records events into the tamper-evident audit log.
///
/// Every public method is best-effort: failures are caught and silently
/// discarded. The audit log is a convenience — it must never crash the app or
/// block an operation.
class AuditService {
  final AuditRepository repository;
  final bool enabled;

  AuditService({required this.repository, required this.enabled});

  /// Whether the audit log is currently enabled.
  bool get isEnabled => enabled;

  /// Records a single event. No-op if the audit log is disabled.
  ///
  /// [beforeHash] and [afterHash] are SHA-256 hex strings of the file content
  /// before and after the event, if applicable. They are hashes, never content.
  Future<AuditEntry?> record({
    required String eventType,
    String? fileName,
    String? fileFingerprint,
    String? beforeHash,
    String? afterHash,
    String? detail,
  }) async {
    if (!enabled) return null;
    try {
      return await repository.append(
        eventType: eventType,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        fileName: fileName,
        fileFingerprint: fileFingerprint,
        beforeHash: beforeHash,
        afterHash: afterHash,
        detail: detail,
      );
    } catch (_) {
      // Best effort — see class doc.
      return null;
    }
  }

  /// Verifies the entire chain. Safe to call from the UI.
  Future<AuditVerificationResult> verifyChain() async {
    try {
      return await repository.verifyChain();
    } catch (_) {
      return const AuditVerificationResult.empty();
    }
  }

  /// Paginated entries, newest first.
  Future<List<AuditEntry>> getEntries({int? limit, int? offset}) async {
    try {
      return await repository.getAll(limit: limit, offset: offset);
    } catch (_) {
      return const [];
    }
  }

  /// Total number of entries.
  Future<int> entryCount() async {
    try {
      return await repository.count();
    } catch (_) {
      return 0;
    }
  }

  /// Clears the log and records a "log cleared" event as the new genesis.
  Future<void> clearLog() async {
    try {
      await repository.clear();
      // Record the clear itself as the new first entry.
      await repository.append(
        eventType: AuditEventType.auditCleared,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        detail: 'Audit log cleared by user',
      );
    } catch (_) {
      // Best effort.
    }
  }

  /// Removes all entries for one document. Used by the ephemeral wiper.
  Future<void> clearForFingerprint(String fingerprint) async {
    try {
      await repository.clearForFingerprint(fingerprint);
    } catch (_) {
      // Best effort.
    }
  }

  /// All entries in insertion order, for export.
  Future<List<AuditEntry>> getEntriesForExport({int? limit}) async {
    try {
      return await repository.getAllForExport(limit: limit);
    } catch (_) {
      return const [];
    }
  }
}
