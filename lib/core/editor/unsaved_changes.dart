/// What the user chose when leaving a document that has unsaved edits
/// (architecture.md §6, CLAUDE.md §3.6). Edits are never lost silently: every
/// exit path (closing a tab, switching away, exiting) routes through this.
enum UnsavedChangesAction {
  /// Overwrite the original file, then proceed.
  save,

  /// Write a new copy (original untouched), then proceed.
  saveAsCopy,

  /// Throw away the unsaved edits and proceed.
  discard,

  /// Stay on the document; do not leave.
  cancel,
}
