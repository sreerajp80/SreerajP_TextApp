import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editor/editor_settings.dart';
import '../../../core/editor/editor_settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

/// Editor settings (task 11.2): default encoding / line ending on save,
/// confirm-before-overwrite, auto-save interval, and open-read-only-by-default.
///
/// These take effect the next time a file is opened or saved.
class EditorSection extends ConsumerWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const EditorSection({super.key, this.showHeader = true});

  static String _autoSaveLabel(AppLocalizations l10n, int seconds) =>
      seconds == 0 ? l10n.editorAutoSaveOff : l10n.editorAutoSaveValue(seconds);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsProvider);
    final controller = ref.read(editorSettingsProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SettingsSectionHeader(title: l10n.editorSectionTitle),
        ListTile(
          title: Text(l10n.editorDefaultEncoding),
          subtitle: Text(l10n.editorPreserveEncoding),
          trailing: DropdownButton<EncodingDefault>(
            value: settings.encodingDefault,
            items: [
              for (final v in EncodingDefault.values)
                DropdownMenuItem(value: v, child: Text(v.label)),
            ],
            onChanged: (v) {
              if (v != null) controller.setEncodingDefault(v);
            },
          ),
        ),
        ListTile(
          title: Text(l10n.editorDefaultLineEnding),
          subtitle: Text(l10n.editorPreserveLineEnding),
          trailing: DropdownButton<LineEndingDefault>(
            value: settings.lineEndingDefault,
            items: [
              for (final v in LineEndingDefault.values)
                DropdownMenuItem(value: v, child: Text(v.label)),
            ],
            onChanged: (v) {
              if (v != null) controller.setLineEndingDefault(v);
            },
          ),
        ),
        SwitchListTile(
          title: Text(l10n.editorConfirmOverwrite),
          subtitle: Text(l10n.editorConfirmOverwriteSub),
          value: settings.confirmOverwrite,
          onChanged: controller.setConfirmOverwrite,
        ),
        SwitchListTile(
          title: Text(l10n.editorOpenReadOnly),
          subtitle: Text(l10n.editorOpenReadOnlySub),
          value: settings.openReadOnlyByDefault,
          onChanged: controller.setOpenReadOnlyByDefault,
        ),
        SettingsSliderTile(
          label: l10n.editorAutoSaveLabel,
          value: EditorSettings.autoSaveChoices
              .indexOf(_nearestChoice(settings.autoSaveSeconds))
              .toDouble(),
          min: 0,
          max: (EditorSettings.autoSaveChoices.length - 1).toDouble(),
          divisions: EditorSettings.autoSaveChoices.length - 1,
          valueLabel: _autoSaveLabel(l10n, settings.autoSaveSeconds),
          onChanged: (i) => controller.setAutoSaveSeconds(
            EditorSettings.autoSaveChoices[i.round()],
          ),
        ),
      ],
    );
  }

  /// Snaps a stored interval to the nearest offered choice so the slider always
  /// lands on a valid stop.
  int _nearestChoice(int seconds) {
    if (EditorSettings.autoSaveChoices.contains(seconds)) return seconds;
    var best = EditorSettings.autoSaveChoices.first;
    for (final c in EditorSettings.autoSaveChoices) {
      if ((c - seconds).abs() < (best - seconds).abs()) best = c;
    }
    return best;
  }
}
