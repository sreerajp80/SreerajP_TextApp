import 'package:sreerajp_textapp/sync/diff/diff_models.dart';

/// Pure Dart diff engine implementing line-level Myers / LCS diffing and
/// word-level inline highlighting.
class TextDiffEngine {
  const TextDiffEngine();

  /// Compares [localText] and [remoteText] line by line, generating hunks and
  /// inline highlights.
  TextDiffResult compare(String localText, String remoteText) {
    final localLines = _splitLines(localText);
    final remoteLines = _splitLines(remoteText);

    // Compute LCS matrix
    final lcs = _computeLcs(localLines, remoteLines);

    final diffLines = <DiffLine>[];
    var i = 0;
    var j = 0;
    var localLineNum = 1;
    var remoteLineNum = 1;

    var added = 0;
    var deleted = 0;
    var modified = 0;
    var unchanged = 0;

    while (i < localLines.length || j < remoteLines.length) {
      if (i < localLines.length &&
          j < remoteLines.length &&
          localLines[i] == remoteLines[j]) {
        diffLines.add(
          DiffLine(
            localLineNumber: localLineNum++,
            remoteLineNumber: remoteLineNum++,
            localText: localLines[i],
            remoteText: remoteLines[j],
            type: DiffType.unchanged,
            localSegments: [InlineSegment(localLines[i])],
            remoteSegments: [InlineSegment(remoteLines[j])],
          ),
        );
        unchanged++;
        i++;
        j++;
      } else if (i < localLines.length &&
          j < remoteLines.length &&
          lcs[i + 1][j] == lcs[i][j + 1]) {
        // Both changed — treat as modified with inline diffing
        final (localSegs, remoteSegs) = _computeInlineSegments(
          localLines[i],
          remoteLines[j],
        );
        diffLines.add(
          DiffLine(
            localLineNumber: localLineNum++,
            remoteLineNumber: remoteLineNum++,
            localText: localLines[i],
            remoteText: remoteLines[j],
            type: DiffType.modified,
            localSegments: localSegs,
            remoteSegments: remoteSegs,
          ),
        );
        modified++;
        i++;
        j++;
      } else if (j < remoteLines.length &&
          (i >= localLines.length || lcs[i][j + 1] >= lcs[i + 1][j])) {
        // Line added in remote
        diffLines.add(
          DiffLine(
            remoteLineNumber: remoteLineNum++,
            remoteText: remoteLines[j],
            type: DiffType.added,
            remoteSegments: [InlineSegment(remoteLines[j], isChanged: true)],
          ),
        );
        added++;
        j++;
      } else if (i < localLines.length &&
          (j >= remoteLines.length || lcs[i + 1][j] > lcs[i][j + 1])) {
        // Line deleted from local
        diffLines.add(
          DiffLine(
            localLineNumber: localLineNum++,
            localText: localLines[i],
            type: DiffType.deleted,
            localSegments: [InlineSegment(localLines[i], isChanged: true)],
          ),
        );
        deleted++;
        i++;
      }
    }

    final hunks = _groupIntoHunks(diffLines);

    return TextDiffResult(
      hunks: hunks,
      lines: diffLines,
      addedCount: added,
      deletedCount: deleted,
      modifiedCount: modified,
      unchangedCount: unchanged,
    );
  }

  static List<String> _splitLines(String text) {
    if (text.isEmpty) return const [];
    // Normalize newlines
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return normalized.split('\n');
  }

  /// Computes the Longest Common Subsequence table for two line lists.
  static List<List<int>> _computeLcs(List<String> a, List<String> b) {
    final m = a.length;
    final n = b.length;
    final lcs = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (var i = m - 1; i >= 0; i--) {
      for (var j = n - 1; j >= 0; j--) {
        if (a[i] == b[j]) {
          lcs[i][j] = 1 + lcs[i + 1][j + 1];
        } else {
          final down = lcs[i + 1][j];
          final right = lcs[i][j + 1];
          lcs[i][j] = down > right ? down : right;
        }
      }
    }
    return lcs;
  }

  /// Groups diff lines into interactive hunks.
  static List<DiffHunk> _groupIntoHunks(List<DiffLine> lines) {
    if (lines.isEmpty) return const [];
    final hunks = <DiffHunk>[];

    var hunkIndex = 1;
    var currentLines = <DiffLine>[];
    DiffType currentType = lines.first.type;
    var startLocal = lines.first.localLineNumber ?? 1;
    var startRemote = lines.first.remoteLineNumber ?? 1;

    for (final line in lines) {
      final lineIsChange = line.type != DiffType.unchanged;
      final currentIsChange = currentType != DiffType.unchanged;

      if (lineIsChange == currentIsChange && currentLines.isNotEmpty) {
        currentLines.add(line);
        if (line.type == DiffType.modified ||
            currentType == DiffType.modified) {
          currentType = DiffType.modified;
        }
      } else {
        if (currentLines.isNotEmpty) {
          hunks.add(
            DiffHunk(
              id: 'hunk_$hunkIndex',
              startLocalLine: startLocal,
              startRemoteLine: startRemote,
              lines: List<DiffLine>.from(currentLines),
              type: currentType,
            ),
          );
          hunkIndex++;
        }
        currentLines = [line];
        currentType = line.type;
        startLocal = line.localLineNumber ?? startLocal;
        startRemote = line.remoteLineNumber ?? startRemote;
      }
    }

    if (currentLines.isNotEmpty) {
      hunks.add(
        DiffHunk(
          id: 'hunk_$hunkIndex',
          startLocalLine: startLocal,
          startRemoteLine: startRemote,
          lines: List<DiffLine>.from(currentLines),
          type: currentType,
        ),
      );
    }

    return hunks;
  }

  /// Computes character/word-level token inline segments for two modified lines.
  static (List<InlineSegment>, List<InlineSegment>) _computeInlineSegments(
    String local,
    String remote,
  ) {
    final localWords = _tokenize(local);
    final remoteWords = _tokenize(remote);

    final lcs = _computeLcs(localWords, remoteWords);

    final localSegs = <InlineSegment>[];
    final remoteSegs = <InlineSegment>[];

    var i = 0;
    var j = 0;

    while (i < localWords.length || j < remoteWords.length) {
      if (i < localWords.length &&
          j < remoteWords.length &&
          localWords[i] == remoteWords[j]) {
        localSegs.add(InlineSegment(localWords[i], isChanged: false));
        remoteSegs.add(InlineSegment(remoteWords[j], isChanged: false));
        i++;
        j++;
      } else if (i < localWords.length &&
          (j >= remoteWords.length || lcs[i + 1][j] >= lcs[i][j + 1])) {
        localSegs.add(InlineSegment(localWords[i], isChanged: true));
        i++;
      } else if (j < remoteWords.length) {
        remoteSegs.add(InlineSegment(remoteWords[j], isChanged: true));
        j++;
      }
    }

    return (_consolidate(localSegs), _consolidate(remoteSegs));
  }

  /// Splits a string into word tokens and whitespace/punctuation delimiters.
  static List<String> _tokenize(String s) {
    if (s.isEmpty) return const [];
    final tokens = <String>[];
    final buffer = StringBuffer();
    bool? inWord;

    for (var k = 0; k < s.length; k++) {
      final ch = s[k];
      final isW = RegExp(r'[a-zA-Z0-9_]').hasMatch(ch);
      if (inWord == null) {
        inWord = isW;
        buffer.write(ch);
      } else if (inWord == isW) {
        buffer.write(ch);
      } else {
        tokens.add(buffer.toString());
        buffer.clear();
        buffer.write(ch);
        inWord = isW;
      }
    }
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }
    return tokens;
  }

  /// Merges adjacent segments with the same change flag.
  static List<InlineSegment> _consolidate(List<InlineSegment> segments) {
    if (segments.isEmpty) return const [];
    final result = <InlineSegment>[];
    var currentText = StringBuffer();
    bool currentChanged = segments.first.isChanged;

    for (final seg in segments) {
      if (seg.isChanged == currentChanged) {
        currentText.write(seg.text);
      } else {
        result.add(
          InlineSegment(currentText.toString(), isChanged: currentChanged),
        );
        currentText = StringBuffer()..write(seg.text);
        currentChanged = seg.isChanged;
      }
    }
    if (currentText.isNotEmpty) {
      result.add(
        InlineSegment(currentText.toString(), isChanged: currentChanged),
      );
    }
    return result;
  }
}
