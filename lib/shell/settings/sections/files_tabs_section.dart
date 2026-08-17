import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/index/index_providers.dart';
import 'package:sreerajp_textapp/core/storage/device_memory.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/over_limit_behavior.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/shell/settings/sections/settings_widgets.dart';

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
        const Divider(height: 0),
        const _WorkspaceIndexTiles(),
      ],
    );
  }
}

/// Workspace search index controls (Feature 11): the on/off switch, how many
/// files are indexed, and the rebuild / clear actions.
class _WorkspaceIndexTiles extends ConsumerStatefulWidget {
  const _WorkspaceIndexTiles();

  @override
  ConsumerState<_WorkspaceIndexTiles> createState() =>
      _WorkspaceIndexTilesState();
}

class _WorkspaceIndexTilesState extends ConsumerState<_WorkspaceIndexTiles> {
  int? _count;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    try {
      final index = await ref.read(searchIndexServiceProvider.future);
      final count = await index.count();
      if (mounted) setState(() => _count = count);
    } catch (_) {
      if (mounted) setState(() => _count = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(workspaceIndexEnabledProvider);
    final count = _count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.filesIndexTitle),
          subtitle: Text(enabled ? l10n.filesIndexOn : l10n.filesIndexOff),
          value: enabled,
          onChanged: (v) =>
              ref.read(workspaceIndexEnabledProvider.notifier).set(v),
        ),
        ListTile(
          title: Text(l10n.filesIndexRebuild),
          subtitle: Text(
            count == null
                ? l10n.filesIndexCount(0)
                : l10n.filesIndexCount(count),
          ),
          trailing: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          enabled: enabled && !_busy,
          onTap: enabled && !_busy ? _rebuild : null,
        ),
        ListTile(
          title: Text(l10n.filesIndexClear),
          subtitle: Text(l10n.filesIndexClearBody),
          trailing: const Icon(Icons.delete_outline),
          enabled: !_busy,
          onTap: _busy ? null : _clear,
        ),
      ],
    );
  }

  Future<void> _rebuild() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(SnackBar(content: Text(l10n.filesIndexRebuilding)));
    var added = 0;
    try {
      final backfill = await ref.read(searchIndexBackfillProvider.future);
      added = await backfill.run();
    } catch (_) {
      added = 0;
    }
    await _refreshCount();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.filesIndexRebuilt(added))),
    );
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.filesIndexClear),
        content: Text(l10n.filesIndexClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.filesIndexClear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final index = await ref.read(searchIndexServiceProvider.future);
      await index.clear();
    } catch (_) {
      // ignored — nothing to clear
    }
    await _refreshCount();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.filesIndexCleared)));
  }
}
