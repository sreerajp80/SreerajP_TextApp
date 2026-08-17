import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/ephemeral/ephemeral_controller.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_models.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_settings.dart';
import 'package:sreerajp_textapp/core/security/app_lock_controller.dart';
import 'package:sreerajp_textapp/core/security/recovery_code_screen.dart';
import 'package:sreerajp_textapp/core/security/set_pin_screen.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/settings/security_settings.dart';
import 'package:sreerajp_textapp/shell/settings/sections/settings_widgets.dart';

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
        const _EphemeralSettingsGroup(),
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

/// Defaults for self-destructing documents, plus a burn-everything action
/// (Feature 9).
///
/// These rows only pre-fill the sheet the user sees when they mark a tab. None
/// of them makes a tab ephemeral on its own — a setting that quietly started
/// destroying documents would be a trap.
class _EphemeralSettingsGroup extends ConsumerWidget {
  const _EphemeralSettingsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final defaults = ref.watch(ephemeralSettingsProvider);
    final settings = ref.read(ephemeralSettingsProvider.notifier);
    final openCount = ref.watch(ephemeralControllerProvider).marks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        SettingsSectionHeader(title: l10n.ephemeralSettingsTitle),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(l10n.ephemeralSettingsDefaultDuration),
          subtitle: Text(_durationLabel(l10n, defaults.duration)),
          onTap: () => _pickDuration(context, settings, defaults.duration),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.local_fire_department_outlined),
          title: Text(l10n.ephemeralSettingsBurnAfterOutput),
          subtitle: Text(l10n.ephemeralSettingsBurnAfterOutputHint),
          value: defaults.burnAfterOutput,
          onChanged: settings.setBurnAfterOutput,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined),
          title: Text(l10n.ephemeralSettingsBurnAll),
          subtitle: Text(l10n.ephemeralSettingsOpenCount(openCount)),
          enabled: openCount > 0,
          onTap: openCount == 0 ? null : () => _burnAll(context, ref),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            l10n.ephemeralSettingsWipeNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDuration(
    BuildContext context,
    EphemeralSettingsController settings,
    EphemeralDuration current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<EphemeralDuration>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final choice in EphemeralDuration.values)
              ListTile(
                title: Text(_durationLabel(l10n, choice)),
                trailing: choice == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(choice),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) settings.setDuration(chosen);
  }

  Future<void> _burnAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(ephemeralControllerProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ephemeralBurnNowTitle),
        content: Text(l10n.ephemeralBurnNowBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionBurn),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Count before burning — the marks are gone by the time it returns.
    final count = ref.read(ephemeralControllerProvider).marks.length;
    await controller.burnAll();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.ephemeralSettingsBurnAllDone(count))),
    );
  }

  String _durationLabel(AppLocalizations l10n, EphemeralDuration choice) {
    return switch (choice) {
      EphemeralDuration.fifteenMinutes => l10n.ephemeralDuration15Minutes,
      EphemeralDuration.oneHour => l10n.ephemeralDuration1Hour,
      EphemeralDuration.fourHours => l10n.ephemeralDuration4Hours,
      EphemeralDuration.twentyFourHours => l10n.ephemeralDuration24Hours,
      EphemeralDuration.custom => l10n.ephemeralDurationCustom,
      EphemeralDuration.none => l10n.ephemeralDurationNone,
    };
  }
}
