import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';

import 'package:text_data/core/editor/atomic_saver.dart';
import 'package:text_data/core/editor/draft_store.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/core/editor/external_change.dart';
import 'package:text_data/core/editor/saf_save_target.dart';
import 'package:text_data/core/ephemeral/secure_wipe.dart';
import 'package:text_data/core/export/export_target.dart';
import 'package:text_data/core/metadata/file_metadata.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/formats/txt/txt_content_sniff.dart';
import 'package:text_data/formats/txt/txt_stats.dart';

/// Loading lifecycle of one open TXT document.
enum TxtLoadStatus { loading, ready, failed }

/// One open TXT file's live state: the bridge between a shell tab and the
/// on-screen viewer/editor (Phase 4).
///
/// It loads the bytes, decodes them (never throwing — CLAUDE.md §3.4), holds the
/// `re_editor` [CodeLineEditingController] that the viewer/editor renders, tracks
/// unsaved edits, drives crash-recovery drafts, and saves back through the
/// [AtomicSaver] preserving encoding + line endings (CLAUDE.md §3.5).
///
/// It is a plain [ChangeNotifier] with **no Riverpod dependency**, so it can be
/// unit-tested directly. The async services ([DraftStore], temp dir) are passed
/// as futures and awaited on first use.
class TxtDocumentSession extends ChangeNotifier with ExternalChangeMixin {
  final DocumentTab tab;
  final SafService _saf;
  final TextCodecService _codec;
  final AtomicSaver _saver;
  final MetadataService _metadata;
  final KeyValueStore _store;
  final Future<DraftStore> _draftStoreFuture;
  final Future<Directory> _tempDirFuture;

  /// Called whenever the unsaved-edits flag flips, so the shell can mirror it on
  /// the tab (drives the close guard).
  final void Function(bool isDirty)? onDirtyChanged;

  /// Called with the saved text right after a successful overwrite save, so the
  /// shell can refresh the workspace search index (Feature 11). It must never
  /// throw — the session ignores whatever it returns.
  final void Function(String text)? onSaved;

  /// How often the auto-save draft is written while editing. [Duration.zero]
  /// (or less) turns auto-save off (task 11.2).
  final Duration autoSaveInterval;

  /// Word-wrap state a freshly opened tab starts with (task 11.1).
  final bool initialWordWrap;

  /// Encoding to save with, overriding the detected one, when the user set a
  /// fixed default in Settings › Editor (task 11.2). Null keeps the detected
  /// encoding (preserve).
  final TextEncodingType? defaultSaveEncoding;

  /// Line ending to save with, overriding the detected one, when the user set a
  /// fixed default. Null keeps the detected line ending (preserve).
  final LineEndingStyle? defaultSaveLineEnding;

  TxtDocumentSession({
    required this.tab,
    required this._saf,
    required this._codec,
    required this._saver,
    required this._metadata,
    required this._store,
    required Future<DraftStore> draftStore,
    required Future<Directory> tempDir,
    this.onDirtyChanged,
    this.onSaved,
    this.autoSaveInterval = const Duration(seconds: 5),
    this.initialWordWrap = true,
    this.defaultSaveEncoding,
    this.defaultSaveLineEnding,
  }) : _draftStoreFuture = draftStore,
       _tempDirFuture = tempDir,
       _viewMode = tab.viewMode;

  // --- state ---------------------------------------------------------------

  TxtLoadStatus _status = TxtLoadStatus.loading;
  String? _errorMessage;
  CodeLineEditingController? _code;
  CodeFindController? _find;
  CodeScrollController? _scroll;
  TextEncodingType _encoding = TextEncodingType.utf8;
  LineEndingStyle _lineEnding = LineEndingStyle.lf;
  bool _isWritable = false;
  FileMetadata? _metadataValue;
  late bool _wordWrap = initialWordWrap;
  bool _binaryWarning = false;
  late TabViewMode _viewMode;
  bool _isDirty = false;

  Uint8List? _rawBytes;
  String _savedText = '';
  bool _draftAvailable = false;
  DraftStore? _draftStore;
  AutoSaver? _autoSaver;
  bool _disposed = false;
  bool _positionRestored = false;

  TxtLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CodeLineEditingController? get code => _code;
  CodeFindController? get find => _find;
  CodeScrollController? get scroll => _scroll;
  TextEncodingType get encoding => _encoding;
  LineEndingStyle get lineEnding => _lineEnding;
  bool get isWritable => _isWritable;
  FileMetadata? get metadata => _metadataValue;
  bool get wordWrap => _wordWrap;
  bool get binaryWarning => _binaryWarning;
  TabViewMode get viewMode => _viewMode;
  @override
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;

  // --- external change watch (see ExternalChangeMixin) ----------------------

  @override
  SafService get diskSaf => _saf;

  @override
  String get diskUri => tab.uri;

  @override
  void notifyDiskWatch() => _safeNotify();

  /// Live stats for the current editor content.
  TxtStats get stats => TxtStats.of(_code?.text ?? '');

  /// The current content as the neutral [TextContent] the shared output
  /// services (share / export / print / TTS) consume (Phase 5).
  TextContent get textContent =>
      TextContent(displayName: tab.displayName, text: _code?.text ?? '');

  /// The line the caret sits on (0-based) — used as the remembered reading
  /// position.
  int get currentLine => _code?.selection.startIndex ?? 0;

  bool get canUndo => _code?.canUndo ?? false;
  bool get canRedo => _code?.canRedo ?? false;

  /// Key under which this file's reading position is remembered.
  String get _positionKey => 'txt.pos.${tab.fingerprint}';

  // --- loading -------------------------------------------------------------

  /// Reads and decodes the file, then wires up drafts and auto-save. Safe to
  /// call once; a read failure lands in [TxtLoadStatus.failed] with a friendly
  /// message rather than throwing.
  Future<void> load() async {
    try {
      _rawBytes = await _saf.readBytes(tab.uri);
    } on SafException catch (e) {
      _fail(e.message);
      return;
    } catch (_) {
      _fail('This file could not be opened.');
      return;
    }
    if (_disposed) return;

    final bytes = _rawBytes!;
    _binaryWarning = TxtContentSniff.looksBinary(bytes);

    final decoded = _codec.detectAndDecode(bytes);
    _encoding = decoded.encoding;
    _lineEnding = decoded.lineEnding;
    // Apply the user's fixed save defaults (Settings › Editor), if any. Null
    // means "preserve what the file used" (task 11.2).
    if (defaultSaveEncoding != null) _encoding = defaultSaveEncoding!;
    if (defaultSaveLineEnding != null) _lineEnding = defaultSaveLineEnding!;

    _code = CodeLineEditingController.fromText(decoded.text);
    _savedText = decoded.text;
    _code!.clearHistory(); // the initial load must not be undoable
    _code!.addListener(_onCodeChanged);
    _find = CodeFindController(_code!);
    _scroll = CodeScrollController();

    _isWritable = await _saf.isWritable(tab.uri);
    // Remember what the file looked like on disk, so a change made by another
    // app can be spotted later (see ExternalChangeMixin).
    await captureDiskBaseline();

    _metadataValue = await _metadata.buildWithDates(
      file: SafFile(
        uri: tab.uri,
        displayName: tab.displayName,
        mimeType: tab.mimeType,
        size: tab.size,
      ),
      decoded: decoded,
    );

    // Offer a crash-recovery draft if one is waiting.
    _draftStore = await _draftStoreFuture;
    _draftAvailable = await _draftStore!.hasDraft(tab.fingerprint);

    _startAutoSave();

    if (_disposed) return;
    _status = TxtLoadStatus.ready;
    _safeNotify();
  }

  void _fail(String message) {
    _status = TxtLoadStatus.failed;
    _errorMessage = message;
    _safeNotify();
  }

  /// Reads the file again and shows the fresh content, dropping whatever the tab
  /// held (task: warn on external change). The caller confirms with the user
  /// first when the tab has unsaved edits — CLAUDE.md §3.6.
  ///
  /// Returns false when the read failed; the document is then left untouched.
  @override
  Future<bool> reloadFromDisk() async {
    final code = _code;
    if (code == null) return false;

    Uint8List bytes;
    try {
      bytes = await _saf.readBytes(tab.uri);
    } catch (_) {
      return false;
    }
    if (_disposed) return false;

    _rawBytes = bytes;
    _binaryWarning = TxtContentSniff.looksBinary(bytes);

    final decoded = _codec.detectAndDecode(bytes);
    _encoding = defaultSaveEncoding ?? decoded.encoding;
    _lineEnding = defaultSaveLineEnding ?? decoded.lineEnding;

    // Set the baseline text first: assigning `code.text` fires the change
    // listener, which compares against it to work out the dirty flag.
    _savedText = decoded.text;
    code.text = decoded.text;
    code.clearHistory(); // the reload itself is not undoable
    _setDirty(false);
    _autoSaver?.markSaved(decoded.text);

    // A draft from before the reload belongs to content that is gone.
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;

    _metadataValue = await _metadata.buildWithDates(
      file: SafFile(
        uri: tab.uri,
        displayName: tab.displayName,
        mimeType: tab.mimeType,
        size: bytes.length,
      ),
      decoded: decoded,
    );

    await markReloaded();
    return true;
  }

  // --- view controls -------------------------------------------------------

  void toggleWordWrap() {
    _wordWrap = !_wordWrap;
    _safeNotify();
  }

  void setViewMode(TabViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _safeNotify();
  }

  /// Moves the caret to the start of [lineIndex] (0-based, clamped) and scrolls
  /// it into view.
  void jumpToLine(int lineIndex) {
    final code = _code;
    if (code == null) return;
    final line = lineIndex.clamp(0, code.lineCount - 1);
    final selection = CodeLineSelection.collapsed(index: line, offset: 0);
    code.selection = selection;
    code.makePositionCenterIfInvisible(selection.base);
  }

  // --- encoding switch -----------------------------------------------------

  /// Re-decodes the original bytes as [encoding] and shows the result — the fix
  /// for a file whose encoding was detected wrongly (task 4.4). Treated as a
  /// fresh baseline (not an unsaved edit): the on-disk bytes are unchanged until
  /// the user saves.
  ///
  /// If the document already has **unsaved edits**, re-decoding would discard
  /// them, so this instead only changes the encoding used on the next save (it
  /// falls back to [setSaveEncoding]) and leaves the edited text alone.
  void changeEncoding(TextEncodingType encoding) {
    final code = _code;
    final raw = _rawBytes;
    if (code == null || raw == null || encoding == _encoding) return;
    if (_isDirty) {
      setSaveEncoding(encoding);
      return;
    }
    final decoded = _codec.decodeAs(raw, encoding);
    _encoding = encoding;
    code.text = decoded;
    code.clearHistory();
    _savedText = decoded;
    _setDirty(false);
    _safeNotify();
  }

  /// Sets the encoding used to **write** the file on the next save, without
  /// re-decoding the text in memory (task 4.2). The characters are already
  /// Unicode, so this only affects the bytes produced on save.
  void setSaveEncoding(TextEncodingType encoding) {
    if (_encoding == encoding) return;
    _encoding = encoding;
    _safeNotify();
  }

  /// Sets the line-ending style used on the next save.
  void setLineEnding(LineEndingStyle lineEnding) {
    if (_lineEnding == lineEnding) return;
    _lineEnding = lineEnding;
    _safeNotify();
  }

  // --- drafts --------------------------------------------------------------

  /// Replaces the editor content with the saved draft (crash recovery).
  Future<void> restoreDraft() async {
    final store = _draftStore;
    final code = _code;
    if (store == null || code == null) return;
    final draft = await store.load(tab.fingerprint);
    if (draft == null) {
      _draftAvailable = false;
      _safeNotify();
      return;
    }
    code.text = draft;
    code.clearHistory();
    _draftAvailable = false;
    _viewMode = TabViewMode.edit;
    _updateDirty();
    _safeNotify();
  }

  /// Throws the saved draft away and keeps the loaded file content.
  Future<void> discardDraft() async {
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    _safeNotify();
  }

  // --- saving --------------------------------------------------------------

  /// Overwrites the original file with the current text, preserving (or using
  /// the chosen) encoding + line ending. Returns the [SaveResult] so the UI can
  /// show the outcome. On success the draft is cleared and the baseline reset.
  Future<SaveResult> save() async {
    final code = _code;
    if (code == null) {
      return const SaveResult(SaveOutcome.failed);
    }
    final target = await _target();
    final result = await _saver.save(
      code.text,
      target,
      encoding: _encoding,
      lineEnding: _lineEnding,
    );
    if (result.outcome == SaveOutcome.saved) {
      await _markSaved(code.text);
    }
    _safeNotify();
    return result;
  }

  /// Writes the current text to a new file chosen by the user, leaving the
  /// original untouched.
  Future<SaveResult> saveAsCopy() async {
    final code = _code;
    if (code == null) {
      return const SaveResult(SaveOutcome.failed);
    }
    final target = await _target();
    try {
      return await _saver.saveAsCopy(
        code.text,
        target,
        tab.displayName,
        encoding: _encoding,
        lineEnding: _lineEnding,
      );
    } on SafCancelled {
      return const SaveResult(SaveOutcome.cancelled);
    }
  }

  Future<SafSaveTarget> _target() async {
    final tempDir = await _tempDirFuture;
    return SafSaveTarget(
      saf: _saf,
      uri: tab.uri,
      canOverwrite: _isWritable,
      tempDir: tempDir,
      mimeType: tab.mimeType ?? 'text/plain',
    );
  }

  Future<void> _markSaved(String text) async {
    _savedText = text;
    _setDirty(false);
    _autoSaver?.markSaved(text);
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    // The file on disk is now ours again — never warn about our own write.
    await captureDiskBaseline();
    onSaved?.call(text);
  }

  void undo() => _code?.undo();
  void redo() => _code?.redo();

  /// Opens the built-in find bar.
  void openFind() => _find?.findMode();

  /// Opens the built-in find-and-replace bar (no-op on a read-only tab, since
  /// the caller only shows it in edit mode).
  void openReplace() => _find?.replaceMode();

  // --- position persistence ------------------------------------------------

  /// Scrolls the editor to the remembered reading position, once. The editor
  /// surface calls this after its first frame: the `re_editor` render object
  /// must be attached for the scroll to take effect, which is not yet the case
  /// during [load]. Safe to call again; only the first call moves the view.
  void restorePositionIntoView() {
    if (_positionRestored) return;
    _positionRestored = true;
    if (_code == null) return;
    final saved = _store.getInt(_positionKey);
    if (saved != null && saved > 0) {
      jumpToLine(saved);
    }
  }

  /// Remembers the current reading position (best-effort; fire-and-forget).
  void persistPosition() {
    _store.setInt(_positionKey, currentLine);
  }

  // --- internals -----------------------------------------------------------

  void _onCodeChanged() {
    _updateDirty();
  }

  void _updateDirty() {
    _setDirty(_code?.text != _savedText);
  }

  void _setDirty(bool value) {
    if (_isDirty == value) return;
    _isDirty = value;
    onDirtyChanged?.call(value);
    _safeNotify();
  }

  void _startAutoSave() {
    // A zero/negative interval means auto-save is turned off in Settings.
    if (autoSaveInterval <= Duration.zero) return;
    final store = _draftStore;
    final code = _code;
    if (store == null || code == null) return;
    _autoSaver =
        AutoSaver(
            store: store,
            fingerprint: tab.fingerprint,
            getContent: () => code.text,
          )
          ..markSaved(_savedText)
          ..start(autoSaveInterval);
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Drops this session's copies of the document from memory.
  ///
  /// The raw file bytes are a [Uint8List], which is mutable, so
  /// [SecureWipe.zeroBytes] genuinely overwrites them. The decoded text is a
  /// Dart [String] — immutable and garbage-collected — so the only thing
  /// possible there is to drop every reference and let the collector reclaim
  /// it. Nothing in the app claims more than that.
  ///
  /// Run on every dispose, not only for ephemeral tabs (Feature 9): it costs
  /// almost nothing and it means a closed tab stops holding a document in RAM.
  void scrubInMemory() {
    SecureWipe.zeroBytes(_rawBytes);
    _rawBytes = null;
    _savedText = '';
    try {
      _code?.text = '';
    } catch (_) {
      // The controller may already be torn down; dropping the reference below
      // is what matters, and a dispose path must never throw.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    persistPosition();
    _autoSaver?.stop();
    _code?.removeListener(_onCodeChanged);
    // Scrub while the controller is still alive but no longer feeding our
    // listener, so clearing it cannot re-enter the dirty-flag path. Runs after
    // persistPosition() above, which needs the caret.
    scrubInMemory();
    _find?.dispose();
    _scroll?.dispose();
    _code?.dispose();
    super.dispose();
  }
}
