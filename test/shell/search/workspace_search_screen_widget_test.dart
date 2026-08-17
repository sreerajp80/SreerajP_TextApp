import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/index/index_providers.dart';
import 'package:sreerajp_textapp/core/index/search_index_models.dart';
import 'package:sreerajp_textapp/core/index/search_index_repository.dart';
import 'package:sreerajp_textapp/core/index/search_index_service.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/shell/home/recents_controller.dart';
import 'package:sreerajp_textapp/shell/search/workspace_search_controller.dart';
import 'package:sreerajp_textapp/shell/search/workspace_search_screen.dart';
import 'package:sreerajp_textapp/shell/shell_providers.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';

import '../../support/test_support.dart';

/// One file held by the fake index.
class _Doc {
  final String fingerprint;
  final String uri;
  final String displayName;
  final String text;

  const _Doc(this.fingerprint, this.uri, this.displayName, this.text);
}

/// An in-memory stand-in for the index service.
///
/// The real, database-backed service is covered by its own tests; here we only
/// need the screen's behaviour, and a plain-Dart fake keeps the widget test free
/// of the SQLite isolate (whose futures never complete under `pump`).
class _FakeIndex implements SearchIndexService {
  final List<_Doc> docs;

  _FakeIndex(this.docs);

  @override
  Future<List<SearchHit>> search(
    String query, {
    Set<IndexFormat> formats = const {},
    int limit = SearchIndexRepository.defaultLimit,
  }) async {
    final terms = SearchIndexRepository.queryTerms(query);
    if (terms.isEmpty) return const [];
    final hits = <SearchHit>[];
    for (final doc in docs) {
      final format = IndexFormat.fromFileName(doc.displayName);
      if (formats.isNotEmpty && !formats.contains(format)) continue;
      final lower = doc.text.toLowerCase();
      if (!terms.every((t) => lower.contains(t.toLowerCase()))) continue;
      hits.add(
        SearchHit(
          fingerprint: doc.fingerprint,
          uri: doc.uri,
          displayName: doc.displayName,
          format: format,
          snippet: SearchIndexRepository.buildSnippet(doc.text, terms),
        ),
      );
    }
    return hits.take(limit).toList(growable: false);
  }

  @override
  Future<void> remove(String fingerprint) async {
    docs.removeWhere((d) => d.fingerprint == fingerprint);
  }

  @override
  Future<int> count() async => docs.length;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used in tests');
}

void main() {
  Future<ProviderContainer> pumpSearch(
    WidgetTester tester,
    List<_Doc> docs, {
    FakeSafService? saf,
  }) async {
    final store = await inMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [
        searchIndexServiceProvider.overrideWith(
          (ref) async => _FakeIndex(docs),
        ),
        // The open flow records a recent; stub it so no database is needed.
        recentsControllerProvider.overrideWith(
          () => StubRecentsController(const []),
        ),
        keyValueStoreSyncProvider.overrideWithValue(store),
        safServiceProvider.overrideWithValue(saf ?? FakeSafService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(home: const WorkspaceSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Lets the debounce timer fire and the search future finish.
  ///
  /// Plain pumps are used instead of `pumpAndSettle` because the "searching"
  /// spinner animates forever and would never settle.
  Future<void> settleSearch(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(WorkspaceSearchController.debounce);
    await settleSearch(tester);
  }

  const notes = _Doc('a', 'content://a', 'notes.txt', 'the quick brown fox');
  const table = _Doc('b', 'content://b', 'table.csv', 'the quick brown fox');

  testWidgets('starts with the "search inside your files" state', (
    tester,
  ) async {
    await pumpSearch(tester, []);
    expect(find.text('Search inside your files'), findsOneWidget);
  });

  testWidgets('typing shows the matching file and its snippet', (tester) async {
    await pumpSearch(tester, [notes]);

    await type(tester, 'brown');

    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.textContaining('quick'), findsOneWidget);
    expect(find.text('1 file'), findsOneWidget);
  });

  testWidgets('a query with no match shows the empty result state', (
    tester,
  ) async {
    await pumpSearch(tester, [notes]);

    await type(tester, 'zebra');

    expect(find.text('No matches found'), findsOneWidget);
  });

  testWidgets('a format chip limits the results', (tester) async {
    await pumpSearch(tester, [notes, table]);

    await type(tester, 'brown');
    expect(find.text('2 files'), findsOneWidget);

    await tester.tap(find.text('CSV'));
    await settleSearch(tester);

    expect(find.text('table.csv'), findsOneWidget);
    expect(find.text('notes.txt'), findsNothing);
  });

  testWidgets('tapping a result opens the file as a tab', (tester) async {
    final container = await pumpSearch(
      tester,
      [notes],
      saf: FakeSafService(
        accessibleUris: const {'content://a'},
        contents: {
          'content://a': Uint8List.fromList([1, 2, 3]),
        },
      ),
    );

    await type(tester, 'brown');
    await tester.tap(find.text('notes.txt'));
    await settleSearch(tester);

    expect(container.read(tabsControllerProvider).tabs, hasLength(1));
    expect(container.read(shellDestinationProvider), ShellDestination.editor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a file that is gone can be dropped from the index', (
    tester,
  ) async {
    final docs = [const _Doc('a', 'content://gone', 'gone.txt', 'brown fox')];
    // No accessible URIs → the tile reports the file as unavailable.
    await pumpSearch(tester, docs, saf: FakeSafService());

    await type(tester, 'brown');
    expect(find.textContaining('File not available'), findsOneWidget);

    await tester.tap(find.text('gone.txt'));
    await settleSearch(tester);

    expect(find.text('gone.txt'), findsNothing);
    expect(docs, isEmpty);
  });
}
