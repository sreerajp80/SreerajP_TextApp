import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/shell/tabs/session_retention.dart';

void main() {
  group('pickReleasableSessions', () {
    test('nothing to release within the budget', () {
      final release = pickReleasableSessions(
        liveSessionIds: {'a', 'b'},
        recencyOrder: ['a', 'b'],
        activeId: 'a',
        dirtyIds: {},
        keepAlive: 3,
      );
      expect(release, isEmpty);
    });

    test('releases least-recently-used clean sessions beyond the budget', () {
      // Recency: a (most recent) .. e (least). Budget 3.
      final release = pickReleasableSessions(
        liveSessionIds: {'a', 'b', 'c', 'd', 'e'},
        recencyOrder: ['a', 'b', 'c', 'd', 'e'],
        activeId: 'a',
        dirtyIds: {},
        keepAlive: 3,
      );
      // Keep a, b, c; release the two oldest.
      expect(release, ['d', 'e']);
    });

    test('never releases the active tab even if it is oldest', () {
      final release = pickReleasableSessions(
        liveSessionIds: {'a', 'b', 'c', 'd'},
        recencyOrder: ['b', 'c', 'd', 'a'], // a is least recent but active
        activeId: 'a',
        dirtyIds: {},
        keepAlive: 2,
      );
      // Active 'a' is protected and does not spend budget; keep b, c; release d.
      expect(release, ['d']);
      expect(release, isNot(contains('a')));
    });

    test('never releases a dirty tab beyond the budget', () {
      final release = pickReleasableSessions(
        liveSessionIds: {'a', 'b', 'c', 'd'},
        recencyOrder: ['a', 'b', 'c', 'd'],
        activeId: 'a',
        dirtyIds: {'d'}, // oldest but has unsaved edits
        keepAlive: 2,
      );
      // Budget 2 keeps a, b. Beyond it: c is clean → released; d is dirty → kept.
      expect(release, ['c']);
      expect(release, isNot(contains('d')));
    });

    test('a dirty tab beyond the budget is kept while clean ones are released',
        () {
      final release = pickReleasableSessions(
        liveSessionIds: {'a', 'b', 'c', 'd', 'e'},
        recencyOrder: ['a', 'b', 'c', 'd', 'e'],
        activeId: 'a',
        dirtyIds: {'e'},
        keepAlive: 2,
      );
      // Budget 2 keeps a, b. Beyond it: c, d clean → released; e dirty → kept.
      expect(release, ['c', 'd']);
      expect(release, isNot(contains('e')));
    });

    test('keepAlive below 1 is clamped to 1', () {
      final release = pickReleasableSessions(
        liveSessionIds: {'a', 'b', 'c'},
        recencyOrder: ['a', 'b', 'c'],
        activeId: null,
        dirtyIds: {},
        keepAlive: 0,
      );
      // Keep the single most recent; release the rest.
      expect(release, ['b', 'c']);
    });

    test('ignores ids not present in the recency list', () {
      final release = pickReleasableSessions(
        liveSessionIds: {'ghost'},
        recencyOrder: ['a', 'b'],
        activeId: 'a',
        dirtyIds: {},
        keepAlive: 1,
      );
      expect(release, isEmpty);
    });
  });
}
