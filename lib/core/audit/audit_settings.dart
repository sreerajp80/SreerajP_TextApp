/// Audit log settings — the on/off flag (Feature 8).
///
/// The setting key uses the `audit` namespace registered in
/// [SettingsNamespaces]. The default is `true` (enabled).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/storage/key_value_store.dart';

/// Manages the audit-log enabled/disabled setting.
class AuditSettings extends Notifier<bool> {
  /// The persisted settings key. Namespace: `audit` (registered in
  /// `app_constants.dart`).
  static const String enabledKey = 'audit.enabled';

  @override
  bool build() {
    final store = ref.watch(keyValueStoreSyncProvider);
    return store.getBool(enabledKey) ?? true; // on by default
  }

  Future<void> setEnabled(bool value) async {
    final store = ref.read(keyValueStoreSyncProvider);
    await store.setBool(enabledKey, value);
    state = value;
  }
}

/// Whether the audit log is enabled. Reads synchronously from settings.
final auditEnabledProvider = NotifierProvider<AuditSettings, bool>(
  AuditSettings.new,
);
