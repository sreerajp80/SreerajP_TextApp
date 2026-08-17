import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sreerajp_textapp/core/ephemeral/ephemeral_models.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Asks the user how a tab should self-destruct (Feature 9).
///
/// Returns the chosen [EphemeralOption], or null if the user backed out.
/// [fileName] is null when the user has not chosen a file yet — the
/// "open as self-destructing" flow asks for the settings first, then opens the
/// system picker.
Future<EphemeralOption?> showEphemeralSheet(
  BuildContext context, {
  String? fileName,
  EphemeralOption initial = const EphemeralOption(),
}) {
  return showModalBottomSheet<EphemeralOption>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _EphemeralSheet(fileName: fileName, initial: initial),
  );
}

class _EphemeralSheet extends StatefulWidget {
  final String? fileName;
  final EphemeralOption initial;

  const _EphemeralSheet({required this.fileName, required this.initial});

  @override
  State<_EphemeralSheet> createState() => _EphemeralSheetState();
}

class _EphemeralSheetState extends State<_EphemeralSheet> {
  late EphemeralOption _option = widget.initial;
  late final TextEditingController _customMinutes = TextEditingController(
    text: widget.initial.customMinutes.toString(),
  );

  /// Choices in the order they are offered. "No timer" sits last because it is
  /// only useful together with burn-after-export.
  static const List<EphemeralDuration> _choices = [
    EphemeralDuration.fifteenMinutes,
    EphemeralDuration.oneHour,
    EphemeralDuration.fourHours,
    EphemeralDuration.twentyFourHours,
    EphemeralDuration.custom,
    EphemeralDuration.none,
  ];

  @override
  void dispose() {
    _customMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                l10n.ephemeralSheetTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (widget.fileName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  widget.fileName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.fileName == null) const SizedBox(height: 8),

            // The two things the user most needs to know before agreeing.
            _Note(
              icon: Icons.cleaning_services_outlined,
              text: l10n.ephemeralSheetWhatIsWiped,
            ),
            _Note(
              icon: Icons.folder_outlined,
              text: l10n.ephemeralSheetFileKept,
            ),
            _Note(
              icon: Icons.warning_amber_outlined,
              text: l10n.ephemeralSheetUnsavedWarning,
              emphasised: true,
            ),

            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                l10n.ephemeralSheetTimerLabel,
                style: theme.textTheme.titleSmall,
              ),
            ),
            RadioGroup<EphemeralDuration>(
              groupValue: _option.duration,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _option = _option.copyWith(duration: value));
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final choice in _choices)
                    RadioListTile<EphemeralDuration>(
                      value: choice,
                      dense: true,
                      title: Text(_durationLabel(l10n, choice)),
                    ),
                ],
              ),
            ),
            if (_option.duration == EphemeralDuration.custom)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                child: TextField(
                  controller: _customMinutes,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.ephemeralSheetCustomMinutes,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value) ?? 0;
                    setState(
                      () => _option = _option.copyWith(customMinutes: minutes),
                    );
                  },
                ),
              ),

            const Divider(height: 24),
            SwitchListTile(
              value: _option.burnAfterOutput,
              title: Text(l10n.ephemeralSheetBurnAfterOutput),
              subtitle: Text(l10n.ephemeralSheetBurnAfterOutputHint),
              onChanged: (value) => setState(
                () => _option = _option.copyWith(burnAfterOutput: value),
              ),
            ),

            if (_option.isNoOp)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Text(
                  l10n.ephemeralSheetNothingChosen,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _option.isNoOp
                        ? null
                        : () => Navigator.of(context).pop(_option),
                    child: Text(l10n.ephemeralSheetConfirm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

/// One explanatory line with a leading icon.
class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool emphasised;

  const _Note({
    required this.icon,
    required this.text,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasised
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
