import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/diff/diff_models.dart';
import 'package:text_data/sync/diff/text_diff_engine.dart';

void main() {
  const engine = TextDiffEngine();

  group('TextDiffEngine tests', () {
    test('identical texts return zero differences', () {
      const text = 'Hello world\nSecond line\nThird line';
      final result = engine.compare(text, text);

      expect(result.isIdentical, isTrue);
      expect(result.totalDifferences, 0);
      expect(result.addedCount, 0);
      expect(result.deletedCount, 0);
      expect(result.modifiedCount, 0);
      expect(result.unchangedCount, 3);
    });

    test('detects line additions', () {
      const local = 'Line 1\nLine 3';
      const remote = 'Line 1\nLine 2\nLine 3';
      final result = engine.compare(local, remote);

      expect(result.isIdentical, isFalse);
      expect(result.addedCount, 1);
      expect(result.deletedCount, 0);
      expect(result.modifiedCount, 0);

      final addedLine = result.lines.firstWhere(
        (l) => l.type == DiffType.added,
      );
      expect(addedLine.remoteText, 'Line 2');
    });

    test('detects line deletions', () {
      const local = 'Line 1\nLine 2\nLine 3';
      const remote = 'Line 1\nLine 3';
      final result = engine.compare(local, remote);

      expect(result.isIdentical, isFalse);
      expect(result.deletedCount, 1);
      expect(result.addedCount, 0);

      final deletedLine = result.lines.firstWhere(
        (l) => l.type == DiffType.deleted,
      );
      expect(deletedLine.localText, 'Line 2');
    });

    test('detects line modifications and computes inline segments', () {
      const local = 'The quick brown fox jumps';
      const remote = 'The fast brown dog jumps';
      final result = engine.compare(local, remote);

      expect(result.isIdentical, isFalse);
      expect(result.modifiedCount, 1);

      final modLine = result.lines.firstWhere(
        (l) => l.type == DiffType.modified,
      );
      expect(modLine.localSegments.any((s) => s.isChanged), isTrue);
      expect(modLine.remoteSegments.any((s) => s.isChanged), isTrue);
    });

    test('groups contiguous changes into hunks', () {
      const local = 'A\nB1\nB2\nC';
      const remote = 'A\nB_mod1\nB_mod2\nC';
      final result = engine.compare(local, remote);

      expect(
        result.hunks.length,
        3,
      ); // A (unchanged), B (modified hunk), C (unchanged)
      expect(result.hunks[1].lines.length, 2);
      expect(result.hunks[1].hasChanges, isTrue);
    });
  });
}
