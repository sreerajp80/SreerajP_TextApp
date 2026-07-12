import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/over_limit_behavior.dart';

DocumentTab tab(String id, int lastActiveAt, {bool dirty = false}) =>
    DocumentTab(
      id: id,
      fingerprint: id,
      uri: 'content://$id',
      displayName: '$id.txt',
      isDirty: dirty,
      lastActiveAt: lastActiveAt,
    );

void main() {
  group('pickLruClosable', () {
    test('picks the least-recently-used tab at the cap', () {
      final tabs = [
        tab('a', 30),
        tab('b', 10), // oldest
        tab('c', 20),
      ];
      expect(pickLruClosable(tabs, 3)?.id, 'b');
    });

    test('returns null when below the cap', () {
      final tabs = [tab('a', 10), tab('b', 20)];
      expect(pickLruClosable(tabs, 5), isNull);
    });

    test('never picks a tab with unsaved edits', () {
      final tabs = [
        tab('a', 10, dirty: true), // oldest but dirty
        tab('b', 20),
        tab('c', 30),
      ];
      expect(pickLruClosable(tabs, 3)?.id, 'b');
    });

    test('returns null when every tab is unsaved', () {
      final tabs = [
        tab('a', 10, dirty: true),
        tab('b', 20, dirty: true),
      ];
      expect(pickLruClosable(tabs, 2), isNull);
    });
  });

  group('OverLimitBehavior pref round-trip', () {
    test('parses known values and falls back on unknown', () {
      expect(
        OverLimitBehavior.fromPrefValue(OverLimitBehavior.ask.prefValue),
        OverLimitBehavior.ask,
      );
      expect(
        OverLimitBehavior.fromPrefValue('bogus'),
        OverLimitBehavior.closeLeastRecentlyUsed,
      );
    });
  });
}
