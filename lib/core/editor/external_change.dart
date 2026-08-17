import 'package:flutter/foundation.dart';

import 'package:sreerajp_textapp/core/storage/saf_service.dart';

/// What the shell needs from an open document to warn that the file changed on
/// disk and to offer a reload.
///
/// Every format session implements this through [ExternalChangeMixin], so the
/// warning banner works for any format without knowing which one it is showing.
abstract class ReloadableDocument implements Listenable {
  /// True when the file on disk changed after this document was loaded and the
  /// user has not dealt with it yet.
  bool get externalChangeDetected;

  /// True when the document holds unsaved edits (a reload would throw them away).
  bool get isDirty;

  /// Asks the file system whether the file changed. Cheap: it compares one
  /// timestamp and never re-reads the content. Never throws.
  Future<void> checkForExternalChange();

  /// Accepts the current content and hides the warning. The same change is not
  /// reported again; a *later* change warns again.
  void dismissExternalChange();

  /// Loads the file content again, replacing what the document holds. Returns
  /// false when the read failed, in which case nothing changed.
  Future<bool> reloadFromDisk();
}

/// Shared "the file changed on disk" logic for the format sessions.
///
/// How it works: at load time the session remembers the file's last-modified
/// time (`SafService.modifiedTime`). A later check asks for the timestamp again;
/// a different value means some other app wrote the file.
///
/// Two rules keep the warning trustworthy:
///
/// * If the provider does not report a modified time (`null`), detection is
///   **skipped**. A missing timestamp must never produce a false warning.
/// * The baseline is re-captured after every save, reload, and dismiss, so the
///   app never warns about **its own** write.
///
/// The session must provide [diskSaf], [diskUri], and [notifyDiskWatch] (which
/// should be the session's dispose-safe notify), and implement
/// [reloadFromDisk] — the only part that depends on the format.
mixin ExternalChangeMixin implements ReloadableDocument {
  /// File access used for the timestamp checks.
  SafService get diskSaf;

  /// URI of the file this document was loaded from.
  String get diskUri;

  /// Tells listeners something changed. Sessions pass their dispose-safe notify
  /// so a check that finishes after the tab closed is harmless.
  void notifyDiskWatch();

  int? _diskStamp;
  bool _externalChange = false;

  @override
  bool get externalChangeDetected => _externalChange;

  /// Records the file's current timestamp as "what this document matches".
  /// Call it after the first load, after a successful save, and after a reload.
  Future<void> captureDiskBaseline() async {
    _diskStamp = await diskSaf.modifiedTime(diskUri);
  }

  @override
  Future<void> checkForExternalChange() async {
    if (_externalChange) return; // already warned; nothing new to say
    final baseline = _diskStamp;
    if (baseline == null) return; // no timestamp to compare against
    final current = await diskSaf.modifiedTime(diskUri);
    if (current == null || current == baseline) return;
    _externalChange = true;
    notifyDiskWatch();
  }

  @override
  void dismissExternalChange() {
    if (!_externalChange) return;
    _externalChange = false;
    notifyDiskWatch();
    // Move the baseline forward so this change is not reported again. Fire and
    // forget: a failed timestamp read only means the next check does nothing.
    captureDiskBaseline();
  }

  /// Clears the warning and re-captures the baseline. The format's
  /// [reloadFromDisk] calls this once the new content is in place.
  Future<void> markReloaded() async {
    _externalChange = false;
    await captureDiskBaseline();
    notifyDiskWatch();
  }
}
