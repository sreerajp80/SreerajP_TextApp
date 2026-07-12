import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'shell_providers.dart';
import 'tabs/tabs_controller.dart';
import 'tabs/tabs_workspace.dart';

/// The adaptive frame the user lives in (task 2.2).
///
/// Uses a [NavigationRail] on wide viewports (tablets, landscape) and a bottom
/// [NavigationBar] on narrow ones (phones), switching between Home, the Editor
/// workspace, and Settings. Respects system font scaling because it uses
/// standard Material components with no fixed text sizes.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  /// Viewport width at/above which the rail layout is used.
  static const double wideBreakpoint = 640;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Resolve the memory-aware tab cap and restore any saved tabs once the
    // first frame is up (both read providers that must exist by then).
    WidgetsBinding.instance.addPostFrameCallback((_) => _startup());
  }

  Future<void> _startup() async {
    final tabs = ref.read(tabsControllerProvider.notifier);
    await tabs.resolveCap();
    final skipped = await tabs.restore();
    if (!mounted) return;
    if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).shellTabsSkipped(skipped)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = ref.watch(shellDestinationProvider);
    final tabCount = ref.watch(tabsControllerProvider).tabs.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppShell.wideBreakpoint;
        return wide
            ? _WideLayout(destination: destination, tabCount: tabCount)
            : _NarrowLayout(destination: destination, tabCount: tabCount);
      },
    );
  }
}

Widget _screenFor(ShellDestination destination) {
  switch (destination) {
    case ShellDestination.home:
      return const HomeScreen();
    case ShellDestination.editor:
      return const TabsWorkspace();
    case ShellDestination.settings:
      return const SettingsScreen();
  }
}

class _WideLayout extends ConsumerWidget {
  final ShellDestination destination;
  final int tabCount;

  const _WideLayout({required this.destination, required this.tabCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shellDestinationProvider.notifier);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: destination.index,
            onDestinationSelected: (i) =>
                controller.select(ShellDestination.values[i]),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(l10n.navHome),
              ),
              NavigationRailDestination(
                icon: _editorIcon(tabCount, selected: false),
                selectedIcon: _editorIcon(tabCount, selected: true),
                label: Text(l10n.navEditor),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n.navSettings),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screenFor(destination)),
        ],
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  final ShellDestination destination;
  final int tabCount;

  const _NarrowLayout({required this.destination, required this.tabCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shellDestinationProvider.notifier);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _screenFor(destination),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: destination.index,
        onDestinationSelected: (i) =>
            controller.select(ShellDestination.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: _editorIcon(tabCount, selected: false),
            selectedIcon: _editorIcon(tabCount, selected: true),
            label: l10n.navEditor,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

/// The Editor icon, badged with the number of open tabs when there are any.
Widget _editorIcon(int tabCount, {required bool selected}) {
  final icon = Icon(selected ? Icons.tab : Icons.tab_outlined);
  if (tabCount == 0) return icon;
  return Badge(label: Text('$tabCount'), child: icon);
}
