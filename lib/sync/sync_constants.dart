// Phase 12 — P2P LAN sync: central home for every tunable and wire literal.
//
// Keeping all of these in one place keeps the host and the client in lockstep
// (they must agree on the alphabet, the crypto sizes, the handshake words, and
// the caps) and makes the security limits auditable at a glance
// (architecture.md §9.2, security-rules).
//
// Nothing here is secret. The pairing code itself is generated at runtime with
// Random.secure() and never stored here or put on the wire.
library;

/// All fixed values the sync engine shares between host and client.
class SyncConstants {
  SyncConstants._();

  // --- Pairing code ---------------------------------------------------------

  /// Alphabet for the human-typed pairing code. It leaves out the look-alike
  /// characters `0 O 1 I L` so a person can read and type it without mistakes.
  static const String codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Number of characters in a pairing code.
  ///
  /// The alphabet has 31 symbols, so each character carries log2(31) ≈ 4.95
  /// bits. 64 characters give ≈ 317 bits of entropy — the ~320 bits the design
  /// asks for (architecture.md §9.1).
  static const int codeLength = 64;

  /// How many characters to group together when showing the code, purely for
  /// readability (e.g. `ABCD-EFGH-...`). Grouping does not change the code.
  static const int codeDisplayGroup = 4;

  // --- Key derivation (PBKDF2-HMAC-SHA256) ----------------------------------

  /// PBKDF2 iteration count. High enough to slow a brute-force guess of the
  /// code, low enough to derive in well under a second on a phone.
  static const int pbkdf2Iterations = 200000;

  /// Length of the per-session random salt, in bytes. A salt is not secret and
  /// is sent in the clear (architecture.md §9.1).
  static const int saltLength = 16;

  /// Derived AES key length in bytes (256-bit key → AES-256).
  static const int keyLengthBytes = 32;

  // --- AES-256-GCM ----------------------------------------------------------

  /// GCM nonce (IV) length in bytes. 12 bytes is the standard GCM nonce size.
  static const int gcmNonceLength = 12;

  // --- Handshake words ------------------------------------------------------
  // These travel AES-GCM sealed (except where noted). A wrong code cannot even
  // read them, because decryption fails first.

  /// Client → host: proves the client derived the same key from the code.
  static const String helloSync = 'HELLO_SYNC';

  /// Host → client: sent immediately on a good HELLO — "you are connected".
  static const String acceptSync = 'ACCEPT_SYNC';

  /// Host → client: sent in the clear when the HELLO could not be decrypted
  /// (wrong code). Carries no secret and lets the client fail fast.
  static const String denied = 'DENIED';

  // --- Bounded reads (DoS guards) ------------------------------------------

  /// Longest handshake line we will buffer, in bytes. The handshake lines
  /// (salt, HELLO, ACCEPT) are tiny; this cap stops a giant-line / slow-loris
  /// attack during the handshake.
  static const int handshakeLineCap = 8 * 1024; // 8 KB

  /// Longest payload line we will buffer, in bytes. The payload is one sealed
  /// line; this is the hard ceiling on how much we will read for it.
  static const int payloadLineCap = 16 * 1024 * 1024; // 16 MB

  // --- Payload caps (validate before ingestion) -----------------------------

  /// Most records we accept per category in one payload.
  static const int maxRecordsPerCategory = 100000;

  /// Longest single string field we accept inside a record, in characters.
  static const int maxFieldLength = 64 * 1024; // 64k chars

  /// Most allow-listed settings entries we accept in one payload.
  static const int maxSettingsEntries = 500;

  // --- Timeouts -------------------------------------------------------------

  /// How long the client waits for the TCP connection to open.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// How long we wait for one handshake line to arrive.
  static const Duration socketTimeout = Duration(seconds: 30);

  /// How long the client waits for the sender to choose data and push the
  /// payload. This is deliberately long because a person is picking on the
  /// other device (architecture.md §9.3).
  static const Duration payloadWaitTimeout = Duration(minutes: 10);

  // --- QR URI ---------------------------------------------------------------

  /// URI scheme for the pairing QR. A foreign QR with a different scheme is
  /// rejected by the parser.
  static const String qrScheme = 'textdatasync';

  /// URI host segment (`scheme://host`). Version-checked on parse.
  static const String qrHost = 'pair';

  /// Wire/QR version. Bump when the handshake or payload shape changes in a way
  /// old clients cannot read.
  static const int protocolVersion = 1;

  // --- TCP port -------------------------------------------------------------
  // The port is conflict-avoidance only, never a security boundary
  // (architecture.md §9.1). The host binds an ephemeral port and advertises it.

  /// Lowest port we will try to bind if picking a fixed port is ever needed.
  static const int portRangeStart = 45000;

  /// Highest port in that range.
  static const int portRangeEnd = 45999;

  // --- Payload shape keys ---------------------------------------------------

  static const String keyApp = 'app';
  static const String keyPayloadVersion = 'payloadVersion';
  static const String keySyncMode = 'syncMode';
  static const String keyRecords = 'records';
  static const String keySettings = 'settings';

  /// The value of the `app` field — lets the receiver reject a payload from a
  /// different app even though the transport is app-agnostic.
  static const String appId = 'text_data';

  /// Current payload version (independent of the wire [protocolVersion]).
  static const int payloadVersion = 1;

  // --- Sync modes -----------------------------------------------------------

  static const String syncModeFull = 'full';
  static const String syncModeIncremental = 'incremental';

  // --- Category keys --------------------------------------------------------

  static const String categoryFavorites = 'favorites';
  static const String categoryBookmarks = 'bookmarks';
  static const String categoryRecents = 'recents';

  /// All record categories the app can sync.
  static const List<String> allCategories = [
    categoryFavorites,
    categoryBookmarks,
    categoryRecents,
  ];

  // --- Syncable settings allow-list -----------------------------------------
  // Only these non-sensitive preference keys may cross the wire. A key that is
  // not in this set is NEVER synced. Security/identity keys (device_key,
  // app_lock_pin, …) are excluded here AND live in secure storage, so they can
  // never reach a payload (security-rules).
  //
  // These MUST be the real namespaced storage keys the settings controllers
  // read and write (e.g. `appearance.theme_mode`, not a bare `theme_mode`).
  // A bare key here would match nothing in the store, so nothing would sync.
  static const Set<String> syncableSettingKeys = {
    // Appearance (ThemeSettings.*Key)
    'appearance.theme_mode',
    'appearance.font_scale',
    'appearance.font_family',
    'appearance.line_spacing',
    'appearance.word_wrap',
    // Tabs (TabsPersistence / TabsController). cap_mode travels with fixed_cap
    // so a synced fixed cap actually takes effect on the receiver.
    'tabs.restore_on_relaunch',
    'tabs.over_limit',
    'tabs.fixed_cap',
    'tabs.cap_mode',
    // Speech (TtsSettings.*Key)
    'tts.english_enabled',
    'tts.malayalam_enabled',
  };

  /// Secure-storage keys that must never appear in a payload, listed for the
  /// belt-and-braces guard in [payload]. This mirrors
  /// `KeyValueStore.defaultSensitiveKeys`.
  static const Set<String> neverSyncKeys = {
    'device_key',
    'app_lock_pin',
    'app_lock_recovery',
  };

  /// Secure-storage key that holds this device's own P2P key. Generated once
  /// with Random.secure(); never synced, never logged.
  static const String deviceKeyStorageKey = 'device_key';
}
