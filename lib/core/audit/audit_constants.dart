/// Constants for the tamper-evident workspace audit log (Feature 8).
///
/// Event type identifiers, the genesis hash, and the settings key live here so
/// every part of the audit system uses the same literals. Following the project
/// convention, the settings key itself is declared on its owning class
/// ([AuditSettings]), not here — only the event-type strings are centralised
/// because they are used across many call sites (hooks, repository, UI).
library;

/// The types of events the audit log captures.
///
/// Each value is a short, stable string stored in the `event_type` column of
/// the `audit_log` table. Do not rename an existing value — it would silently
/// break chain verification on logs that contain the old name.
class AuditEventType {
  const AuditEventType._();

  static const String fileOpen = 'file_open';
  static const String fileSave = 'file_save';
  static const String fileExport = 'file_export';
  static const String filePrint = 'file_print';
  static const String fileShare = 'file_share';
  static const String p2pSyncSend = 'p2p_sync_send';
  static const String p2pSyncReceive = 'p2p_sync_receive';
  static const String airqrSend = 'airqr_send';
  static const String airqrReceive = 'airqr_receive';
  static const String securityPinChange = 'security_pin_change';
  static const String securityLockToggle = 'security_lock_toggle';
  static const String fileBurn = 'file_burn';
  static const String auditCleared = 'audit_cleared';

  /// All known event types, for the UI filter and for validation.
  static const List<String> all = [
    fileOpen,
    fileSave,
    fileExport,
    filePrint,
    fileShare,
    p2pSyncSend,
    p2pSyncReceive,
    airqrSend,
    airqrReceive,
    securityPinChange,
    securityLockToggle,
    fileBurn,
    auditCleared,
  ];
}

/// Technical constants for the audit chain.
class AuditConstants {
  const AuditConstants._();

  /// The `previous_hash` of the very first entry in the chain (or after a
  /// clear). 64 hex zeros = the SHA-256-sized "nothing came before" marker.
  static const String genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  /// Maximum entries returned in a single page of the audit log screen.
  static const int pageSize = 50;

  /// Field separator used inside the hash preimage so that fields cannot be
  /// shifted across boundaries ('a|b' vs 'ab|').
  static const String hashSeparator = '|';
}
