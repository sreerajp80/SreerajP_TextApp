import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;
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
import 'md_front_matter.dart';
import 'md_parse.dart';
import 'md_stats.dart';
import 'md_toc.dart';

/// Loading lifecycle of one open Markdown document.
enum MdLoadStatus { loading, ready, failed }

/// How the Markdown document is shown: the rendered preview, the raw source
/// (read-only), or the source editor.
enum MdMode { rendered, raw, edit }

/// One open Markdown file's live state (Phase 6): the bridge between a shell tab
/// and the on-screen rendered/raw/editor views.
///
/// Mirrors [TxtDocumentSession] — it loads bytes, decodes them (never throwing —
/// CLAUDE.md §3.4), holds the `re_editor` controllers for the source, tracks
/// unsaved edits, drives crash-recovery drafts, and saves through the
/// [AtomicSaver] preserving encoding + line endings (CLAUDE.md §3.5). On top of
/// that it parses the Markdown (front matter, AST, TOC, stats) for the rendered
/// view. A plain [ChangeNotifier] with **no Riverpod dependency**, so it is
/// unit-testable directly.
class MdDocumentSession extends ChangeNotifier {
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

  MdDocumentSession({
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

  MdLoadStatus _status = MdLoadStatus.loading;
  String? _errorMessage;
  CodeLineEditingController? _code;
  CodeFindController? _find;
  CodeScrollController? _scroll;
  TextEncodingType _encoding = TextEncodingType.utf8;
  LineEndingStyle _lineEnding = LineEndingStyle.lf;
  bool _isWritable = false;
  FileMetadata? _metadataValue;
  MdMode _mode = MdMode.rendered;
  bool _livePreview = true;
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
  List<md.Node> _nodes = const [];
  MdToc _toc = const MdToc([]);
  MdFrontMatter _frontMatter = const MdFrontMatter(
    present: false,
    title: null,
    author: null,
    tags: [],
    fields: {},
    body: '',
  );
  MdStats _stats = MdStats.empty;

  MdLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CodeLineEditingController? get code => _code;
  CodeFindController? get find => _find;
  CodeScrollController? get scroll => _scroll;
  TextEncodingType get encoding => _encoding;
  LineEndingStyle get lineEnding => _lineEnding;
  bool get isWritable => _isWritable;
  FileMetadata? get metadata => _metadataValue;
  MdMode get mode => _mode;
  bool get livePreview => _livePreview;
  bool get isDirty => _isDirty;
  bool get draftAvailable => _draftAvailable;
  bool get isEditing => _mode == MdMode.edit;

  MdFrontMatter get frontMatter {
    _ensureParsed();
    return _frontMatter;
  }

  /// The parsed AST for the rendered view (body only, math enabled).
  List<md.Node> get renderNodes {
    _ensureParsed();
    return _nodes;
  }

  MdToc get toc {
    _ensureParsed();
    return _toc;
  }

  MdStats get stats {
    _ensureParsed();
    return _stats;
  }

  /// The current content as neutral [TextContent] for the shared output services
  /// (share / export / print). The full source is kept so a copy is lossless.
  TextContent get textContent =>
      TextContent(displayName: tab.displayName, text: _code?.text ?? '');

  bool get canUndo => _code?.canUndo ?? false;
  bool get canRedo => _code?.canRedo ?? false;

  /// Scroll controller for the rendered preview (shared so the toolbar's TOC and
  /// the preview body agree on one scroll view).
  final ScrollController previewScroll = ScrollController();

  final Map<String, GlobalKey> _headingKeys = {};

  /// The heading anchors in document order, aligned with [renderNodes] headings.
  List<String> get headingAnchors =>
      toc.headings.map((h) => h.anchor).toList();

  /// [GlobalKey]s the renderer tags each heading with, so a TOC entry or an
  /// internal `#` link can scroll to it. Call [syncHeadingKeys] before rendering.
  Map<String, GlobalKey> get headingKeys => _headingKeys;

  /// Makes sure there is exactly one key per current heading anchor.
  void syncHeadingKeys() {
    final anchors = headingAnchors;
    _headingKeys.removeWhere((k, _) => !anchors.contains(k));
    for (final anchor in anchors) {
      _headingKeys.putIfAbsent(anchor, GlobalKey.new);
    }
  }

  /// Scrolls the rendered preview to the heading with [anchor], if present.
  Future<void> jumpToAnchor(String anchor) async {
    final context = _headingKeys[anchor]?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      alignment: 0.05,
    );
  }

  String get _positionKey => 'md.pos.${tab.fingerprint}';
  String get _previewKey => 'md.preview.${tab.fingerprint}';

  /// The remembered preview scroll offset (0 when none saved).
  double get initialPreviewOffset =>
      (_store.getInt(_previewKey) ?? 0).toDouble();

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

    _startAutoSave();

    if (_disposed) return;
    _status = MdLoadStatus.ready;
    _safeNotify();
  }

  void _fail(String message) {
    _status = MdLoadStatus.failed;
    _errorMessage = message;
    _safeNotify();
  }

  Map<String, String> _metadataFields() {
    final fm = _frontMatter;
    return {
      'Words': '${_stats.words}',
      'Headings': '${_stats.headings}',
      'Links': '${_stats.links}',
      if (fm.title != null) 'Title': fm.title!,
      if (fm.author != null) 'Author': fm.author!,
      if (fm.tags.isNotEmpty) 'Tags': fm.tags.join(', '),
    };
  }

  // --- view controls -------------------------------------------------------

  /// Switches the document mode. Entering [MdMode.edit] is only meaningful when
  /// the file is editable; the caller (toolbar) guards that.
  void setMode(MdMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _safeNotify();
  }

  void toggleLivePreview() {
    _livePreview = !_livePreview;
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
      mimeType: tab.mimeType ?? 'text/markdown',
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
    _mode = MdMode.edit;
    _updateDirty();
    _safeNotify();
  }

  Future<void> discardDraft() async {
    await _draftStore?.discard(tab.fingerprint);
    _draftAvailable = false;
    _safeNotify();
  }

  // --- editing helpers -----------------------------------------------------

  void undo() => _code?.undo();
  void redo() => _code?.redo();
  void openFind() => _find?.findMode();
  void openReplace() => _find?.replaceMode();

  /// The current selection as flat character offsets `[start, end)` over the
  /// whole source, so the formatting toolbar can transform it (task 6.4).
  (int, int) get selectionRange {
    final code = _code;
    if (code == null) return (0, 0);
    final sel = code.selection;
    final a = _flatOffset(code.text, sel.baseIndex, sel.baseOffset);
    final b = _flatOffset(code.text, sel.extentIndex, sel.extentOffset);
    return a <= b ? (a, b) : (b, a);
  }

  /// Applies a formatting-toolbar edit result to the source, replacing the whole
  /// text and restoring the given selection (given as flat char offsets).
  void applyEdit(String newText, int selectionStart, int selectionEnd) {
    final code = _code;
    if (code == null) return;
    code.text = newText;
    final (bi, bo) = _lineColOf(newText, selectionStart);
    final (ei, eo) = _lineColOf(newText, selectionEnd);
    code.selection = CodeLineSelection(
      baseIndex: bi,
      baseOffset: bo,
      extentIndex: ei,
      extentOffset: eo,
    );
  }

  /// Flat char offset of a (line, column) position in [text].
  static int _flatOffset(String text, int lineIndex, int charOffset) {
    final lines = text.split('\n');
    var offset = 0;
    for (var i = 0; i < lineIndex && i < lines.length; i++) {
      offset += lines[i].length + 1; // +1 for the '\n'
    }
    return offset + charOffset;
  }

  /// The (line, column) position of a flat char offset in [text].
  static (int, int) _lineColOf(String text, int flat) {
    var remaining = flat.clamp(0, text.length);
    var line = 0;
    final parts = text.split('\n');
    for (final part in parts) {
      if (remaining <= part.length) return (line, remaining);
      remaining -= part.length + 1;
      line++;
    }
    final lastLine = parts.isEmpty ? 0 : parts.length - 1;
    final lastLen = parts.isEmpty ? 0 : parts.last.length;
    return (lastLine, lastLen);
  }

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

  /// Best-effort remember the rendered-view scroll offset (fire-and-forget).
  void persistPreviewOffset(double offset) {
    _store.setInt(_previewKey, offset.round());
  }

  // --- internals -----------------------------------------------------------

  void _ensureParsed() {
    final text = _code?.text ?? '';
    if (_parsedFor == text) return;
    _parsedFor = text;
    _frontMatter = MdFrontMatter.parse(text);
    final body = _frontMatter.body;
    _nodes = MdParse.parseBlocks(body, withMath: true);
    _toc = MdToc.of(body);
    _stats = MdStats.of(body);
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
    previewScroll.dispose();
    super.dispose();
  }
}
