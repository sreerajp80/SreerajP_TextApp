import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_lock_controller.dart';
import '../../../core/security/recovery_code_screen.dart';
import '../../../core/security/set_pin_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../security_settings.dart';
import 'settings_widgets.dart';

/// Security settings (tasks 11.6 + 13.2). The toggles are now enforced:
/// app-lock gates the app on launch/resume (PIN + optional biometric, with a
/// recovery code), and screenshot protection sets `FLAG_SECURE`.
class SecuritySection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const SecuritySection({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(securitySettingsProvider);
    final controller = ref.read(securitySettingsProvider.notifier);
    final appLock = ref.read(appLockControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SettingsSectionHeader(title: l10n.securitySectionTitle),
        SwitchListTile(
          title: Text(l10n.securityAppLockTitle),
          subtitle: Text(l10n.securityAppLockSubtitle),
          value: settings.appLockEnabled,
          onChanged: (value) => _onAppLockChanged(context, ref, value),
        ),
        if (settings.appLockEnabled) ...[
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(l10n.securityChangePin),
            onTap: () => _changePin(context, appLock),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: Text(l10n.securityShowNewRecovery),
            subtitle: Text(l10n.securityShowNewRecoverySubtitle),
            onTap: () => _regenerateRecovery(context, appLock),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text(l10n.securityBiometricTitle),
            subtitle: Text(l10n.securityBiometricSubtitle),
            value: settings.biometricUnlockEnabled,
            onChanged: controller.setBiometricUnlockEnabled,
          ),
        ],
        SwitchListTile(
          title: Text(l10n.securityScreenshotTitle),
          subtitle: Text(l10n.securityScreenshotSubtitle),
          value: settings.screenshotProtection,
          onChanged: controller.setScreenshotProtection,
        ),
      ],
    );
  }

  Future<void> _onAppLockChanged(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final appLock = ref.read(appLockControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    if (value) {
      // Turning on: choose a PIN, then show the recovery code once.
      final pin = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => SetPinScreen(
            title: l10n.securitySetPinTitle,
            subtitle: l10n.securitySetPinSubtitle,
          ),
        ),
      );
      if (pin == null || !context.mounted) return;
      final recovery = await appLock.enableWithNewPin(pin);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecoveryCodeScreen(code: recovery)),
      );
    } else {
      // Turning off: confirm, then clear the stored secrets.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.securityTurnOffTitle),
          content: Text(l10n.securityTurnOffBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.securityTurnOff),
            ),
          ],
        ),
      );
      if (confirmed == true) await appLock.disableAppLock();
    }
  }

  Future<void> _changePin(
    BuildContext context,
    AppLockController appLock,
  ) async {
    final l10n = AppLocalizations.of(context);
    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SetPinScreen(title: l10n.securityChangePin),
      ),
    );
    if (pin == null || !context.mounted) return;
    await appLock.changePin(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.securityPinChanged),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _regenerateRecovery(
    BuildContext context,
    AppLockController appLock,
  ) async {
    final recovery = await appLock.regenerateRecoveryCode();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecoveryCodeScreen(code: recovery)),
    );
  }
}
