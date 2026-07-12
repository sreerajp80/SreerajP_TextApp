import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shell/settings/security_settings.dart';
import 'app_lock_controller.dart';
import 'app_lock_hasher.dart';
import 'biometric_service.dart';
import 'recovery_code_screen.dart';
import 'set_pin_screen.dart';

/// The unlock screen shown while the app is locked (task 13.2). Offers PIN
/// entry, biometric unlock (if available), and a forgot-PIN recovery flow that
/// ends by forcing a new PIN.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _biometricAvailable = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final allowed = ref
        .read(securitySettingsProvider)
        .biometricUnlockEnabled;
    if (!allowed) return;
    final available =
        await ref.read(appLockControllerProvider.notifier).biometricAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available) _tryBiometric();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _tryPin() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithPin(_pin.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = ok ? null : AppLocalizations.of(context).lockWrongPin;
      if (!ok) _pin.clear();
    });
  }

  Future<void> _tryBiometric() async {
    final result = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithBiometric(AppLocalizations.of(context).lockBiometricReason);
    if (!mounted) return;
    if (result == BiometricResult.unavailable) {
      setState(() => _biometricAvailable = false);
    }
    // On success the controller flips to unlocked and the gate swaps the screen.
  }

  /// Forgot-PIN flow: enter the recovery code, then set a new PIN, then see a
  /// fresh recovery code. Each step is a full screen so it reads clearly.
  Future<void> _forgotPin() async {
    final notifier = ref.read(appLockControllerProvider.notifier);
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _RecoveryCodeEntryDialog(),
    );
    if (code == null || !mounted) return;

    final valid = await notifier.verifyRecoveryCode(code);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!valid) {
      setState(() => _error = l10n.lockRecoveryWrong);
      return;
    }

    final newPin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SetPinScreen(
          title: l10n.lockSetNewPinTitle,
          subtitle: l10n.lockSetNewPinSubtitle,
        ),
      ),
    );
    if (newPin == null || !mounted) return;

    final newRecovery = await notifier.completeRecovery(newPin);
    if (!mounted) return;
    // Show the new recovery code once; then the gate reveals the app (unlocked).
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecoveryCodeScreen(code: newRecovery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.lockEnterPin,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _tryPin(),
                decoration: InputDecoration(
                  labelText: l10n.lockPinLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _tryPin,
                child: Text(l10n.lockUnlock),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.lockUseBiometric),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _forgotPin,
                child: Text(l10n.lockForgotPin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small dialog that collects a typed recovery code.
class _RecoveryCodeEntryDialog extends StatefulWidget {
  const _RecoveryCodeEntryDialog();

  @override
  State<_RecoveryCodeEntryDialog> createState() =>
      _RecoveryCodeEntryDialogState();
}

class _RecoveryCodeEntryDialogState extends State<_RecoveryCodeEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.lockEnterRecoveryTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: l10n.lockRecoveryHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            AppLockHasher.normalizeRecoveryCode(_controller.text),
          ),
          child: Text(l10n.actionContinue),
        ),
      ],
    );
  }
}
