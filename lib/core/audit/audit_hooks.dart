/// Static best-effort helpers that the open, save, export, sync, and security
/// flows call to record events in the audit log (Feature 8).
///
/// Follows the same pattern as [WorkspaceIndexHooks]: every call is
/// fire-and-forget, swallows all exceptions, and takes the service as a future
/// plus the enabled flag so callers can read both from whichever kind of
/// Riverpod ref they hold.
library;

import 'package:text_data/core/audit/audit_constants.dart';
import 'package:text_data/core/audit/audit_service.dart';

/// Best-effort audit-log recording helpers.
///
/// Each method maps to one [AuditEventType]. The [service] future and [enabled]
/// flag are accepted as parameters (not read from a global) so test doubles can
/// be injected trivially.
class AuditHooks {
  const AuditHooks._();

  // ---------------------------------------------------------------------------
  // File lifecycle
  // ---------------------------------------------------------------------------

  static Future<void> onFileOpened({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
    String? contentHash,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.fileOpen,
        fileName: fileName,
        fileFingerprint: fingerprint,
        afterHash: contentHash,
        detail: 'Opened',
      );
    } catch (_) {}
  }

  static Future<void> onFileSaved({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
    String? beforeHash,
    String? afterHash,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.fileSave,
        fileName: fileName,
        fileFingerprint: fingerprint,
        beforeHash: beforeHash,
        afterHash: afterHash,
        detail: 'Saved',
      );
    } catch (_) {}
  }

  static Future<void> onFileExported({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
    required String exportFormat,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.fileExport,
        fileName: fileName,
        fileFingerprint: fingerprint,
        detail: 'Exported as $exportFormat',
      );
    } catch (_) {}
  }

  static Future<void> onFilePrinted({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.filePrint,
        fileName: fileName,
        fileFingerprint: fingerprint,
        detail: 'Printed',
      );
    } catch (_) {}
  }

  static Future<void> onFileShared({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.fileShare,
        fileName: fileName,
        fileFingerprint: fingerprint,
        detail: 'Shared',
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  static Future<void> onSyncSent({
    required Future<AuditService> service,
    required bool enabled,
    String? detail,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.p2pSyncSend,
        detail: detail ?? 'P2P sync data sent',
      );
    } catch (_) {}
  }

  static Future<void> onSyncReceived({
    required Future<AuditService> service,
    required bool enabled,
    String? detail,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.p2pSyncReceive,
        detail: detail ?? 'P2P sync data received',
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // AirQR
  // ---------------------------------------------------------------------------

  static Future<void> onAirqrSent({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.airqrSend,
        fileName: fileName,
        fileFingerprint: fingerprint,
        detail: 'Sent via AirQR',
      );
    } catch (_) {}
  }

  static Future<void> onAirqrReceived({
    required Future<AuditService> service,
    required bool enabled,
    String? fileName,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.airqrReceive,
        fileName: fileName,
        detail: 'Received via AirQR',
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Security
  // ---------------------------------------------------------------------------

  static Future<void> onSecurityEvent({
    required Future<AuditService> service,
    required bool enabled,
    required String eventType,
    String? detail,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(eventType: eventType, detail: detail);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Ephemeral
  // ---------------------------------------------------------------------------

  static Future<void> onFileBurned({
    required Future<AuditService> service,
    required bool enabled,
    required String fileName,
    required String fingerprint,
  }) async {
    if (!enabled) return;
    try {
      final s = await service;
      await s.record(
        eventType: AuditEventType.fileBurn,
        fileName: fileName,
        fileFingerprint: fingerprint,
        detail: 'Document burned (ephemeral)',
      );
    } catch (_) {}
  }
}
