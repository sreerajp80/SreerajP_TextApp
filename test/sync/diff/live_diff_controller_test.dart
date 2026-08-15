import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/diff/diff_models.dart';
import 'package:text_data/sync/diff/diff_payload.dart';
import 'package:text_data/sync/diff/live_diff_controller.dart';

void main() {
  group('LiveDiffController tests', () {
    test('initializes and computes diff correctly', () {
      final ctrl = LiveDiffController(
        documentName: 'test.txt',
        mimeType: 'text/plain',
        initialLocalContent: 'A\nB\nC',
        initialRemoteContent: 'A\nB_mod\nC',
      );

      expect(ctrl.totalDifferences, 1);
      expect(ctrl.textDiff?.modifiedCount, 1);
      expect(ctrl.isCsv, isFalse);
    });

    test('recomputes when local content is updated', () {
      final ctrl = LiveDiffController(
        documentName: 'test.txt',
        mimeType: 'text/plain',
        initialLocalContent: 'A\nB',
        initialRemoteContent: 'A\nB',
      );

      expect(ctrl.totalDifferences, 0);

      ctrl.updateLocalContent('A\nB\nC');
      expect(ctrl.totalDifferences, 1);
      expect(ctrl.deletedCount, 1); // in local relative to remote
    });

    test('handles incoming remote delta updates from peer', () {
      final ctrl = LiveDiffController(
        documentName: 'data.csv',
        mimeType: 'text/csv',
        initialLocalContent: 'A,B\n1,2',
        initialRemoteContent: 'A,B\n1,2',
      );

      expect(ctrl.totalDifferences, 0);

      final payload = DiffSessionPayload.build(
        action: DiffPayloadAction.deltaUpdate,
        sessionId: 'session_1',
        fileName: 'data.csv',
        mimeType: 'text/csv',
        content: 'A,B\n1,99',
      );

      ctrl.handleIncomingPayload(payload);
      expect(ctrl.peerUpdatedNotice, isTrue);
      expect(ctrl.totalDifferences, 1);
    });

    test('merges output with getMergedOutput()', () {
      final ctrl = LiveDiffController(
        documentName: 'note.md',
        mimeType: 'text/markdown',
        initialLocalContent: 'Title\nMine',
        initialRemoteContent: 'Title\nPeer',
      );

      ctrl.resolveHunk('hunk_2', HunkResolution.acceptRemote);
      expect(ctrl.getMergedOutput(), 'Title\nPeer');

      ctrl.acceptAllMine();
      expect(ctrl.getMergedOutput(), 'Title\nMine');
    });
  });
}
