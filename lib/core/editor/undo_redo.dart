/// A single reversible text change: replace the characters in
/// `[offset, offset + removed.length)` with [inserted].
///
/// Only the changed slices are stored (not the whole document), so an undo
/// history over a large file stays light (architecture.md §6). [invert] returns
/// the command that undoes this one.
class TextReplacement {
  /// Start of the replaced range in the text *before* this command applied.
  final int offset;

  /// The exact characters that were removed (so undo can put them back).
  final String removed;

  /// The characters that were inserted.
  final String inserted;

  const TextReplacement({
    required this.offset,
    required this.removed,
    required this.inserted,
  });

  /// Applies this replacement to [text] and returns the new text.
  String applyTo(String text) {
    return text.replaceRange(offset, offset + removed.length, inserted);
  }

  /// The command that reverses this one.
  TextReplacement invert() {
    return TextReplacement(
      offset: offset,
      removed: inserted,
      inserted: removed,
    );
  }

  /// The caret position after this command applies (end of the inserted text).
  int get endOffset => offset + inserted.length;

  /// True when this is a pure insertion of typed characters right after the
  /// previous one — used to coalesce fast typing into one undo step.
  bool _isSimpleInsertAfter(TextReplacement previous) {
    final noDeletion = removed.isEmpty && previous.removed.isEmpty;
    final contiguous = offset == previous.endOffset;
    final noNewline = !inserted.contains('\n');
    return noDeletion && contiguous && noNewline && inserted.isNotEmpty;
  }

  /// Merges a follow-on typing command onto this one (caller must have checked
  /// they are coalescable).
  TextReplacement _mergeInsert(TextReplacement next) {
    return TextReplacement(
      offset: offset,
      removed: removed,
      inserted: inserted + next.inserted,
    );
  }
}

/// A command-stack undo/redo history for text edits.
///
/// Pushing a command clears the redo stack. Consecutive single-character-style
/// typing coalesces into one entry so undo removes a word's worth at a time and
/// stays responsive. This holds *only* the commands, never document snapshots.
class UndoRedoStack {
  final List<TextReplacement> _undo = [];
  final List<TextReplacement> _redo = [];

  /// Whether coalescing of adjacent typing is allowed. Disable it to force each
  /// command to be its own undo step (useful in tests).
  final bool coalesce;

  /// False after [breakRun] until the next non-coalesced push, so the current
  /// typing run cannot absorb further characters.
  bool _runOpen = true;

  UndoRedoStack({this.coalesce = true});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  int get undoDepth => _undo.length;
  int get redoDepth => _redo.length;

  /// Records [command] as the newest change. Clears the redo history.
  void push(TextReplacement command) {
    _redo.clear();
    if (coalesce && _runOpen && _undo.isNotEmpty) {
      final last = _undo.last;
      if (command._isSimpleInsertAfter(last)) {
        _undo[_undo.length - 1] = last._mergeInsert(command);
        return;
      }
    }
    _undo.add(command);
    _runOpen = true;
  }

  /// Pops the newest change and returns the command that reverses it (already
  /// moved onto the redo stack), or null when there is nothing to undo.
  TextReplacement? undo() {
    if (_undo.isEmpty) return null;
    final command = _undo.removeLast();
    _redo.add(command);
    return command.invert();
  }

  /// Re-applies the most recently undone change and returns it (moved back onto
  /// the undo stack), or null when there is nothing to redo.
  TextReplacement? redo() {
    if (_redo.isEmpty) return null;
    final command = _redo.removeLast();
    _undo.add(command);
    return command;
  }

  /// Ends the current coalescing run so the next typed character starts a fresh
  /// undo step (call on caret jumps, blur, save, etc.). Contiguity already
  /// breaks a run on a caret move; this is for explicit callers.
  void breakRun() {
    _runOpen = false;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
    _runOpen = true;
  }
}
