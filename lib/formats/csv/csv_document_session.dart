import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/editor/atomic_saver.dart';
import '../../core/editor/draft_store.dart';
import '../../core/editor/encoding.dart';
import '../../core/editor/external_change.dart';
import '../../core/editor/saf_save_target.dart';
import '../../core/export/export_target.dart';
import '../../core/metadata/file_metadata.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../shell/tabs/document_tab.dart';
import 'csv_conditional_format.dart';
import 'csv_dialect.dart';
import 'csv_filter_sort.dart';
import 'csv_formula.dart';
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
class CsvDocumentSession extends ChangeNotifier with ExternalChangeMixin {
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

  /// The sort hierarchy (roadmap §4.2.1). The first level decides the order and
  /// later levels only break its ties. An empty list means "no sort".
  List<CsvSortSpec> _sortSpecs = const [];

  /// Formulas for calculated columns, keyed by column index (roadmap §4.2.2).
  /// Their values are written into the table and refreshed after every change,
  /// so the saved file stays plain CSV.
  final Map<int, String> _formulas = {};

  /// Conditional formatting rules (roadmap §4.2.3), in priority order.
  List<CsvFormatRule> _formatRules = const [];
  CsvConditionalFormat? _formatCache;

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

  CodeLineEditingController? get code => _code;
  CodeFindController? get find => _find;
  CodeScrollController? get scroll => _scroll;

  String get filterQuery => _filterQuery;

  /// The whole sort hierarchy, first level first (roadmap §4.2.1).
  List<CsvSortSpec> get sortSpecs => List.unmodifiable(_sortSpecs);

  /// The first sort level's column, or null when nothing is sorted. Kept so the
  /// grid header and the saved reading position keep working as before.
  int? get sortColumn => _sortSpecs.isEmpty ? null : _sortSpecs.first.column;

  /// The first sort level's direction.
  SortDirection get sortDirection =>
      _sortSpecs.isEmpty ? SortDirection.none : _sortSpecs.first.direction;

  /// Where [column] sits in the sort hierarchy as a 1-based level number, or
  /// null when it is not sorted. The grid header shows this when more than one
  /// level is active.
  int? sortLevelOf(int column) {
    for (var i = 0; i < _sortSpecs.length; i++) {
      if (_sortSpecs[i].column == column) return i + 1;
    }
    return null;
  }

  /// The direction applied to [column], or [SortDirection.none].
  SortDirection sortDirectionOf(int column) {
    for (final spec in _sortSpecs) {
      if (spec.column == column) return spec.direction;
    }
    return SortDirection.none;
  }

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
    if (_sortSpecs.isEmpty) return filtered;
    return CsvFilterSort.sortMulti(_table, filtered, _sortSpecs);
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

  // Legacy single-column sort keys, still read so a file sorted before the
  // multi-level sort arrived opens the way the user left it.
  String get _positionKey => 'csv.pos.${tab.fingerprint}';
  String get _sortDirKey => 'csv.dir.${tab.fingerprint}';

  String get _sortSpecsKey => 'csv.sorts.${tab.fingerprint}';
  String get _formulasKey => 'csv.formulas.${tab.fingerprint}';
  String get _formatRulesKey => 'csv.rules.${tab.fingerprint}';

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
      formatFields: _metadataFields(),
    );

    _draftStore = await _draftStoreFuture;
    _draftAvailable = await _draftStore!.hasDraft(tab.fingerprint);

    _restoreSort();
    _restoreFormulas();
    _restoreFormatRules();
    _startAutoSave();

    if (_disposed) return;
    _status = CsvLoadStatus.ready;
    _safeNotify();
  }

  /// Re-applies the sort hierarchy the file was last left with. Levels that no
  /// longer fit the parsed table are dropped; if none survive, the table opens
  /// unsorted. No render timing to worry about — sorting is a data operation the
  /// grid reads on its first build.
  ///
  /// A file last sorted before the multi-level sort existed only has the old
  /// single-column keys, so those are read as a fallback.
  void _restoreSort() {
    final stored = _store.getPlainString(_sortSpecsKey);
    if (stored != null && stored.isNotEmpty) {
      final specs = <CsvSortSpec>[];
      for (final part in stored.split(',')) {
        final spec = CsvSortSpec.decode(part);
        if (spec == null) continue;
        if (spec.column >= _table.columnCount) continue;
        if (spec.direction == SortDirection.none) continue;
        specs.add(spec);
      }
      if (specs.isNotEmpty) {
        _sortSpecs = specs;
        return;
      }
    }
    _restoreLegacySort();
  }

  void _restoreLegacySort() {
    final column = _store.getInt(_positionKey);
    if (column == null || column < 0 || column >= _table.columnCount) return;
    final dirIndex = _store.getInt(_sortDirKey);
    if (dirIndex == null ||
        dirIndex < 0 ||
        dirIndex >= SortDirection.values.length) {
      return;
    }
    final direction = SortDirection.values[dirIndex];
    if (direction == SortDirection.none) return;
    _sortSpecs = [CsvSortSpec(column, direction)];
  }

  /// Re-applies the calculated-column formulas remembered for this file and
  /// fills their values in. A formula whose column is gone is dropped.
  void _restoreFormulas() {
    final stored = _store.getPlainString(_formulasKey);
    if (stored == null || stored.isEmpty) return;
    for (final line in stored.split('\n')) {
      final split = line.indexOf('=');
      if (split <= 0) continue;
      final column = int.tryParse(line.substring(0, split));
      if (column == null || column < 0 || column >= _table.columnCount) continue;
      _formulas[column] = line.substring(split + 1);
    }
    if (_formulas.isNotEmpty) _recomputeFormulas();
  }

  /// Re-applies the conditional formatting rules remembered for this file.
  void _restoreFormatRules() {
    final stored = _store.getPlainString(_formatRulesKey);
    if (stored == null || stored.isEmpty) return;
    final rules = <CsvFormatRule>[];
    for (final line in stored.split('\n')) {
      final rule = CsvFormatRule.decode(line);
      if (rule == null) continue;
      if (rule.column != null && rule.column! >= _table.columnCount) continue;
      rules.add(rule);
    }
    _formatRules = rules;
    _formatCache = null;
  }

  void _fail(String message) {
    _status = CsvLoadStatus.failed;
    _errorMessage = message;
    _safeNotify();
  }

  /// Reads the file again and rebuilds the table from it, dropping whatever the
  /// tab held. The caller confirms with the user first when the tab has unsaved
  /// edits — CLAUDE.md §3.6.
  ///
  /// Returns false when the read failed; the document is then left untouched.
  @override
  Future<bool> reloadFromDisk() async {
    Uint8List bytes;
    try {
      bytes = await _saf.readBytes(tab.uri);
    } catch (_) {
      return false;
    }
    if (_disposed) return false;

    final decoded = _codec.detectAndDecode(bytes);
    _encoding = defaultSaveEncoding ?? decoded.encoding;
    _dialect = CsvDialect.detect(
      decoded.text,
      lineEnding: defaultSaveLineEnding ?? decoded.lineEnding,
      hasHeader: true,
    );
    _table = CsvParse.parse(decoded.text, _dialect);
    _savedText = _table.toCsv(_dialect);

    // The old snapshots belong to a table that is gone, and row/column state
    // may not fit the new shape.
    _undo.clear();
    _selectedRows.clear();
    _hiddenColumns.removeWhere((c) => c >= _table.columnCount);
    _dropStaleColumnState();
    _pendingJumpRow = null;
    // The reloaded file may not have the calculated columns' values in it.
    _recomputeFormulas();

    // Refresh the raw buffer too, so raw mode shows the new content.
    if (_code != null) {
      _code!.text = _savedText;
      _code!.clearHistory();
    }
    _setDirty(false);
    _autoSaver?.markSaved(_savedText);

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
    _dropStaleColumnState();
    _hiddenColumns.removeWhere((c) => c >= _table.columnCount);
    // The duplicate lookup inside the prepared rules belongs to the old data.
    _formatCache = null;
    // Calculated columns follow the data, so they are refreshed before the
    // dirty flag is worked out — the recomputed values are part of the content.
    _recomputeFormulas();
    _updateDirty();
    _safeNotify();
  }

  /// Forgets sort levels, formulas and rules that point past the table's last
  /// column, which happens after a column is deleted or the file is reloaded.
  void _dropStaleColumnState() {
    final count = _table.columnCount;
    if (_sortSpecs.any((s) => s.column >= count)) {
      _sortSpecs = [for (final s in _sortSpecs) if (s.column < count) s];
    }
    _formulas.removeWhere((column, _) => column >= count);
    if (_formatRules.any((r) => r.column != null && r.column! >= count)) {
      _formatRules = [
        for (final r in _formatRules)
          if (r.column == null || r.column! < count) r,
      ];
      _formatCache = null;
    }
  }

  // --- navigation state ----------------------------------------------------

  void setFilterQuery(String query) {
    if (_filterQuery == query) return;
    _filterQuery = query;
    _safeNotify();
  }

  /// Cycles the sort on [column] from a header tap: none → ascending →
  /// descending → none. This always replaces the whole hierarchy with a single
  /// level, so a tap is a simple, predictable action; a multi-level sort is
  /// built in the sort sheet instead ([setSortSpecs]).
  void sortBy(int column) {
    final current = sortDirectionOf(column);
    final next = _sortSpecs.length == 1 || _sortSpecs.isEmpty
        ? switch (current) {
            SortDirection.none => SortDirection.ascending,
            SortDirection.ascending => SortDirection.descending,
            SortDirection.descending => SortDirection.none,
          }
        // Coming from a multi-level sort, the first tap collapses to just this
        // column rather than continuing someone else's cycle.
        : SortDirection.ascending;
    _sortSpecs =
        next == SortDirection.none ? const [] : [CsvSortSpec(column, next)];
    _safeNotify();
  }

  /// Replaces the whole sort hierarchy (roadmap §4.2.1). Levels that name a
  /// missing column or carry no direction are dropped.
  void setSortSpecs(List<CsvSortSpec> specs) {
    _sortSpecs = [
      for (final spec in specs)
        if (spec.direction != SortDirection.none &&
            spec.column >= 0 &&
            spec.column < _table.columnCount)
          spec,
    ];
    _safeNotify();
  }

  void clearSort() => setSortSpecs(const []);

  // --- calculated columns (roadmap 4.2.2) ----------------------------------

  /// The formula set on [column], or null when it is an ordinary column.
  String? columnFormula(int column) => _formulas[column];

  /// True when any column in the table is calculated.
  bool get hasFormulas => _formulas.isNotEmpty;

  /// Sets [formula] on [column] and fills the column in. The column becomes
  /// read-only in the grid, because a typed value would be overwritten on the
  /// next recompute.
  ///
  /// Returns null on success, or a friendly message when the formula cannot be
  /// used — the caller shows it and leaves the column alone.
  String? setColumnFormula(int column, String formula) {
    if (column < 0 || column >= _table.columnCount) {
      return 'That column is no longer in the table.';
    }
    final problem = CsvFormula.validate(_table, formula, selfColumn: column);
    if (problem != null) return problem;
    _formulas[column] = formula;
    _undo.record(_table);
    _recomputeFormulas();
    _updateDirty();
    _persistFormulas();
    _safeNotify();
    return null;
  }

  /// Turns [column] back into an ordinary column. The values it last computed
  /// stay in the cells, so nothing disappears from the file.
  void clearColumnFormula(int column) {
    if (_formulas.remove(column) == null) return;
    _persistFormulas();
    _safeNotify();
  }

  /// Writes every calculated column's values into the table, in place. Called
  /// after each change, so the file always holds the values a save would write.
  void _recomputeFormulas() {
    if (_formulas.isEmpty) return;
    for (final entry in _formulas.entries) {
      final column = entry.key;
      if (column < 0 || column >= _table.columnCount) continue;
      for (var row = 0; row < _table.rowCount; row++) {
        final result =
            CsvFormula.evaluate(_table, entry.value, row, selfColumn: column);
        final cells = _table.rows[row];
        if (column < cells.length) cells[column] = result.display;
      }
    }
  }

  void _persistFormulas() {
    if (_formulas.isEmpty) {
      _store.remove(_formulasKey);
      return;
    }
    _store.setPlainString(
      _formulasKey,
      [for (final e in _formulas.entries) '${e.key}=${e.value}'].join('\n'),
    );
  }

  // --- conditional formatting (roadmap 4.2.3) ------------------------------

  /// The highlight rules, in priority order.
  List<CsvFormatRule> get formatRules => List.unmodifiable(_formatRules);

  /// The rules prepared against the current table, ready for the grid to ask
  /// cell by cell. Rebuilt only when the rules or the table change.
  CsvConditionalFormat get conditionalFormat {
    final cache = _formatCache;
    if (cache != null) return cache;
    final prepared = CsvConditionalFormat.prepare(_table, _formatRules);
    _formatCache = prepared;
    return prepared;
  }

  void setFormatRules(List<CsvFormatRule> rules) {
    _formatRules = List<CsvFormatRule>.from(rules);
    _formatCache = null;
    _persistFormatRules();
    _safeNotify();
  }

  void addFormatRule(CsvFormatRule rule) =>
      setFormatRules([..._formatRules, rule]);

  void removeFormatRuleAt(int index) {
    if (index < 0 || index >= _formatRules.length) return;
    final next = List<CsvFormatRule>.from(_formatRules)..removeAt(index);
    setFormatRules(next);
  }

  void clearFormatRules() => setFormatRules(const []);

  void _persistFormatRules() {
    if (_formatRules.isEmpty) {
      _store.remove(_formatRulesKey);
      return;
    }
    _store.setPlainString(
      _formatRulesKey,
      [for (final r in _formatRules) r.encode()].join('\n'),
    );
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
    // The file on disk is now ours again — never warn about our own write.
    await captureDiskBaseline();
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
    // The whole hierarchy, plus the legacy single-column keys so an older build
    // of the app still restores something sensible.
    if (_sortSpecs.isEmpty) {
      _store.remove(_sortSpecsKey);
    } else {
      _store.setPlainString(
        _sortSpecsKey,
        [for (final spec in _sortSpecs) spec.encode()].join(','),
      );
    }
    _store.setInt(_positionKey, sortColumn ?? -1);
    _store.setInt(_sortDirKey, sortDirection.index);
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
