import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'editor_settings_controller.dart';

/// Asks the user to confirm overwriting the original file, but only when the
/// "confirm before overwrite" editor setting is on (task 11.2).
///
/// Returns `true` when the save should go ahead — either the setting is off, or
/// the user confirmed. "Save as a copy" never calls this because it does not
/// overwrite the original.
///
/// Reads the setting from the Riverpod container attached to [context], so the
/// existing save sheets (plain functions with only a `BuildContext`) can call it
/// without threading a `WidgetRef` through every layer.
Future<bool> confirmOverwriteIfNeeded(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (!container.read(editorSettingsProvider).confirmOverwrite) return true;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.overwriteTitle),
        content: Text(l10n.overwriteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.overwriteConfirm),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}
