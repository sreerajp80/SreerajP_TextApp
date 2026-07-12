import 'csv_table.dart';

/// Undo/redo for grid edits (task 7.5). The [CsvTable] model is small enough to
/// snapshot per edit, so this keeps a bounded stack of whole-table snapshots
/// rather than diffing. Raw-text editing uses `re_editor`'s own history; this
/// covers the grid side.
///
/// Pure Dart, host-tested.
class CsvTableUndo {
  /// Maximum number of snapshots kept on the undo stack.
  final int limit;

  final List<CsvTable> _undo = [];
  final List<CsvTable> _redo = [];

  CsvTableUndo({this.limit = 100});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Records [before] — the table state *prior* to an edit that is about to be
  /// applied. Clears the redo stack (a new edit branches history).
  void record(CsvTable before) {
    _undo.add(before.clone());
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  /// Returns the state to restore for an undo, given the [current] state (which
  /// is pushed onto the redo stack). Null when there is nothing to undo.
  CsvTable? undo(CsvTable current) {
    if (_undo.isEmpty) return null;
    _redo.add(current.clone());
    return _undo.removeLast();
  }

  /// Returns the state to restore for a redo, given the [current] state (which
  /// is pushed back onto the undo stack). Null when there is nothing to redo.
  CsvTable? redo(CsvTable current) {
    if (_redo.isEmpty) return null;
    _undo.add(current.clone());
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
