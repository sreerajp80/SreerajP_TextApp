import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/device_memory.dart';
import '../../../l10n/app_localizations.dart';
import '../../tabs/over_limit_behavior.dart';
import '../../tabs/tabs_controller.dart';
import 'settings_widgets.dart';

/// Files & Tabs settings (task 11.3): the maximum open-tab cap (Auto from device
/// RAM, or a fixed number), the over-limit behavior, and restore-on-relaunch.
class FilesTabsSection extends ConsumerStatefulWidget {
  /// Whether to show the in-body section header. The detail page hides it
  /// because the app bar already shows the title.
  final bool showHeader;

  const FilesTabsSection({super.key, this.showHeader = true});

  @override
  ConsumerState<FilesTabsSection> createState() => _FilesTabsSectionState();
}

class _FilesTabsSectionState extends ConsumerState<FilesTabsSection> {
  /// Fixed-cap choices offered when the user turns Auto off.
  static const List<int> _fixedChoices = [1, 2, 3, 4, 5, 6, 8, 10];

  int? _autoCap;

  @override
  void initState() {
    super.initState();
    // Resolve the RAM-based cap once so we can show "Auto — N".
    ref.read(deviceMemoryProvider).autoTabCapForDevice().then((cap) {
      if (mounted) setState(() => _autoCap = cap);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(tabsControllerProvider);
    final controller = ref.read(tabsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final isAuto = controller.capMode != 'fixed';
    final autoLabel = _autoCap == null
        ? l10n.filesAuto
        : l10n.filesAutoCap(_autoCap!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          SettingsSectionHeader(title: l10n.filesTabsSectionTitle),
        SwitchListTile(
          title: Text(l10n.filesAutoLimit),
          subtitle: Text(
            isAuto
                ? l10n.filesChosenFromMemory(autoLabel)
                : l10n.filesUsingFixed,
          ),
          value: isAuto,
          onChanged: (auto) async {
            if (auto) {
              await controller.setCapModeAuto();
            } else {
              await controller.setFixedCap(tabs.cap);
            }
            if (mounted) setState(() {});
          },
        ),
        if (!isAuto)
          ListTile(
            title: Text(l10n.filesMaxOpenTabs),
            trailing: DropdownButton<int>(
              value: _fixedChoices.contains(tabs.cap) ? tabs.cap : null,
              hint: Text('${tabs.cap}'),
              items: [
                for (final n in _fixedChoices)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (n) async {
                if (n != null) {
                  await controller.setFixedCap(n);
                  if (mounted) setState(() {});
                }
              },
            ),
          ),
        ListTile(
          title: Text(l10n.filesWhenLimitReached),
          subtitle: Text(tabs.overLimitBehavior.label),
          trailing: DropdownButton<OverLimitBehavior>(
            value: tabs.overLimitBehavior,
            items: [
              for (final b in OverLimitBehavior.values)
                DropdownMenuItem(value: b, child: Text(b.label)),
            ],
            onChanged: (b) {
              if (b != null) controller.setOverLimitBehavior(b);
            },
          ),
        ),
        SwitchListTile(
          title: Text(l10n.filesRestoreOnRelaunch),
          subtitle: Text(l10n.filesRestoreSub),
          value: controller.restoreOnRelaunch,
          onChanged: (v) async {
            await controller.setRestoreOnRelaunch(v);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}
