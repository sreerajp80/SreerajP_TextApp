import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
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
import 'package:text_data/formats/json/json_node.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_path.dart';
import 'package:text_data/formats/json/json_stats.dart';
import 'package:text_data/formats/json/json_table.dart';
import 'package:text_data/formats/json/json_well_formed_gate.dart';

/// Loading lifecycle of one open JSON document.
enum JsonLoadStatus { loading, ready, failed }

/// How the JSON document is shown (task 8.1): a colour-coded pretty view, a
/// collapsible tree, the raw source (read-only), a single-line minified view,
/// the source editor, or — for an array of uniform objects — a sortable grid
/// (roadmap §4.3.1).
enum JsonViewMode { pretty, tree, raw, minified, edit, table }

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
class JsonDocumentSession extends ChangeNotifier with ExternalChangeMixin {
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
  final Duration autoSaveInterval;

  /// Fixed save encoding / line ending from Settings › Editor; null = preserve.
  final TextEncodingType? defaultSaveEncoding;
  final LineEndingStyle? defaultSaveLineEnding;

  static const JsonParser _parser = JsonParser();
  static const JsonWellFormedGate _gate = JsonWellFormedGate();

  JsonDocumentSession({
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
    this.defaultSaveEncoding,
    this.defaultSaveLineEnding,
  }) : _draftStoreFuture = draftStore,
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
  bool _positionRestored = false;

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
  @override
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;
  bool get isEditing => _mode == JsonViewMode.edit;

  // --- external change watch (see ExternalChangeMixin) ----------------------

  @override
  SafService get diskSaf => _saf;

  @override
  String get diskUri => tab.uri;

  @override
  void notifyDiskWatch() => _safeNotify();

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
    // Remember what the file looked like on disk, so a change made by another
    // app can be spotted later (see ExternalChangeMixin).
    await captureDiskBaseline();
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

  /// Reads the file again and shows the fresh content (tree and pretty views
  /// included), dropping whatever the tab held. The caller confirms with the user
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

    // Re-parse the tree, validity, and stats for the pretty/tree views.
    _parsedFor = null;
    _ensureParsed();

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
    _mode = JsonViewMode.edit;
    _updateDirty();
    _safeNotify();
  }

  Future<void> discardDraft() async {
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    _safeNotify();
  }

  // --- array as a table (roadmap 4.3.1) ------------------------------------

  /// The JSONPath of the array currently shown as a table. `$` means "whatever
  /// array this document offers", which is resolved fresh on every read so the
  /// grid follows edits.
  String _tablePath = r'$';

  int _tableSortColumn = -1;
  JsonSortDirection _tableSortDirection = JsonSortDirection.none;

  String get tablePath => _tablePath;
  int get tableSortColumn => _tableSortColumn;
  JsonSortDirection get tableSortDirection => _tableSortDirection;

  /// The array node the table view shows: the one [_tablePath] names, or the
  /// document's first usable array when the path is the default `$`.
  JsonNode? get tableNode {
    final node = root;
    if (node == null) return null;
    if (_tablePath != r'$') {
      final result = evaluateJsonPath(node, _tablePath);
      final match = result.matches.isEmpty ? null : result.matches.first;
      if (JsonTable.isTabular(match)) return match;
      // The array the user picked is gone (an edit removed it); fall back
      // rather than showing an error.
    }
    if (JsonTable.isTabular(node)) return node;
    return _firstTabularArray(node);
  }

  /// The current table, or an empty one when this document has no array to
  /// show. Never throws.
  JsonTable get jsonTable => JsonTable.fromNode(tableNode);

  /// True when the document has at least one array the grid can show, so the
  /// toolbar can grey the button out instead of opening an empty screen.
  bool get hasTabularArray => tableNode != null;

  /// Shows [node] as the table and switches to that view.
  void showNodeAsTable(JsonNode node) {
    _tablePath = pathOf(node);
    _tableSortColumn = -1;
    _tableSortDirection = JsonSortDirection.none;
    _mode = JsonViewMode.table;
    _safeNotify();
  }

  /// Goes back to the array the document offers by default.
  void showWholeDocumentAsTable() {
    if (_tablePath == r'$') return;
    _tablePath = r'$';
    _tableSortColumn = -1;
    _tableSortDirection = JsonSortDirection.none;
    _safeNotify();
  }

  /// Cycles the table sort on [column]: ascending → descending → none.
  void sortTableBy(int column) {
    if (_tableSortColumn == column) {
      _tableSortDirection = switch (_tableSortDirection) {
        JsonSortDirection.none => JsonSortDirection.ascending,
        JsonSortDirection.ascending => JsonSortDirection.descending,
        JsonSortDirection.descending => JsonSortDirection.none,
      };
      if (_tableSortDirection == JsonSortDirection.none) _tableSortColumn = -1;
    } else {
      _tableSortColumn = column;
      _tableSortDirection = JsonSortDirection.ascending;
    }
    _safeNotify();
  }

  void clearTableSort() {
    if (_tableSortDirection == JsonSortDirection.none) return;
    _tableSortColumn = -1;
    _tableSortDirection = JsonSortDirection.none;
    _safeNotify();
  }

  /// The first array below [node] that the grid could show, breadth-first so a
  /// top-level record list is preferred over one buried deep.
  static JsonNode? _firstTabularArray(JsonNode node) {
    final queue = <JsonNode>[node];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (JsonTable.isTabular(current)) return current;
      queue.addAll(current.children);
    }
    return null;
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
