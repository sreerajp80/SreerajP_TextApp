import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:xml/xml.dart';

import '../../core/editor/atomic_saver.dart';
import '../../core/editor/draft_store.dart';
import '../../core/editor/encoding.dart';
import '../../core/editor/saf_save_target.dart';
import '../../core/export/export_target.dart';
import '../../core/metadata/file_metadata.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../shell/tabs/document_tab.dart';
import 'xml_parser.dart';
import 'xml_path.dart';
import 'xml_stats.dart';
import 'xml_well_formed_gate.dart';

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
class XmlDocumentSession extends ChangeNotifier {
  final DocumentTab tab;
  final SafService _saf;
  final TextCodecService _codec;
  final AtomicSaver _saver;
  final MetadataService _metadata;
  final KeyValueStore _store;
  final Future<DraftStore> _draftStoreFuture;
  final Future<Directory> _tempDirFuture;

  final void Function(bool isDirty)? onDirtyChanged;

  /// How often the auto-save draft is written. [Duration.zero] turns it off.
  final Duration autoSaveInterval;

  /// Fixed save encoding / line ending from Settings › Editor; null = preserve.
  final TextEncodingType? defaultSaveEncoding;
  final LineEndingStyle? defaultSaveLineEnding;

  static const XmlDocumentParser _parser = XmlDocumentParser();
  static const XmlWellFormedGate _gate = XmlWellFormedGate();

  XmlDocumentSession({
    required this.tab,
    required SafService saf,
    required TextCodecService codec,
    required AtomicSaver saver,
    required MetadataService metadata,
    required KeyValueStore store,
    required Future<DraftStore> draftStore,
    required Future<Directory> tempDir,
    this.onDirtyChanged,
    this.autoSaveInterval = const Duration(seconds: 5),
    this.defaultSaveEncoding,
    this.defaultSaveLineEnding,
  })  : _saf = saf,
        _codec = codec,
        _saver = saver,
        _metadata = metadata,
        _store = store,
        _draftStoreFuture = draftStore,
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
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;
  bool get isEditing => _mode == XmlViewMode.edit;

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

    _restorePosition();
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

  void _restorePosition() {
    final saved = _store.getInt(_positionKey);
    final code = _code;
    if (saved != null && saved > 0 && code != null) {
      final line = saved.clamp(0, code.lineCount - 1);
      code.selection = CodeLineSelection.collapsed(index: line, offset: 0);
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
    if (autoSaveInterval <= Duration.zero) return;
    final store = _draftStore;
    final code = _code;
    if (store == null || code == null) return;
    _autoSaver = AutoSaver(
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

  @override
  void dispose() {
    _disposed = true;
    persistPosition();
    _autoSaver?.stop();
    _code?.removeListener(_onCodeChanged);
    _find?.dispose();
    _scroll?.dispose();
    _code?.dispose();
    super.dispose();
  }
}
