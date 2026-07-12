/// Chooses which background document sessions may drop their heavy in-memory
/// state to keep memory in check (Phase 10, task 10.3).
///
/// A "session" here is one open tab's live, heavy state (decoded text, parsed
/// model, editor controller, undo history). The workspace keeps a small budget
/// of sessions loaded and releases the rest; a released session is rebuilt from
/// the file when the user returns to that tab.
///
/// Pure so it is fully testable without widgets. The rules are conservative:
///
///   * the most-recently-used sessions up to [keepAlive] are kept (this budget
///     counts the active and any dirty tab that fall within it),
///   * of the sessions **beyond** the budget, only clean, non-active ones are
///     released,
///   * the **active** tab and any tab with **unsaved edits** are never released,
///     even when they fall beyond the budget (edits are never lost —
///     CLAUDE.md §3.6).
library;

/// Returns the ids of the sessions that should be released now.
///
/// - [liveSessionIds]: ids that currently hold heavy state.
/// - [recencyOrder]: all open tab ids, **most-recently-used first**.
/// - [activeId]: the tab shown right now (never released), or `null`.
/// - [dirtyIds]: tabs with unsaved edits (never released).
/// - [keepAlive]: how many sessions to keep loaded (clamped to at least 1).
List<String> pickReleasableSessions({
  required Iterable<String> liveSessionIds,
  required List<String> recencyOrder,
  required String? activeId,
  required Set<String> dirtyIds,
  required int keepAlive,
}) {
  final budget = keepAlive < 1 ? 1 : keepAlive;
  final live = liveSessionIds.toSet();

  // Walk sessions from most- to least-recently-used. The first [budget] live
  // sessions are kept. Beyond the budget, a clean, non-active session is
  // released; an active or dirty one is kept anyway (never lose edits).
  final ordered = recencyOrder.where(live.contains).toList(growable: false);

  final toRelease = <String>[];
  var kept = 0;
  for (final id in ordered) {
    if (kept < budget) {
      kept++;
      continue;
    }
    final protected = id == activeId || dirtyIds.contains(id);
    if (!protected) toRelease.add(id);
  }

  // A live session not present in the recency list (should not happen) is left
  // alone rather than guessed at.
  return toRelease;
}
