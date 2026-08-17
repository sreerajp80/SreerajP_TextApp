import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';
import 'package:sreerajp_textapp/core/sql/sql_guard.dart';
import 'package:sreerajp_textapp/core/sql/sql_presets.dart';
import 'package:sreerajp_textapp/core/sql/sql_query_engine.dart';
import 'package:sreerajp_textapp/core/sql/sql_result.dart';
import 'package:sreerajp_textapp/core/sql/sql_result_grid.dart';
import 'package:sreerajp_textapp/core/sql/sql_schema_panel.dart';
import 'package:sreerajp_textapp/core/sql/sql_source.dart';
import 'package:sreerajp_textapp/core/sql/sql_source_picker.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// The SQL-on-data screen (Feature 4).
///
/// The open document — and any other open CSV or JSON tab the user adds — is
/// copied into a throwaway in-memory SQLite database. Queries are read-only and
/// checked by [SqlGuard] before they run, so nothing here can change or delete
/// the user's file.
///
/// The screen holds a **snapshot**: editing the document afterwards does not
/// change the loaded tables until "Reload data" is tapped. That is stated on the
/// schema panel rather than left for the user to discover.
class SqlQueryScreen extends ConsumerStatefulWidget {
  /// The document the screen was opened from. Always the first table.
  final SqlSource primary;

  /// The other open documents that may be added as tables. It is a callback so
  /// the list is read when the picker opens, not when the screen is built.
  ///
  /// The formats layer supplies this; `core/sql` never inspects a document
  /// itself (CLAUDE.md §4).
  final List<SqlSource> Function() otherSources;

  /// Lets a widget test run the engine on the host through the FFI factory.
  /// The app leaves it null and gets Android's own SQLite.
  @visibleForTesting
  final DatabaseFactory? databaseFactoryOverride;

  const SqlQueryScreen({
    super.key,
    required this.primary,
    required this.otherSources,
    this.databaseFactoryOverride,
  });

  static Future<void> open(
    BuildContext context, {
    required SqlSource primary,
    required List<SqlSource> Function() otherSources,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            SqlQueryScreen(primary: primary, otherSources: otherSources),
      ),
    );
  }

  @override
  ConsumerState<SqlQueryScreen> createState() => _SqlQueryScreenState();
}

class _SqlQueryScreenState extends ConsumerState<SqlQueryScreen> {
  late final SqlQueryEngine _engine = SqlQueryEngine(
    factory: widget.databaseFactoryOverride,
  );
  final TextEditingController _sql = TextEditingController();

  /// Sources added on top of the primary one, kept so a reload can rebuild them.
  final List<SqlSource> _extra = [];

  List<SqlDataset> _datasets = const [];
  bool _loading = true;
  bool _running = false;

  /// Set when the data itself could not be loaded — the screen then has nothing
  /// to offer and says so.
  String? _loadError;

  SqlQueryResult? _result;
  String? _queryError;

  /// The schema is shown first (the user needs the names), then the result takes
  /// over once a query has run.
  bool _showSchema = true;

  @override
  void initState() {
    super.initState();
    // After the first frame, not during initState: the load reads localized
    // strings, and looking up an inherited widget is not allowed this early.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _sql.dispose();
    unawaited(_engine.close());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      final datasets = <SqlDataset>[];
      final primary = await widget.primary.build();
      if (primary == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadError = l10n.sqlNoData;
        });
        return;
      }
      datasets.add(primary);
      for (final source in _extra) {
        final dataset = await source.build();
        if (dataset != null) datasets.add(dataset);
      }
      await _engine.load(datasets);
      if (!mounted) return;
      setState(() {
        _datasets = _engine.datasets;
        _loading = false;
        if (_sql.text.trim().isEmpty) {
          final presets = buildSqlPresets(_datasets);
          if (presets.isNotEmpty) _sql.text = presets.first.sql;
        }
      });
    } on SqlQueryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = l10n.sqlLoadFailed;
      });
    }
  }

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    final guard = SqlGuard.check(_sql.text);
    if (!guard.ok) {
      setState(() {
        _queryError = _guardMessage(l10n, guard);
        _result = null;
        _showSchema = false;
      });
      return;
    }

    setState(() {
      _running = true;
      _queryError = null;
      _showSchema = false;
    });
    try {
      final result = await _engine.run(guard.statement);
      if (!mounted) return;
      setState(() {
        _result = result;
        _running = false;
      });
    } on SqlQueryException catch (e) {
      if (!mounted) return;
      setState(() {
        _queryError = e.message;
        _result = null;
        _running = false;
      });
    }
  }

  String _guardMessage(AppLocalizations l10n, SqlGuardResult guard) {
    switch (guard.failure) {
      case SqlGuardFailure.empty:
        return l10n.sqlErrorEmpty;
      case SqlGuardFailure.notSelect:
        return l10n.sqlErrorNotSelect;
      case SqlGuardFailure.multipleStatements:
        return l10n.sqlErrorMultiple;
      case SqlGuardFailure.forbiddenKeyword:
      case null:
        return l10n.sqlErrorForbidden(guard.keyword ?? '');
    }
  }

  Future<void> _addTable() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final taken = {widget.primary.tabId, ..._extra.map((s) => s.tabId)};
    final choices = widget
        .otherSources()
        .where((s) => !taken.contains(s.tabId))
        .toList();
    final picked = await showSqlSourcePicker(context, choices);
    if (picked == null) return;

    setState(() => _loading = true);
    final dataset = await picked.build();
    if (!mounted) return;
    if (dataset == null) {
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.sqlAddTableFailed(picked.displayName))),
      );
      return;
    }
    _extra.add(picked);
    await _load();
    if (!mounted) return;
    final loaded = _datasets.length > 1 ? _datasets.last.tableName : '';
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.sqlTableAdded(picked.displayName, loaded))),
    );
  }

  void _removeTable(SqlDataset dataset) {
    final index = _datasets.indexOf(dataset);
    // The first table is the document itself and is never removable; the extra
    // list runs one behind the dataset list because of it.
    if (index < 1 || index - 1 >= _extra.length) return;
    _extra.removeAt(index - 1);
    unawaited(_load());
  }

  void _insert(String text) {
    final selection = _sql.selection;
    final value = _sql.text;
    final at = selection.isValid ? selection.baseOffset : value.length;
    final safeAt = at.clamp(0, value.length);
    final next = value.replaceRange(
      safeAt,
      selection.isValid
          ? selection.extentOffset.clamp(0, value.length)
          : safeAt,
      text,
    );
    _sql.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: safeAt + text.length),
    );
  }

  Future<void> _copyResult() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = _result;
    if (result == null || result.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sqlNoResultYet)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: result.toCsv()));
    messenger.showSnackBar(SnackBar(content: Text(l10n.sqlCopiedResult)));
  }

  Future<void> _saveResult() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = _result;
    if (result == null || result.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sqlNoResultYet)));
      return;
    }
    // A brand-new file, so UTF-8 is the right encoding — there is no original
    // encoding to preserve here.
    final bytes = Uint8List.fromList(utf8.encode(result.toCsv()));
    try {
      final file = await ref
          .read(safServiceProvider)
          .createDocument(
            suggestedName: 'query-result.csv',
            bytes: bytes,
            mimeType: 'text/csv',
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.sqlSavedResult(file.displayName))),
      );
    } on SafCancelled {
      // The user backed out of the picker; nothing to report.
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sqlQueryTitle),
        actions: [
          IconButton(
            key: const Key('sql-schema-toggle'),
            tooltip: l10n.sqlTablesHeading,
            isSelected: _showSchema,
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: _loadError != null
                ? null
                : () => setState(() => _showSchema = !_showSchema),
          ),
          IconButton(
            tooltip: l10n.sqlReloadData,
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _reload,
          ),
          PopupMenuButton<int>(
            key: const Key('sql-overflow-menu'),
            onSelected: (value) => value == 0 ? _copyResult() : _saveResult(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: Text(l10n.sqlCopyResult),
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  leading: const Icon(Icons.save_alt_outlined),
                  title: Text(l10n.sqlSaveResult),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: _body(theme, l10n)),
    );
  }

  Future<void> _reload() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await _load();
    if (!mounted || _loadError != null) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.sqlReloadedData)));
  }

  Widget _body(ThemeData theme, AppLocalizations l10n) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _editor(theme, l10n),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.sqlLoadingData),
                    ],
                  ),
                )
              : (_showSchema
                    ? SqlSchemaPanel(
                        datasets: _datasets,
                        onInsert: _insert,
                        onRemove: _removeTable,
                      )
                    : _resultArea(theme, l10n)),
        ),
      ],
    );
  }

  Widget _editor(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          TextField(
            key: const Key('sql-input'),
            controller: _sql,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'JetBrains Mono',
            ),
            decoration: InputDecoration(
              hintText: l10n.sqlQueryHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                key: const Key('sql-run-button'),
                onPressed: _loading || _running ? null : _run,
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? l10n.sqlRunning : l10n.sqlRunAction),
              ),
              const SizedBox(width: 8),
              _presetsButton(l10n),
              const Spacer(),
              TextButton.icon(
                key: const Key('sql-add-table'),
                onPressed: _loading ? null : _addTable,
                icon: const Icon(Icons.library_add_outlined, size: 18),
                label: Text(l10n.sqlAddTable),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetsButton(AppLocalizations l10n) {
    final presets = buildSqlPresets(_datasets);
    return PopupMenuButton<SqlPreset>(
      key: const Key('sql-presets-menu'),
      enabled: presets.isNotEmpty,
      tooltip: l10n.sqlPresetsHeading,
      onSelected: (preset) {
        _sql.text = preset.sql;
        setState(() {});
      },
      itemBuilder: (context) => [
        for (final preset in presets)
          PopupMenuItem(value: preset, child: Text(_presetLabel(l10n, preset))),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Icon(Icons.lightbulb_outline),
      ),
    );
  }

  String _presetLabel(AppLocalizations l10n, SqlPreset preset) {
    switch (preset.kind) {
      case SqlPresetKind.selectAll:
        return l10n.sqlPresetSelectAll;
      case SqlPresetKind.countRows:
        return l10n.sqlPresetCountRows;
      case SqlPresetKind.groupCount:
        return l10n.sqlPresetGroupCount;
      case SqlPresetKind.orderBy:
        return l10n.sqlPresetOrderBy;
      case SqlPresetKind.join:
        return l10n.sqlPresetJoin;
    }
  }

  Widget _resultArea(ThemeData theme, AppLocalizations l10n) {
    final error = _queryError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                error,
                key: const Key('sql-error-text'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.sqlResultPlaceholder,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainer,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sqlResultSummary(result.rowCount, result.elapsedMs),
                style: theme.textTheme.bodySmall,
              ),
              if (result.truncated)
                Text(
                  l10n.sqlResultTruncated(result.rowCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: SqlResultGrid(result: result)),
      ],
    );
  }
}
