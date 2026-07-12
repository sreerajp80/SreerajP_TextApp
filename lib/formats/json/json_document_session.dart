import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

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
import 'json_node.dart';
import 'json_parser.dart';
import 'json_path.dart';
import 'json_stats.dart';
import 'json_well_formed_gate.dart';

/// Loading lifecycle of one open JSON document.
enum JsonLoadStatus { loading, ready, failed }

/// How the JSON document is shown (task 8.1): a colour-coded pretty view, a
/// collapsible tree, the raw source (read-only), a single-line minified view, or
/// the source editor.
enum JsonViewMode { pretty, tree, raw, minified, edit }

/// The indentation used when the document is re-formatted or saved (task 8.5).
enum JsonIndent { twoSpaces, fourSpaces, tab }

extension JsonIndentInfo on JsonIndent {
  String get unit {
    switch (this) {
      case JsonIndent.twoSpaces:
        return '  ';
      case JsonIndent.fourSpaces:
        return '    ';
      case JsonIndent.tab:
        return '\t';
    }
  }

  String get label {
    switch (this) {
      case JsonIndent.twoSpaces:
        return '2 spaces';
      case JsonIndent.fourSpaces:
        return '4 spaces';
      case JsonIndent.tab:
        return 'Tab';
    }
  }
}

/// One open JSON file's live state (Phase 8): the bridge between a shell tab and
/// the on-screen pretty / tree / raw / minified / editor views.
///
/// Mirrors [MdDocumentSession]: it loads bytes, decodes them (never throwing —
/// CLAUDE.md §3.4), holds the `re_editor` controllers for the source, tracks
/// unsaved edits, drives crash-recovery drafts, and saves through the
/// [AtomicSaver] preserving encoding + line endings (CLAUDE.md §3.5). On top of
/// that it parses the JSON — leniently for the views (so a JSONC file still
/// shows) and strictly for the pre-save gate + validity indicator. A plain
/// [ChangeNotifier] with **no Riverpod dependency**, so it is unit-testable.
class JsonDocumentSession extends ChangeNotifier {
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

  static const JsonParser _parser = JsonParser();
  static const JsonWellFormedGate _gate = JsonWellFormedGate();

  JsonDocumentSession({
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

  JsonLoadStatus _status = JsonLoadStatus.loading;
  String? _errorMessage;
  CodeLineEditingController? _code;
  CodeFindController? _find;
  CodeScrollController? _scroll;
  TextEncodingType _encoding = TextEncodingType.utf8;
  LineEndingStyle _lineEnding = LineEndingStyle.lf;
  bool _isWritable = false;
  FileMetadata? _metadataValue;
  JsonViewMode _mode = JsonViewMode.pretty;
  JsonIndent _indent = JsonIndent.twoSpaces;
  bool _isDirty = false;

  Uint8List? _rawBytes;
  String _savedText = '';
  bool _draftAvailable = false;
  DraftStore? _draftStore;
  AutoSaver? _autoSaver;
  bool _disposed = false;

  // Parse cache, refreshed when the source text changes.
  String? _parsedFor;
  JsonNode? _root;
  bool _wellFormedStrict = false;
  bool _lenientOnly = false;
  String? _validationError;
  int? _validationLine;
  bool _isNdjson = false;
  int _ndjsonCount = 0;
  JsonStats? _stats;

  JsonLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CodeLineEditingController? get code => _code;
  CodeFindController? get find => _find;
  CodeScrollController? get scroll => _scroll;
  TextEncodingType get encoding => _encoding;
  LineEndingStyle get lineEnding => _lineEnding;
  bool get isWritable => _isWritable;
  FileMetadata? get metadata => _metadataValue;
  JsonViewMode get mode => _mode;
  JsonIndent get indent => _indent;
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;
  bool get isEditing => _mode == JsonViewMode.edit;

  /// The parsed tree used by the pretty and tree views. `null` when the current
  /// text cannot be read at all (a broken document); the raw view still works.
  JsonNode? get root {
    _ensureParsed();
    return _root;
  }

  /// True when the buffer is strict, well-formed JSON (drives the validity chip
  /// and whether a plain Save will pass the gate).
  bool get isWellFormed {
    _ensureParsed();
    return _wellFormedStrict;
  }

  /// True when the file was read leniently (comments / trailing commas / single
  /// quotes) and is not yet strict — so the user is told it will be saved as
  /// strict JSON (task 8.4).
  bool get lenientOnly {
    _ensureParsed();
    return _lenientOnly;
  }

  /// A friendly validation message when the buffer is not strict JSON.
  String? get validationError {
    _ensureParsed();
    return _validationError;
  }

  int? get validationLine {
    _ensureParsed();
    return _validationLine;
  }

  /// True when the document looks like NDJSON (newline-delimited records).
  bool get isNdjson {
    _ensureParsed();
    return _isNdjson;
  }

  int get ndjsonCount {
    _ensureParsed();
    return _ndjsonCount;
  }

  JsonStats? get stats {
    _ensureParsed();
    return _stats;
  }

  /// The current content as neutral [TextContent] for the shared output services
  /// (share / export / print).
  TextContent get textContent =>
      TextContent(displayName: tab.displayName, text: _code?.text ?? '');

  bool get canUndo => _code?.canUndo ?? false;
  bool get canRedo => _code?.canRedo ?? false;

  String get _positionKey => 'json.pos.${tab.fingerprint}';

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
    _status = JsonLoadStatus.ready;
    _safeNotify();
  }

  void _fail(String message) {
    _status = JsonLoadStatus.failed;
    _errorMessage = message;
    _safeNotify();
  }

  Map<String, String> _metadataFields() {
    final stats = _stats;
    if (stats == null) return const {};
    return {
      'Top-level type': stats.topLevelType.label,
      'Items': '${stats.topLevelItemCount}',
      'Keys': '${stats.keyCount}',
      'Depth': '${stats.maxDepth}',
    };
  }

  // --- view controls -------------------------------------------------------

  void setMode(JsonViewMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _safeNotify();
  }

  void setIndent(JsonIndent indent) {
    if (_indent == indent) return;
    _indent = indent;
    _safeNotify();
  }

  // --- format / minify -----------------------------------------------------

  /// Re-writes the buffer as strict, indented JSON. This also drops JSONC
  /// comments and trailing commas, so a leniently-read file becomes strict
  /// (task 8.4). No-op when the document cannot be parsed.
  void formatDocument() {
    final code = _code;
    final node = root;
    if (code == null || node == null) return;
    code.text = prettyPrintJson(node, indent: _indent.unit);
    _safeNotify();
  }

  /// Re-writes the buffer as strict, single-line JSON. No-op when unparseable.
  void minifyDocument() {
    final code = _code;
    final node = root;
    if (code == null || node == null) return;
    code.text = minifyJson(node);
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
      mimeType: tab.mimeType ?? 'application/json',
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
    _mode = JsonViewMode.edit;
    _updateDirty();
    _safeNotify();
  }

  Future<void> discardDraft() async {
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    _safeNotify();
  }

  // --- tree expansion + filter (task 8.2, 8.3) -----------------------------

  final Set<String> _expanded = {r'$'};
  String _treeFilter = '';

  /// The current tree search/filter text (empty = show everything).
  String get treeFilter => _treeFilter;

  bool isExpanded(String path) => _expanded.contains(path);

  void toggleExpanded(String path) {
    if (!_expanded.remove(path)) _expanded.add(path);
    _safeNotify();
  }

  void expandAll() {
    final node = root;
    if (node == null) return;
    _expanded.clear();
    _collectContainerPaths(node, _expanded);
    _safeNotify();
  }

  void collapseAll() {
    _expanded
      ..clear()
      ..add(r'$');
    _safeNotify();
  }

  void setTreeFilter(String filter) {
    if (_treeFilter == filter) return;
    _treeFilter = filter;
    _safeNotify();
  }

  void _collectContainerPaths(JsonNode node, Set<String> into) {
    if (node.isContainer) into.add(pathOf(node));
    for (final child in node.children) {
      _collectContainerPaths(child, into);
    }
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

    final strict = _parser.parse(text);
    _wellFormedStrict = strict.ok;
    _validationError = strict.ok ? null : strict.errorMessage;
    _validationLine = strict.ok ? null : strict.errorLine;

    final lenient = _parser.parse(text, lenient: true);
    _lenientOnly = lenient.ok && !strict.ok;

    _isNdjson = false;
    _ndjsonCount = 0;
    if (lenient.ok) {
      _root = lenient.root;
    } else if (_parser.looksLikeNdjson(text)) {
      final records = _parser.parseNdjson(text);
      _ndjsonCount = records.length;
      _isNdjson = true;
      _root = _ndjsonRoot(records);
      // NDJSON is valid as a record set, even though it is not one JSON value.
      _validationError = null;
      _validationLine = null;
    } else {
      _root = null;
    }

    final node = _root;
    _stats = node == null ? null : JsonStats.of(node);
  }

  /// Wraps NDJSON records in a synthetic array so the tree / pretty views can
  /// show them as an ordered record list (task 8.4).
  JsonNode _ndjsonRoot(List<NdjsonRecord> records) {
    final children = <JsonNode>[];
    var i = 0;
    for (final record in records) {
      final node = record.node;
      if (node == null) continue;
      node.index = i;
      children.add(node);
      i++;
    }
    final array = JsonNode(
      kind: JsonKind.array,
      start: 0,
      end: 0,
      children: children,
    );
    for (final child in children) {
      child.parent = array;
    }
    return array;
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
