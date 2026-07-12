import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Collects a new app-lock PIN (enter + confirm). Pops the chosen PIN string on
/// success, or null if the user backs out. Used when enabling app-lock, changing
/// the PIN, and finishing a recovery (task 13.2).
///
/// [title] / [subtitle] are optional overrides; when null the localized defaults
/// (`setPinTitle` / `setPinSubtitle`) are used.
class SetPinScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;

  const SetPinScreen({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  static const int _minLength = 4;
  static const int _maxLength = 12;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final pin = _pin.text;
    if (pin.length < _minLength) {
      setState(() => _error = l10n.setPinTooShort(_minLength));
      return;
    }
    if (pin != _confirm.text) {
      setState(() => _error = l10n.setPinMismatch);
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l10n.setPinTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.subtitle ?? l10n.setPinSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: _maxLength,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.lockPinLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: _maxLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.setPinConfirmLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: Text(l10n.setPinSave),
          ),
        ],
      ),
    );
  }
}
