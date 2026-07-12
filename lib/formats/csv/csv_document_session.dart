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
import 'csv_dialect.dart';
import 'csv_filter_sort.dart';
import 'csv_parse.dart';
import 'csv_table.dart';
import 'csv_table_undo.dart';
import 'csv_types.dart';

/// Loading lifecycle of one open CSV document.
enum CsvLoadStatus { loading, ready, failed }

/// How the CSV is shown: the data grid or the raw delimited text.
enum CsvViewMode { table, raw }

/// One open CSV file's live state (Phase 7): the bridge between a shell tab and
/// the grid / raw views.
///
/// Mirrors [MdDocumentSession], but the **source of truth is a [CsvTable]**, not
/// a text string. The grid edits the table directly (with a snapshot undo/redo
/// stack); the raw view is a `re_editor` surface bound to the table's
/// serialization and re-parsed back into the table when the user leaves raw mode
/// or saves. It loads bytes, decodes them (never throwing — CLAUDE.md §3.4),
/// tracks unsaved edits, drives crash-recovery drafts, and saves through the
/// [AtomicSaver] preserving encoding + line endings + dialect (CLAUDE.md §3.5).
/// A plain [ChangeNotifier] with **no Riverpod dependency**, so it is
/// unit-testable directly.
class CsvDocumentSession extends ChangeNotifier {
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

  CsvDocumentSession({
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

  CsvLoadStatus _status = CsvLoadStatus.loading;
  String? _errorMessage;
  CsvTable _table = CsvTable.empty();
  CsvDialect _dialect = const CsvDialect();
  TextEncodingType _encoding = TextEncodingType.utf8;
  bool _isWritable = false;
  FileMetadata? _metadataValue;
  CsvViewMode _mode = CsvViewMode.table;
  bool _isDirty = false;

  final CsvTableUndo _undo = CsvTableUndo();

  // Grid view state (kept on the session so it survives tab switches).
  String _filterQuery = '';
  int? _sortColumn;
  SortDirection _sortDirection = SortDirection.none;
  final Set<int> _hiddenColumns = {};
  bool _freezeHeader = true;
  bool _freezeFirstColumn = false;
  final Set<int> _selectedRows = {};

  // Raw-mode editor controllers, created lazily on first entry to raw mode.
  CodeLineEditingController? _code;
  CodeFindController? _find;
  CodeScrollController? _scroll;

  String _savedText = '';
  bool _draftAvailable = false;
  DraftStore? _draftStore;
  AutoSaver? _autoSaver;
  bool _disposed = false;

  CsvLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CsvTable get table => _table;
  CsvDialect get dialect => _dialect;
  TextEncodingType get encoding => _encoding;
  LineEndingStyle get lineEnding => _dialect.lineEnding;
  bool get isWritable => _isWritable;
  FileMetadata? get metadata => _metadataValue;
  CsvViewMode get mode => _mode;
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;

  CodeLineEditingController? get code => _code;
  CodeFindController? get find => _find;
  CodeScrollController? get scroll => _scroll;

  String get filterQuery => _filterQuery;
  int? get sortColumn => _sortColumn;
  SortDirection get sortDirection => _sortDirection;
  Set<int> get hiddenColumns => _hiddenColumns;
  bool get freezeHeader => _freezeHeader;
  bool get freezeFirstColumn => _freezeFirstColumn;
  Set<int> get selectedRows => _selectedRows;

  bool get canUndo =>
      _mode == CsvViewMode.raw ? (_code?.canUndo ?? false) : _undo.canUndo;
  bool get canRedo =>
      _mode == CsvViewMode.raw ? (_code?.canRedo ?? false) : _undo.canRedo;

  /// The current CSV text (grid serialization, or the raw editor buffer when in
  /// raw mode). Newlines are `\n`; the real line ending is applied on save.
  String get currentText {
    if (_mode == CsvViewMode.raw && _code != null) return _code!.text;
    return _table.toCsv(_dialect);
  }

  /// The current content as neutral [TextContent] for the shared output
  /// services (share / export / print).
  TextContent get textContent =>
      TextContent(displayName: tab.displayName, text: currentText);

  /// [TextContent] holding only [rowIndices] (original row order preserved),
  /// used to export/copy the selected or filtered rows only (task 7.6).
  TextContent textContentForRows(List<int> rowIndices) {
    final subset = CsvTable(
      header: List<String>.from(_table.header),
      rows: [
        for (final i in rowIndices)
          if (i >= 0 && i < _table.rowCount) List<String>.from(_table.rows[i]),
      ],
      hasHeader: _table.hasHeader,
    );
    return TextContent(
      displayName: tab.displayName,
      text: subset.toCsv(_dialect),
    );
  }

  /// The visible row indices after applying the current filter then sort. The
  /// grid renders rows in this order; edits still address the original rows.
  List<int> get visibleRowIndices {
    final filtered = CsvFilterSort.filter(_table, _filterQuery);
    if (_sortColumn == null || _sortDirection == SortDirection.none) {
      return filtered;
    }
    return CsvFilterSort.sort(_table, filtered, _sortColumn!, _sortDirection);
  }

  // A one-shot jump target (original row index) the grid consumes and clears.
  int? _pendingJumpRow;
  int? get pendingJumpRow => _pendingJumpRow;

  /// Asks the grid to scroll so [row] (0-based original index) is visible.
  void requestJumpToRow(int row) {
    _pendingJumpRow = row;
    _safeNotify();
  }

  void clearPendingJump() => _pendingJumpRow = null;

  String get _positionKey => 'csv.pos.${tab.fingerprint}';

  // --- loading -------------------------------------------------------------

  Future<void> load() async {
    Uint8List bytes;
    try {
      bytes = await _saf.readBytes(tab.uri);
    } on SafException catch (e) {
      _fail(e.message);
      return;
    } catch (_) {
      _fail('This file could not be opened.');
      return;
    }
    if (_disposed) return;

    final decoded = _codec.detectAndDecode(bytes);
    // Apply the user's fixed save defaults (Settings › Editor); null = preserve.
    _encoding = defaultSaveEncoding ?? decoded.encoding;
    _dialect = CsvDialect.detect(
      decoded.text,
      lineEnding: defaultSaveLineEnding ?? decoded.lineEnding,
      hasHeader: true,
    );
    _table = CsvParse.parse(decoded.text, _dialect);
    _savedText = _table.toCsv(_dialect);

    _isWritable = await _saf.isWritable(tab.uri);

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
    _status = CsvLoadStatus.ready;
    _safeNotify();
  }

  void _fail(String message) {
    _status = CsvLoadStatus.failed;
    _errorMessage = message;
    _safeNotify();
  }

  Map<String, String> _metadataFields() {
    return {
      'Rows': '${_table.rowCount}',
      'Columns': '${_table.columnCount}',
      'Delimiter': _dialect.delimiter.label,
      'Header row': _dialect.hasHeader ? 'Yes' : 'No',
    };
  }

  // --- view controls -------------------------------------------------------

  void setViewMode(CsvViewMode mode) {
    if (_mode == mode) return;
    if (_mode == CsvViewMode.raw && mode == CsvViewMode.table) {
      _syncTableFromRaw();
    }
    _mode = mode;
    if (mode == CsvViewMode.raw) _ensureRawController();
    _safeNotify();
  }

  void _ensureRawController() {
    final text = _table.toCsv(_dialect);
    if (_code == null) {
      _code = CodeLineEditingController.fromText(text);
      _code!.clearHistory();
      _code!.addListener(_onCodeChanged);
      _find = CodeFindController(_code!);
      _scroll = CodeScrollController();
    } else {
      // Refresh the raw buffer with any edits made in the grid meanwhile.
      _code!.text = text;
      _code!.clearHistory();
    }
  }

  void _syncTableFromRaw() {
    final code = _code;
    if (code == null) return;
    final parsed = CsvParse.parse(code.text, _dialect);
    if (parsed.contentEquals(_table)) return;
    _undo.record(_table);
    _table = parsed;
  }

  // --- grid edits ----------------------------------------------------------

  /// Applies [next] as the new table state, recording the previous state for
  /// undo and refreshing dirty/metadata. A no-op change is ignored.
  void _applyTable(CsvTable next) {
    if (identical(next, _table)) return;
    _undo.record(_table);
    _table = next;
    _afterTableChanged();
  }

  void setCell(int row, int col, String value) =>
      _applyTable(_table.setCell(row, col, value));
  void renameHeader(int col, String name) =>
      _applyTable(_table.renameHeader(col, name));
  void insertRow(int index, [List<String>? values]) =>
      _applyTable(_table.insertRow(index, values));
  void deleteRow(int index) => _applyTable(_table.deleteRow(index));
  void moveRow(int from, int to) => _applyTable(_table.moveRow(from, to));
  void insertColumn(int index, {String name = ''}) =>
      _applyTable(_table.insertColumn(index, name: name));
  void deleteColumn(int index) => _applyTable(_table.deleteColumn(index));
  void moveColumn(int from, int to) => _applyTable(_table.moveColumn(from, to));
  void removeDuplicateRows({int? keyColumn}) =>
      _applyTable(_table.removeDuplicateRows(keyColumn: keyColumn));

  /// Replaces the whole table (e.g. after a merge), recording it for undo.
  void replaceTable(CsvTable next) => _applyTable(next);

  /// Count of duplicate rows for the current dedup key (whole row when null).
  int duplicateCount({int? keyColumn}) =>
      _table.findDuplicateRows(keyColumn: keyColumn).length;

  void setHasHeader(bool value) {
    if (value == _dialect.hasHeader) return;
    _applyTable(_table.setHasHeader(value));
    _dialect = _dialect.copyWith(hasHeader: value);
    _safeNotify();
  }

  void undo() {
    if (_mode == CsvViewMode.raw) {
      _code?.undo();
      return;
    }
    final prev = _undo.undo(_table);
    if (prev != null) {
      _table = prev;
      _afterTableChanged();
    }
  }

  void redo() {
    if (_mode == CsvViewMode.raw) {
      _code?.redo();
      return;
    }
    final next = _undo.redo(_table);
    if (next != null) {
      _table = next;
      _afterTableChanged();
    }
  }

  void _afterTableChanged() {
    // Drop selection/sort references that no longer exist.
    _selectedRows.removeWhere((r) => r >= _table.rowCount);
    if (_sortColumn != null && _sortColumn! >= _table.columnCount) {
      _sortColumn = null;
      _sortDirection = SortDirection.none;
    }
    _hiddenColumns.removeWhere((c) => c >= _table.columnCount);
    _updateDirty();
    _safeNotify();
  }

  // --- navigation state ----------------------------------------------------

  void setFilterQuery(String query) {
    if (_filterQuery == query) return;
    _filterQuery = query;
    _safeNotify();
  }

  void sortBy(int column) {
    if (_sortColumn == column) {
      _sortDirection = switch (_sortDirection) {
        SortDirection.none => SortDirection.ascending,
        SortDirection.ascending => SortDirection.descending,
        SortDirection.descending => SortDirection.none,
      };
      if (_sortDirection == SortDirection.none) _sortColumn = null;
    } else {
      _sortColumn = column;
      _sortDirection = SortDirection.ascending;
    }
    _safeNotify();
  }

  void setColumnHidden(int column, bool hidden) {
    if (hidden) {
      _hiddenColumns.add(column);
    } else {
      _hiddenColumns.remove(column);
    }
    _safeNotify();
  }

  void toggleFreezeHeader() {
    _freezeHeader = !_freezeHeader;
    _safeNotify();
  }

  void toggleFreezeFirstColumn() {
    _freezeFirstColumn = !_freezeFirstColumn;
    _safeNotify();
  }

  void toggleRowSelected(int row) {
    if (!_selectedRows.remove(row)) _selectedRows.add(row);
    _safeNotify();
  }

  void clearSelection() {
    if (_selectedRows.isEmpty) return;
    _selectedRows.clear();
    _safeNotify();
  }

  /// Column types in column order, for alignment and the insights panel.
  List<ColumnType> get columnTypes =>
      [for (var c = 0; c < _table.columnCount; c++) inferColumnType(_table.column(c))];

  // --- dialect on save -----------------------------------------------------

  void setSaveEncoding(TextEncodingType encoding) {
    if (_encoding == encoding) return;
    _encoding = encoding;
    _safeNotify();
  }

  void setLineEnding(LineEndingStyle lineEnding) {
    if (_dialect.lineEnding == lineEnding) return;
    _dialect = _dialect.copyWith(lineEnding: lineEnding);
    _updateDirty();
    _safeNotify();
  }

  void setDelimiter(CsvDelimiter delimiter) {
    if (_dialect.delimiter == delimiter) return;
    _dialect = _dialect.copyWith(delimiter: delimiter);
    _updateDirty();
    _safeNotify();
  }

  // --- saving --------------------------------------------------------------

  Future<SaveResult> save() async {
    if (_mode == CsvViewMode.raw) _syncTableFromRaw();
    final text = _table.toCsv(_dialect);
    final target = await _target();
    final result = await _saver.save(
      text,
      target,
      encoding: _encoding,
      lineEnding: _dialect.lineEnding,
    );
    if (result.outcome == SaveOutcome.saved) {
      await _markSaved(text);
    }
    _safeNotify();
    return result;
  }

  Future<SaveResult> saveAsCopy() async {
    if (_mode == CsvViewMode.raw) _syncTableFromRaw();
    final text = _table.toCsv(_dialect);
    final target = await _target();
    try {
      return await _saver.saveAsCopy(
        text,
        target,
        tab.displayName,
        encoding: _encoding,
        lineEnding: _dialect.lineEnding,
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
      mimeType: tab.mimeType ?? 'text/csv',
    );
  }

  Future<void> _markSaved(String text) async {
    _savedText = text;
    if (_code != null && _mode == CsvViewMode.raw) {
      // Keep the raw buffer in step so it is not seen as dirty.
      _savedText = _code!.text;
    }
    _setDirty(false);
    _autoSaver?.markSaved(_savedText);
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
  }

  // --- drafts --------------------------------------------------------------

  Future<void> restoreDraft() async {
    final store = _draftStore;
    if (store == null) return;
    final draft = await store.load(tab.fingerprint);
    if (draft == null) {
      _draftAvailable = false;
      _safeNotify();
      return;
    }
    _undo.record(_table);
    _table = CsvParse.parse(draft, _dialect);
    if (_code != null) {
      _code!.text = _table.toCsv(_dialect);
      _code!.clearHistory();
    }
    _draftAvailable = false;
    _updateDirty();
    _safeNotify();
  }

  Future<void> discardDraft() async {
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    _safeNotify();
  }

  // --- position persistence ------------------------------------------------

  void persistPosition() {
    _store.setInt(_positionKey, _sortColumn ?? -1);
  }

  // --- internals -----------------------------------------------------------

  void _onCodeChanged() => _updateDirty();

  void _updateDirty() => _setDirty(currentText != _savedText);

  void _setDirty(bool value) {
    if (_isDirty == value) return;
    _isDirty = value;
    onDirtyChanged?.call(value);
    _safeNotify();
  }

  void _startAutoSave() {
    final store = _draftStore;
    if (store == null) return;
    // A zero (or negative) interval disables crash-recovery auto-save — used by
    // widget tests so no periodic timer keeps `pumpAndSettle` from settling.
    if (autoSaveInterval <= Duration.zero) return;
    _autoSaver = AutoSaver(
      store: store,
      fingerprint: tab.fingerprint,
      getContent: () => currentText,
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
