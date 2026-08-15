import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/index/index_providers.dart';
import 'package:text_data/core/index/search_index_models.dart';
import 'package:text_data/core/storage/saf_service.dart';

/// What the workspace search screen is showing right now.
class WorkspaceSearchState {
  final String query;

  /// Formats the user is limiting the search to. Empty means "all formats".
  final Set<IndexFormat> formats;
  final List<SearchHit> hits;

  /// True while a search is running (the query changed and results are due).
  final bool searching;

  /// True once at least one search has finished for the current query, so the
  /// screen knows the difference between "not searched yet" and "no results".
  final bool searched;

  const WorkspaceSearchState({
    this.query = '',
    this.formats = const {},
    this.hits = const [],
    this.searching = false,
    this.searched = false,
  });

  WorkspaceSearchState copyWith({
    String? query,
    Set<IndexFormat>? formats,
    List<SearchHit>? hits,
    bool? searching,
    bool? searched,
  }) => WorkspaceSearchState(
    query: query ?? this.query,
    formats: formats ?? this.formats,
    hits: hits ?? this.hits,
    searching: searching ?? this.searching,
    searched: searched ?? this.searched,
  );
}

/// Drives the workspace-wide search screen (Feature 11).
///
/// Typing is debounced so the index is queried once the user pauses, and every
/// run is tagged so a slow earlier search can never overwrite a newer result.
class WorkspaceSearchController extends Notifier<WorkspaceSearchState> {
  /// How long to wait after the last keystroke before searching.
  static const Duration debounce = Duration(milliseconds: 250);

  /// How many results one search asks for.
  static const int resultLimit = 60;

  Timer? _timer;
  int _run = 0;

  /// Cache of "is this file still reachable?", so the list does not ask the
  /// system about the same file again while scrolling.
  final Map<String, Future<bool>> _availability = {};

  @override
  WorkspaceSearchState build() {
    ref.onDispose(() => _timer?.cancel());
    return const WorkspaceSearchState();
  }

  /// Clears the query, filters, and results (called when the screen opens, so
  /// it never starts on someone else's old search).
  void reset() {
    _timer?.cancel();
    _run++;
    _availability.clear();
    state = const WorkspaceSearchState();
  }

  /// The user typed something.
  void setQuery(String query) {
    final trimmed = query.trim();
    state = state.copyWith(
      query: query,
      searching: trimmed.isNotEmpty,
      searched: trimmed.isNotEmpty && state.searched,
      hits: trimmed.isEmpty ? const [] : state.hits,
    );
    _timer?.cancel();
    if (trimmed.isEmpty) return;
    _timer = Timer(debounce, search);
  }

  /// Turns one format filter on or off.
  void toggleFormat(IndexFormat format) {
    final formats = Set<IndexFormat>.from(state.formats);
    if (!formats.remove(format)) formats.add(format);
    state = state.copyWith(formats: formats);
    if (state.query.trim().isNotEmpty) search();
  }

  /// Clears every format filter ("All").
  void clearFormats() {
    if (state.formats.isEmpty) return;
    state = state.copyWith(formats: const {});
    if (state.query.trim().isNotEmpty) search();
  }

  /// Runs the search now (also used by the retry action).
  Future<void> search() async {
    final query = state.query.trim();
    if (query.isEmpty) {
      state = state.copyWith(hits: const [], searching: false, searched: false);
      return;
    }
    final run = ++_run;
    state = state.copyWith(searching: true);
    List<SearchHit> hits;
    try {
      final index = await ref.read(searchIndexServiceProvider.future);
      hits = await index.search(
        query,
        formats: state.formats,
        limit: resultLimit,
      );
    } catch (_) {
      hits = const [];
    }
    if (run != _run) return; // a newer search already answered
    state = state.copyWith(hits: hits, searching: false, searched: true);
  }

  /// Whether the file behind a hit can still be opened. The answer is cached
  /// per URI for the life of the screen.
  Future<bool> isAvailable(String uri) {
    return _availability.putIfAbsent(
      uri,
      () => ref.read(safServiceProvider).isAccessible(uri),
    );
  }

  /// Drops a file from the index (used when its file is gone) and removes it
  /// from the list on screen.
  Future<void> forget(String fingerprint) async {
    try {
      final index = await ref.read(searchIndexServiceProvider.future);
      await index.remove(fingerprint);
    } catch (_) {
      // ignored — the row may already be gone
    }
    state = state.copyWith(
      hits: state.hits
          .where((h) => h.fingerprint != fingerprint)
          .toList(growable: false),
    );
  }
}

final workspaceSearchControllerProvider =
    NotifierProvider<WorkspaceSearchController, WorkspaceSearchState>(
      WorkspaceSearchController.new,
    );
