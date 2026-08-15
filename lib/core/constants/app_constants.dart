/// Cross-cutting technical constants. Values only — no logic, no imports.
///
/// This file is deliberately small. Most technical constants in this app live
/// next to the code that uses them, because separating a value from its parsing
/// and default makes both harder to change safely:
///
/// * Settings keys live on the settings class that owns them
///   (for example `EditorSettings.autoSaveSecondsKey`).
/// * Sync protocol constants live in `lib/sync/sync_constants.dart`.
/// * Size and threshold values live with their policy
///   (for example `LargeFilePolicy.largeThresholdBytes`).
///
/// What belongs *here* is the one thing no single feature owns: the registry of
/// settings-key namespaces. Two features could otherwise pick the same key
/// string and silently overwrite each other's value. See
/// `docs/project_structure.md` for the rule.
library;

/// The namespaces used by persisted settings keys, and the registry that keeps
/// them unique.
///
/// A persisted settings key is written as `<namespace>.<name>`, in
/// `lower_snake_case`. Before adding a key:
///
/// 1. Use one of the namespaces below, or add a new one here first.
/// 2. Declare the key as a `static const String` on the class that owns it —
///    not here.
///
/// `test/core/constants/app_constants_test.dart` checks that every key in the
/// app uses a registered namespace and that no two keys collide.
class SettingsNamespaces {
  const SettingsNamespaces._();

  /// Theme, fonts, language, and text layout.
  static const String appearance = 'appearance';

  /// Editor behaviour — encoding, line endings, auto-save, read-only.
  static const String editor = 'editor';

  /// Defaults for self-destructing (ephemeral) documents (Feature 9).
  ///
  /// Only the sheet's pre-filled choices live here. The marks themselves are
  /// never persisted: a stored mark would be a record of the very document the
  /// user asked the app to forget.
  static const String ephemeral = 'ephemeral';

  /// Markdown split-view state.
  static const String markdownSplit = 'md.split';

  /// First-run onboarding.
  static const String onboarding = 'onboarding';

  /// App lock, biometrics, screenshot protection.
  ///
  /// Note: these are *flags* about whether a feature is on. The secrets
  /// themselves never go in settings — they go to `SecureStore` (see below).
  static const String security = 'security';

  /// Open tabs and the tab limit.
  static const String tabs = 'tabs';

  /// Text-to-speech per-language enablement.
  static const String tts = 'tts';

  /// Tamper-evident workspace audit log (Feature 8).
  static const String audit = 'audit';

  /// Every namespace above. Add a new namespace here when you add one.
  static const Set<String> all = {
    appearance,
    editor,
    ephemeral,
    markdownSplit,
    onboarding,
    security,
    tabs,
    tts,
    audit,
  };
}

/// Keys held in `SecureStore` (Android Keystore via `flutter_secure_storage`).
///
/// These are **not** settings and carry no namespace prefix — they are listed
/// here only so the full set of persisted key strings is visible in one place
/// and cannot collide. Each is declared on its owning class; this is the
/// registry, not the definition.
///
/// * `app_lock_pin`      — `AppLockRepository.pinKey`
/// * `app_lock_recovery` — `AppLockRepository.recoveryKey`
/// * `device_key`        — `SyncConstants.deviceKeyStorageKey`
class SecureStoreKeys {
  const SecureStoreKeys._();

  /// Every secure-storage key string the app persists.
  static const Set<String> all = {
    'app_lock_pin',
    'app_lock_recovery',
    'device_key',
    'audit_export_key',
  };
}
