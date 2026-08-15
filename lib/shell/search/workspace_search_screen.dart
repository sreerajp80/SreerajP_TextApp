import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/index/index_providers.dart';
import 'package:text_data/core/index/search_index_models.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/shell/open_file_action.dart';
import 'package:text_data/shell/search/search_hit_tile.dart';
import 'package:text_data/shell/search/workspace_search_controller.dart';

/// Searches every indexed file at once and opens the one the user picks
/// (Feature 11).
///
/// The screen only reads the local index — it never touches the files on disk
/// until the user taps a result, and it never leaves the device.
class WorkspaceSearchScreen extends ConsumerStatefulWidget {
  const WorkspaceSearchScreen({super.key});

  /// Pushes the screen on top of the current one.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WorkspaceSearchScreen()),
    );
  }

  @override
  ConsumerState<WorkspaceSearchScreen> createState() =>
      _WorkspaceSearchScreenState();
}

class _WorkspaceSearchScreenState extends ConsumerState<WorkspaceSearchScreen> {
  final TextEditingController _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start from a clean sheet every time the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceSearchControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(workspaceSearchControllerProvider);
    final controller = ref.read(workspaceSearchControllerProvider.notifier);
    final enabled = ref.watch(workspaceIndexEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchWorkspaceTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _field,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: controller.setQuery,
                  onSubmitted: (_) => controller.search(),
                  decoration: InputDecoration(
                    hintText: l10n.searchWorkspaceHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: state.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.searchWorkspaceClear,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _field.clear();
                              controller.setQuery('');
                            },
                          ),
                  ),
                ),
              ),
              _FormatChips(
                selected: state.formats,
                onToggle: controller.toggleFormat,
                onAll: controller.clearFormats,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _Body(state: state, indexEnabled: enabled),
    );
  }
}

class _Body extends ConsumerWidget {
  final WorkspaceSearchState state;
  final bool indexEnabled;

  const _Body({required this.state, required this.indexEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(workspaceSearchControllerProvider.notifier);

    if (!indexEnabled && state.hits.isEmpty && !state.searched) {
      return _Message(
        icon: Icons.search_off,
        title: l10n.searchWorkspaceOffTitle,
        body: l10n.searchWorkspaceOffBody,
      );
    }
    if (state.query.trim().isEmpty) {
      return _Message(
        icon: Icons.travel_explore_outlined,
        title: l10n.searchWorkspaceStartTitle,
        body: l10n.searchWorkspaceStartBody,
      );
    }
    if (state.searching && state.hits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hits.isEmpty) {
      return _Message(
        icon: Icons.search_off,
        title: l10n.searchWorkspaceNoResults,
        body: l10n.searchWorkspaceNoResultsBody,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l10n.searchWorkspaceResults(state.hits.length),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: state.hits.length,
            separatorBuilder: (_, _) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final hit = state.hits[i];
              return SearchHitTile(
                hit: hit,
                available: controller.isAvailable(hit.uri),
                onOpen: () => _open(context, ref, hit),
                onForget: () => controller.forget(hit.fingerprint),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, SearchHit hit) async {
    final navigator = Navigator.of(context);
    await OpenFileAction(
      ref,
    ).openFile(context, SafFile(uri: hit.uri, displayName: hit.displayName));
    // Leave the search behind so the user lands on the document.
    if (navigator.canPop()) navigator.pop();
  }
}

/// The format filter row. "All" clears every filter.
class _FormatChips extends StatelessWidget {
  final Set<IndexFormat> selected;
  final void Function(IndexFormat) onToggle;
  final VoidCallback onAll;

  const _FormatChips({
    required this.selected,
    required this.onToggle,
    required this.onAll,
  });

  static const List<IndexFormat> _shown = [
    IndexFormat.txt,
    IndexFormat.markdown,
    IndexFormat.json,
    IndexFormat.csv,
    IndexFormat.xml,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(l10n.searchWorkspaceAll),
              selected: selected.isEmpty,
              onSelected: (_) => onAll(),
            ),
          ),
          for (final format in _shown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(format.id.toUpperCase()),
                selected: selected.contains(format),
                onSelected: (_) => onToggle(format),
              ),
            ),
        ],
      ),
    );
  }
}

/// A centred icon + title + body used for the start, empty, and off states.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
