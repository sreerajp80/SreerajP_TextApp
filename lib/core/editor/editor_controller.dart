import 'undo_redo.dart';

/// A selected span of text, as caret offsets into the document. When [start]
/// equals [end] it is a plain caret (no selection). Offsets are always
/// normalized so `start <= end`.
class EditorSelection {
  final int start;
  final int end;

  const EditorSelection(this.start, this.end);

  const EditorSelection.collapsed(int offset)
      : start = offset,
        end = offset;

  bool get isCollapsed => start == end;
  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is EditorSelection && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// The shared, pure-Dart editing engine every format reuses (architecture.md
/// §6).
///
/// It holds the current [text] and [selection] and applies edits through a
/// command-stack [UndoRedoStack], so undo/redo returns exact prior states. It
/// has **no Flutter dependency** — Phase 4 adds the thin `TextField` binding
/// when the on-screen editor lands. Editing is refused while [readOnly] is set
/// (the read-only lock, task 3.8).
class EditorController {
  String _text;
  EditorSelection _selection;
  final UndoRedoStack _history;

  /// The text as first loaded, used to compute [isDirty].
  String _savedText;

  bool _readOnly;

  /// Called after any change to text, selection, or flags, so a UI layer can
  /// rebuild. Kept as a plain callback to avoid a Flutter dependency.
  void Function()? onChanged;

  EditorController({
    String text = '',
    EditorSelection? selection,
    bool readOnly = false,
    bool coalesceUndo = true,
  })  : _text = text,
        _savedText = text,
        _selection = selection ?? EditorSelection.collapsed(text.length),
        _readOnly = readOnly,
        _history = UndoRedoStack(coalesce: coalesceUndo);

  String get text => _text;
  EditorSelection get selection => _selection;
  bool get readOnly => _readOnly;

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// True when the current text differs from the last saved text.
  bool get isDirty => _text != _savedText;

  /// Moves the caret / selection without changing text. Breaks the typing run so
  /// a caret jump starts a fresh undo step.
  void setSelection(EditorSelection selection) {
    _selection = _clampSelection(selection);
    _history.breakRun();
    _notify();
  }

  /// Turns the read-only lock on or off (task 3.8). While on, [replace],
  /// [insert], [undo], and [redo] are no-ops.
  void setReadOnly(bool value) {
    if (_readOnly == value) return;
    _readOnly = value;
    _notify();
  }

  /// Replaces the characters in `[start, end)` with [replacement] and places the
  /// caret after the inserted text. Records the change for undo. Does nothing
  /// while [readOnly].
  void replace(int start, int end, String replacement) {
    if (_readOnly) return;
    final lo = start < end ? start : end;
    final hi = start < end ? end : start;
    if (lo < 0 || hi > _text.length) {
      throw RangeError('replace range [$lo, $hi) is outside 0..${_text.length}');
    }
    final removed = _text.substring(lo, hi);
    if (removed.isEmpty && replacement.isEmpty) return;

    final command = TextReplacement(
      offset: lo,
      removed: removed,
      inserted: replacement,
    );
    _text = command.applyTo(_text);
    _history.push(command);
    _selection = EditorSelection.collapsed(command.endOffset);
    _notify();
  }

  /// Inserts [textToInsert] at the current caret, replacing any selection.
  void insert(String textToInsert) {
    replace(_selection.start, _selection.end, textToInsert);
  }

  /// Deletes the current selection (no-op when the selection is collapsed).
  void deleteSelection() {
    if (_selection.isCollapsed) return;
    replace(_selection.start, _selection.end, '');
  }

  /// Undoes the most recent change and restores the caret to that edit.
  void undo() {
    if (_readOnly) return;
    final inverse = _history.undo();
    if (inverse == null) return;
    _text = inverse.applyTo(_text);
    _selection = EditorSelection.collapsed(inverse.endOffset);
    _notify();
  }

  /// Redoes the most recently undone change.
  void redo() {
    if (_readOnly) return;
    final command = _history.redo();
    if (command == null) return;
    _text = command.applyTo(_text);
    _selection = EditorSelection.collapsed(command.endOffset);
    _notify();
  }

  /// Replaces the whole document (e.g. after a find-&-replace-all or restoring a
  /// draft). Clears the undo history because it is not a single reversible edit.
  void setText(String newText, {bool markSaved = false}) {
    _text = newText;
    _history.clear();
    _selection = _clampSelection(_selection);
    if (markSaved) _savedText = newText;
    _notify();
  }

  /// Marks the current text as the saved baseline (call after a successful
  /// save), so [isDirty] becomes false. Ends the coalescing run too.
  void markSaved() {
    _savedText = _text;
    _history.breakRun();
    _notify();
  }

  EditorSelection _clampSelection(EditorSelection s) {
    final max = _text.length;
    final start = s.start.clamp(0, max);
    final end = s.end.clamp(0, max);
    return EditorSelection(start < end ? start : end, start < end ? end : start);
  }

  void _notify() => onChanged?.call();
}
