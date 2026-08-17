import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:xml/xml.dart';

import 'package:sreerajp_textapp/core/editor/atomic_saver.dart';
import 'package:sreerajp_textapp/core/editor/draft_store.dart';
import 'package:sreerajp_textapp/core/editor/encoding.dart';
import 'package:sreerajp_textapp/core/editor/external_change.dart';
import 'package:sreerajp_textapp/core/editor/saf_save_target.dart';
import 'package:sreerajp_textapp/core/ephemeral/secure_wipe.dart';
import 'package:sreerajp_textapp/core/export/export_target.dart';
import 'package:sreerajp_textapp/core/metadata/file_metadata.dart';
import 'package:sreerajp_textapp/core/storage/key_value_store.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/formats/xml/xml_parser.dart';
import 'package:sreerajp_textapp/formats/xml/xml_path.dart';
import 'package:sreerajp_textapp/formats/xml/xml_stats.dart';
import 'package:sreerajp_textapp/formats/xml/xml_well_formed_gate.dart';

/// Loading lifecycle of one open XML document.
enum XmlLoadStatus { loading, ready, failed }

/// How the XML document is shown (task 9.1): a colour-coded pretty view, a
/// collapsible element tree, the raw source (read-only), or the source editor.
enum XmlViewMode { pretty, tree, raw, edit }

/// The indentation used when the document is re-formatted or saved (task 9.5).
enum XmlIndent { twoSpaces, fourSpaces, tab }

extension XmlIndentInfo on XmlIndent {
  String get unit {
    switch (this) {
      case XmlIndent.twoSpaces:
        return '  ';
      case XmlIndent.fourSpaces:
        return '    ';
      case XmlIndent.tab:
        return '\t';
    }
  }

  String get label {
    switch (this) {
      case XmlIndent.twoSpaces:
        return '2 spaces';
      case XmlIndent.fourSpaces:
        return '4 spaces';
      case XmlIndent.tab:
        return 'Tab';
    }
  }
}

/// One open XML file's live state (Phase 9): the bridge between a shell tab and
/// the on-screen pretty / tree / raw / editor views.
///
/// Mirrors [JsonDocumentSession]: it loads bytes, decodes them (never throwing —
/// CLAUDE.md §3.4), holds the `re_editor` controllers for the source, tracks
/// unsaved edits, drives crash-recovery drafts, and saves through the
/// [AtomicSaver] preserving encoding + line endings (CLAUDE.md §3.5). On top of
/// that it parses the XML for the views and the pre-save gate + validity chip. A
/// plain [ChangeNotifier] with **no Riverpod dependency**, so it is unit-testable.
class XmlDocumentSession extends ChangeNotifier with ExternalChangeMixin {
  final DocumentTab tab;
  final SafService _saf;
  final TextCodecService _codec;
  final AtomicSaver _saver;
  final MetadataService _metadata;
  final KeyValueStore _store;
  final Future<DraftStore> _draftStoreFuture;
  final Future<Directory> _tempDirFuture;

  final void Function(bool isDirty)? onDirtyChanged;

  /// Called with the saved text right after a successful overwrite save, so the
  /// shell can refresh the workspace search index (Feature 11). It must never
  /// throw — the session ignores whatever it returns.
  final void Function(String text)? onSaved;

  /// How often the auto-save draft is written. [Duration.zero] turns it off.
  /// Can change while the tab is open — see [setAutoSaveInterval].
  Duration get autoSaveInterval => _autoSaveInterval;
  Duration _autoSaveInterval;

  /// Fixed save encoding / line ending from Settings › Editor; null = preserve.
  final TextEncodingType? defaultSaveEncoding;
  final LineEndingStyle? defaultSaveLineEnding;

  static const XmlDocumentParser _parser = XmlDocumentParser();
  static const XmlWellFormedGate _gate = XmlWellFormedGate();

  XmlDocumentSession({
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
    this._autoSaveInterval = const Duration(seconds: 5),
    this.defaultSaveEncoding,
    this.defaultSaveLineEnding,
  }) : _draftStoreFuture = draftStore,
       _tempDirFuture = tempDir;

  // --- state ---------------------------------------------------------------

  XmlLoadStatus _status = XmlLoadStatus.loading;
  String? _errorMessage;
  CodeLineEditingController? _code;
  CodeFindController? _find;
  CodeScrollController? _scroll;
  TextEncodingType _encoding = TextEncodingType.utf8;
  LineEndingStyle _lineEnding = LineEndingStyle.lf;
  bool _isWritable = false;
  FileMetadata? _metadataValue;
  XmlViewMode _mode = XmlViewMode.pretty;
  XmlIndent _indent = XmlIndent.twoSpaces;
  bool _isDirty = false;

  Uint8List? _rawBytes;
  String _savedText = '';
  bool _draftAvailable = false;
  DraftStore? _draftStore;
  AutoSaver? _autoSaver;
  bool _disposed = false;
  bool _positionRestored = false;

  // Parse cache, refreshed when the source text changes.
  String? _parsedFor;
  XmlDocument? _document;
  bool _wellFormed = false;
  String? _validationError;
  int? _validationLine;
  List<String> _namespaces = const [];
  XmlStats? _stats;

  XmlLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CodeLineEditingController? get code => _code;
  CodeFindController? get find => _find;
  CodeScrollController? get scroll => _scroll;
  TextEncodingType get encoding => _encoding;
  LineEndingStyle get lineEnding => _lineEnding;
  bool get isWritable => _isWritable;
  FileMetadata? get metadata => _metadataValue;
  XmlViewMode get mode => _mode;
  XmlIndent get indent => _indent;
  @override
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;
  bool get isEditing => _mode == XmlViewMode.edit;

  /// True when the auto-save draft could not be written. The editor shows a
  /// warning so the user knows their work is not being protected right now; the
  /// timer keeps retrying, so this clears itself when a write succeeds.
  bool get autoSaveFailing => _autoSaver?.isFailing ?? false;

  // --- external change watch (see ExternalChangeMixin) ----------------------

  @override
  SafService get diskSaf => _saf;

  @override
  String get diskUri => tab.uri;

  @override
  void notifyDiskWatch() => _safeNotify();

  /// The parsed document used by the pretty and tree views. `null` when the
  /// current text is not well-formed; the raw view still works.
  XmlDocument? get document {
    _ensureParsed();
    return _document;
  }

  /// True when the buffer is well-formed XML (drives the validity chip and
  /// whether a plain Save will pass the gate).
  bool get isWellFormed {
    _ensureParsed();
    return _wellFormed;
  }

  /// A friendly validation message when the buffer is not well-formed.
  String? get validationError {
    _ensureParsed();
    return _validationError;
  }

  int? get validationLine {
    _ensureParsed();
    return _validationLine;
  }

  /// The distinct namespace URIs declared in the document (task 9.4).
  List<String> get namespaces {
    _ensureParsed();
    return _namespaces;
  }

  XmlStats? get stats {
    _ensureParsed();
    return _stats;
  }

  /// The current content as neutral [TextContent] for the shared output services
  /// (share / export / print).
  TextContent get textContent =>
      TextContent(displayName: tab.displayName, text: _code?.text ?? '');

  bool get canUndo => _code?.canUndo ?? false;
  bool get canRedo => _code?.canRedo ?? false;

  String get _positionKey => 'xml.pos.${tab.fingerprint}';

  // --- loading -------------------------------------------------------------

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

    final decoded = _codec.detectAndDecode(_rawBytes!);
    _encoding = decoded.encoding;
    _lineEnding = decoded.lineEnding;
    // Apply the user's fixed save defaults (Settings › Editor); null = preserve.
    if (defaultSaveEncoding != null) _encoding = defaultSaveEncoding!;
    if (defaultSaveLineEnding != null) _lineEnding = defaultSaveLineEnding!;

    _code = CodeLineEditingController.fromText(decoded.text);
    _savedText = decoded.text;
    _code!.clearHistory();
    _code!.addListener(_onCodeChanged);
    _find = CodeFindController(_code!);
    _scroll = CodeScrollController();

    _isWritable = await _saf.isWritable(tab.uri);
    // Remember what the file looked like on disk, so a change made by another
    // app can be spotted later (see ExternalChangeMixin).
    await captureDiskBaseline();
    _ensureParsed();
    _expandRoot();

    _metadataValue = await _metadata.buildWithDates(
      file: SafFile(
        uri: tab.uri,
        displayName: tab.displayName,
        mimeType: tab.mimeType,
        size: tab.size,
      ),
      decoded: decoded,
      formatFields: _metadataFields(),
    );

    _draftStore = await _draftStoreFuture;
    _draftAvailable = await _draftStore!.hasDraft(tab.fingerprint);

    _startAutoSave();

    if (_disposed) return;
    _status = XmlLoadStatus.ready;
    _safeNotify();
  }

  void _fail(String message) {
    _status = XmlLoadStatus.failed;
    _errorMessage = message;
    _safeNotify();
  }

  /// Reads the file again and shows the fresh content (tree view included),
  /// dropping whatever the tab held. The caller confirms with the user first when
  /// the tab has unsaved edits — CLAUDE.md §3.6.
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

    // Re-parse the document and re-open the root, as on a first load.
    _parsedFor = null;
    _ensureParsed();
    _expandRoot();

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
      formatFields: _metadataFields(),
    );

    await markReloaded();
    return true;
  }

  Map<String, String> _metadataFields() {
    final stats = _stats;
    final fields = <String, String>{};
    if (stats != null) {
      fields['Root element'] = stats.rootElement ?? '—';
      fields['Elements'] = '${stats.elementCount}';
      fields['Depth'] = '${stats.maxDepth}';
    }
    final enc = _document == null ? null : _parser.declaredEncoding(_document!);
    if (enc != null) fields['Declared encoding'] = enc;
    return fields;
  }

  // --- view controls -------------------------------------------------------

  void setMode(XmlViewMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _safeNotify();
  }

  void setIndent(XmlIndent indent) {
    if (_indent == indent) return;
    _indent = indent;
    _safeNotify();
  }

  // --- format / minify -----------------------------------------------------

  /// Re-writes the buffer as pretty-printed XML with the chosen indent. No-op
  /// when the document cannot be parsed (task 9.4).
  void formatDocument() {
    final code = _code;
    final doc = document;
    if (code == null || doc == null) return;
    code.text = _parser.pretty(doc, indent: _indent.unit);
    _safeNotify();
  }

  /// Re-writes the buffer as single-line XML. No-op when unparseable (task 9.4).
  void minifyDocument() {
    final code = _code;
    final doc = document;
    if (code == null || doc == null) return;
    code.text = _parser.minify(doc);
    _safeNotify();
  }

  /// Applies a tree-edit result (new full source) to the editor buffer.
  void applySource(String newSource) {
    final code = _code;
    if (code == null) return;
    code.text = newSource;
    _safeNotify();
  }

  // --- saving --------------------------------------------------------------

  void setSaveEncoding(TextEncodingType encoding) {
    if (_encoding == encoding) return;
    _encoding = encoding;
    _safeNotify();
  }

  void setLineEnding(LineEndingStyle lineEnding) {
    if (_lineEnding == lineEnding) return;
    _lineEnding = lineEnding;
    _safeNotify();
  }

  Future<SaveResult> save() async {
    final code = _code;
    if (code == null) return const SaveResult(SaveOutcome.failed);
    final target = await _target();
    final result = await _saver.save(
      code.text,
      target,
      encoding: _encoding,
      lineEnding: _lineEnding,
      gate: _gate,
    );
    if (result.outcome == SaveOutcome.saved) {
      await _markSaved(code.text);
    }
    _safeNotify();
    return result;
  }

  Future<SaveResult> saveAsCopy() async {
    final code = _code;
    if (code == null) return const SaveResult(SaveOutcome.failed);
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
      mimeType: tab.mimeType ?? 'application/xml',
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

  // --- drafts --------------------------------------------------------------

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
    _mode = XmlViewMode.edit;
    _updateDirty();
    _safeNotify();
  }

  Future<void> discardDraft() async {
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    _safeNotify();
  }

  // --- tree expansion + filter (task 9.2, 9.3) -----------------------------

  final Set<String> _expanded = {};
  String _treeFilter = '';

  /// The current tree search/filter text (empty = show everything).
  String get treeFilter => _treeFilter;

  bool isExpanded(String path) => _expanded.contains(path);

  void toggleExpanded(String path) {
    if (!_expanded.remove(path)) _expanded.add(path);
    _safeNotify();
  }

  void expandAll() {
    final doc = document;
    if (doc == null) return;
    _expanded.clear();
    for (final element in doc.descendantElements) {
      if (element.childElements.isNotEmpty) {
        _expanded.add(xmlPathOf(element));
      }
    }
    _expanded.add(xmlPathOf(doc.rootElement));
    _safeNotify();
  }

  void collapseAll() {
    _expanded.clear();
    _expandRoot();
    _safeNotify();
  }

  void setTreeFilter(String filter) {
    if (_treeFilter == filter) return;
    _treeFilter = filter;
    _safeNotify();
  }

  void _expandRoot() {
    final doc = _document;
    if (doc != null) _expanded.add(xmlPathOf(doc.rootElement));
  }

  // --- editing helpers -----------------------------------------------------

  void undo() => _code?.undo();
  void redo() => _code?.redo();
  void openFind() => _find?.findMode();
  void openReplace() => _find?.replaceMode();

  // --- position persistence ------------------------------------------------

  /// Scrolls the editor to the remembered reading position, once. The editor
  /// surface calls this after its first frame: the `re_editor` render object
  /// must be attached for the scroll to take effect, which is not yet the case
  /// during [load]. Safe to call again; only the first call moves the view.
  void restorePositionIntoView() {
    if (_positionRestored) return;
    _positionRestored = true;
    final code = _code;
    if (code == null) return;
    final saved = _store.getInt(_positionKey);
    if (saved != null && saved > 0) {
      final line = saved.clamp(0, code.lineCount - 1);
      final selection = CodeLineSelection.collapsed(index: line, offset: 0);
      code.selection = selection;
      code.makePositionCenterIfInvisible(selection.base);
    }
  }

  void persistPosition() {
    final code = _code;
    if (code != null) {
      _store.setInt(_positionKey, code.selection.startIndex);
    }
  }

  // --- internals -----------------------------------------------------------

  void _ensureParsed() {
    final text = _code?.text ?? '';
    if (_parsedFor == text) return;
    _parsedFor = text;

    final result = _parser.parse(text);
    _wellFormed = result.ok;
    _document = result.document;
    _validationError = result.ok ? null : result.errorMessage;
    _validationLine = result.ok ? null : result.errorLine;

    final doc = _document;
    if (doc != null) {
      _namespaces = _parser.namespaces(doc);
      _stats = XmlStats.of(doc);
    } else {
      _namespaces = const [];
      _stats = null;
    }
  }

  void _onCodeChanged() => _updateDirty();

  void _updateDirty() => _setDirty(_code?.text != _savedText);

  void _setDirty(bool value) {
    if (_isDirty == value) return;
    _isDirty = value;
    onDirtyChanged?.call(value);
    _safeNotify();
  }

  void _startAutoSave() {
    if (_autoSaveInterval <= Duration.zero) return;
    final store = _draftStore;
    final code = _code;
    if (store == null || code == null) return;
    _autoSaver =
        AutoSaver(
            store: store,
            fingerprint: tab.fingerprint,
            getContent: () => code.text,
            onFailingChanged: (_) => _safeNotify(),
          )
          ..markSaved(_savedText)
          ..start(_autoSaveInterval);
  }

  /// Writes the auto-save draft right now instead of waiting for the next tick.
  ///
  /// Called when the app leaves the foreground: Android can kill a paused app at
  /// any moment, and without this the user loses everything typed since the last
  /// tick (CLAUDE.md §3.6). Does nothing when auto-save is switched off.
  Future<void> flushDraft() async {
    await _autoSaver?.tick();
  }

  /// Applies a new auto-save interval to a tab that is already open (task 11.2),
  /// so a changed setting does not wait for the tab to be reopened.
  void setAutoSaveInterval(Duration interval) {
    if (interval == _autoSaveInterval) return;
    _autoSaveInterval = interval;
    _autoSaver?.stop();
    _autoSaver = null;
    if (_status == XmlLoadStatus.ready) _startAutoSave();
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Drops this session's copies of the document from memory. See
  /// `TxtDocumentSession.scrubInMemory` for what this can and cannot promise
  /// (Feature 9).
  void scrubInMemory() {
    SecureWipe.zeroBytes(_rawBytes);
    _rawBytes = null;
    _savedText = '';
    try {
      _code?.text = '';
    } catch (_) {
      // A dispose path must never throw; dropping the references is the point.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    persistPosition();
    _autoSaver?.stop();
    _code?.removeListener(_onCodeChanged);
    // Scrub while the controller is alive but detached from our listener, so
    // clearing it cannot re-enter the dirty-flag path.
    scrubInMemory();
    _find?.dispose();
    _scroll?.dispose();
    _code?.dispose();
    super.dispose();
  }
}
