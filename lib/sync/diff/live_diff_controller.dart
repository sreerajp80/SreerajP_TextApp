import 'package:flutter/foundation.dart';
import 'package:sreerajp_textapp/sync/diff/csv_diff_engine.dart';
import 'package:sreerajp_textapp/sync/diff/diff_models.dart';
import 'package:sreerajp_textapp/sync/diff/diff_payload.dart';
import 'package:sreerajp_textapp/sync/diff/merge_engine.dart';
import 'package:sreerajp_textapp/sync/diff/text_diff_engine.dart';

/// Connection mode for diff session.
enum DiffSessionMode {
  standalone, // comparing two local files / tabs
  p2pHost, // hosting live P2P diff session
  p2pClient, // connected as client to live P2P diff session
}

/// Controller driving the real-time document diff and delta sync session.
class LiveDiffController extends ChangeNotifier {
  final String documentName;
  final String mimeType;
  final DiffSessionMode mode;
  final String sessionId;

  final TextDiffEngine _textEngine = const TextDiffEngine();
  final CsvDiffEngine _csvEngine = const CsvDiffEngine();
  final MergeEngine _mergeEngine = const MergeEngine();

  /// Function invoked to transmit payloads to peer over encrypted local socket.
  final Future<void> Function(DiffSessionPayload payload)? onSendPayload;

  String _localContent;
  String _remoteContent;

  TextDiffResult? _textDiff;
  CsvDiffResult? _csvDiff;

  bool _isSending = false;
  String? _errorMessage;
  bool _peerUpdatedNotice = false;

  LiveDiffController({
    required this.documentName,
    required this.mimeType,
    this.mode = DiffSessionMode.standalone,
    this.sessionId = 'session_1',
    required String initialLocalContent,
    String initialRemoteContent = '',
    this.onSendPayload,
  }) : _localContent = initialLocalContent,
       _remoteContent = initialRemoteContent {
    _recomputeDiff();
  }

  String get localContent => _localContent;
  String get remoteContent => _remoteContent;

  TextDiffResult? get textDiff => _textDiff;
  CsvDiffResult? get csvDiff => _csvDiff;

  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get peerUpdatedNotice => _peerUpdatedNotice;

  bool get isCsv =>
      mimeType.contains('csv') || documentName.toLowerCase().endsWith('.csv');
  bool get isMarkdown =>
      mimeType.contains('markdown') ||
      documentName.toLowerCase().endsWith('.md');
  bool get isJson =>
      mimeType.contains('json') || documentName.toLowerCase().endsWith('.json');
  bool get isXml =>
      mimeType.contains('xml') || documentName.toLowerCase().endsWith('.xml');

  int get totalDifferences => isCsv
      ? (_csvDiff?.totalDifferences ?? 0)
      : (_textDiff?.totalDifferences ?? 0);

  int get addedCount =>
      isCsv ? (_csvDiff?.addedRowCount ?? 0) : (_textDiff?.addedCount ?? 0);

  int get deletedCount =>
      isCsv ? (_csvDiff?.deletedRowCount ?? 0) : (_textDiff?.deletedCount ?? 0);

  int get modifiedCount => isCsv
      ? (_csvDiff?.modifiedRowCount ?? 0)
      : (_textDiff?.modifiedCount ?? 0);

  void _recomputeDiff() {
    if (isCsv) {
      _csvDiff = _csvEngine.compare(_localContent, _remoteContent);
      _textDiff = _textEngine.compare(_localContent, _remoteContent);
    } else {
      _textDiff = _textEngine.compare(_localContent, _remoteContent);
    }
  }

  /// Updates local document content and re-evaluates diff.
  void updateLocalContent(String newContent, {bool broadcast = false}) {
    _localContent = newContent;
    _recomputeDiff();
    notifyListeners();
    if (broadcast && onSendPayload != null) {
      pushLocalToPeer();
    }
  }

  /// Updates remote document content (e.g. from peer) and re-evaluates diff.
  void updateRemoteContent(String newRemote) {
    _remoteContent = newRemote;
    _peerUpdatedNotice = true;
    _recomputeDiff();
    notifyListeners();
  }

  /// Handles an incoming delta payload from connected peer.
  void handleIncomingPayload(DiffSessionPayload payload) {
    if (payload.action == DiffPayloadAction.deltaUpdate ||
        payload.action == DiffPayloadAction.offer) {
      updateRemoteContent(payload.content);
    } else if (payload.action == DiffPayloadAction.resolveHunk) {
      final hunkId = payload.hunkId;
      final resStr = payload.resolution;
      if (hunkId != null && resStr != null && _textDiff != null) {
        for (final h in _textDiff!.hunks) {
          if (h.id == hunkId) {
            // Note: peer resolution preference
            _peerUpdatedNotice = true;
            notifyListeners();
            break;
          }
        }
      }
    }
  }

  void clearPeerNotice() {
    _peerUpdatedNotice = false;
    notifyListeners();
  }

  /// Resolves a single text hunk.
  void resolveHunk(
    String hunkId,
    HunkResolution resolution, {
    String? customText,
  }) {
    if (_textDiff == null) return;
    for (final hunk in _textDiff!.hunks) {
      if (hunk.id == hunkId) {
        hunk.resolution = resolution;
        hunk.customText = customText;
        notifyListeners();

        // Broadcast resolution hint to peer
        if (onSendPayload != null) {
          final payload = DiffSessionPayload.build(
            action: DiffPayloadAction.resolveHunk,
            sessionId: sessionId,
            fileName: documentName,
            mimeType: mimeType,
            hunkId: hunkId,
            resolution: resolution.name,
          );
          onSendPayload?.call(payload);
        }
        break;
      }
    }
  }

  /// Resolves a single CSV row diff.
  void resolveCsvRow(int rowId, HunkResolution resolution) {
    if (_csvDiff == null) return;
    for (final row in _csvDiff!.rows) {
      if (row.id == rowId) {
        row.resolution = resolution;
        notifyListeners();
        break;
      }
    }
  }

  /// Accepts all local changes across all hunks/rows.
  void acceptAllMine() {
    if (_textDiff != null) {
      _mergeEngine.acceptAllLocal(_textDiff!.hunks);
    }
    if (_csvDiff != null) {
      _mergeEngine.acceptAllLocalCsv(_csvDiff!.rows);
    }
    notifyListeners();
  }

  /// Accepts all remote changes across all hunks/rows.
  void acceptAllPeer() {
    if (_textDiff != null) {
      _mergeEngine.acceptAllRemote(_textDiff!.hunks);
    }
    if (_csvDiff != null) {
      _mergeEngine.acceptAllRemoteCsv(_csvDiff!.rows);
    }
    notifyListeners();
  }

  /// Auto-merges non-conflicting additions and deletions.
  void autoMergeNonConflicting() {
    if (_textDiff != null) {
      _mergeEngine.acceptNonConflicting(_textDiff!.hunks);
    }
    if (_csvDiff != null) {
      _mergeEngine.acceptNonConflictingCsv(_csvDiff!.rows);
    }
    notifyListeners();
  }

  /// Returns the merged output document.
  String getMergedOutput() {
    if (isCsv && _csvDiff != null) {
      return _mergeEngine.mergeCsv(_csvDiff!);
    }
    if (_textDiff != null) {
      return _mergeEngine.mergeText(_textDiff!);
    }
    return _localContent;
  }

  /// Pushes local content / delta to the connected peer over the encrypted socket.
  Future<void> pushLocalToPeer() async {
    if (onSendPayload == null) return;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = DiffSessionPayload.build(
        action: DiffPayloadAction.deltaUpdate,
        sessionId: sessionId,
        fileName: documentName,
        mimeType: mimeType,
        content: _localContent,
      );
      await onSendPayload!(payload);
    } catch (e) {
      _errorMessage = 'Could not push update to peer.';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
