import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/sync/diff/diff_models.dart';
import 'package:sreerajp_textapp/sync/diff/merge_engine.dart';
import 'package:sreerajp_textapp/sync/diff/text_diff_engine.dart';

void main() {
  const diffEngine = TextDiffEngine();
  const mergeEngine = MergeEngine();

  group('MergeEngine tests', () {
    test('mergeText respects acceptLocal and acceptRemote choices', () {
      const local = 'Header\nLocal change\nFooter';
      const remote = 'Header\nRemote change\nFooter';
      final diff = diffEngine.compare(local, remote);

      // Default (accept local)
      diff.hunks[1].resolution = HunkResolution.acceptLocal;
      expect(mergeEngine.mergeText(diff), 'Header\nLocal change\nFooter');

      // Accept remote
      diff.hunks[1].resolution = HunkResolution.acceptRemote;
      expect(mergeEngine.mergeText(diff), 'Header\nRemote change\nFooter');

      // Accept both
      diff.hunks[1].resolution = HunkResolution.acceptBoth;
      expect(
        mergeEngine.mergeText(diff),
        'Header\nLocal change\nRemote change\nFooter',
      );
    });

    test('acceptAllLocal and acceptAllRemote bulk helpers work', () {
      const local = 'A\nLocal 1\nLocal 2\nZ';
      const remote = 'A\nRemote 1\nRemote 2\nZ';
      final diff = diffEngine.compare(local, remote);

      mergeEngine.acceptAllRemote(diff.hunks);
      expect(diff.hunks[1].resolution, HunkResolution.acceptRemote);

      mergeEngine.acceptAllLocal(diff.hunks);
      expect(diff.hunks[1].resolution, HunkResolution.acceptLocal);
    });

    test('acceptNonConflicting auto-resolves additions and deletions', () {
      const local = 'A\nDeleteMe\nB\nC';
      const remote = 'A\nB\nAddedHere\nC';
      final diff = diffEngine.compare(local, remote);

      mergeEngine.acceptNonConflicting(diff.hunks);

      final deleteHunk = diff.hunks.firstWhere(
        (h) => h.type == DiffType.deleted,
      );
      expect(deleteHunk.resolution, HunkResolution.acceptLocal);

      final addHunk = diff.hunks.firstWhere((h) => h.type == DiffType.added);
      expect(addHunk.resolution, HunkResolution.acceptRemote);
    });
  });
}
