import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';
import 'package:sreerajp_textapp/core/sql/sql_source.dart';
import 'package:sreerajp_textapp/formats/csv/csv_document_session.dart';
import 'package:sreerajp_textapp/formats/csv/csv_session_manager.dart';
import 'package:sreerajp_textapp/formats/csv/csv_sql_source.dart';
import 'package:sreerajp_textapp/formats/format_dispatch.dart';
import 'package:sreerajp_textapp/formats/json/json_document_session.dart';
import 'package:sreerajp_textapp/formats/json/json_session_manager.dart';
import 'package:sreerajp_textapp/formats/json/json_sql_source.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';

/// How long to wait for a background tab's document to load before giving up.
const Duration _loadTimeout = Duration(seconds: 20);

/// The open CSV and JSON tabs that can be loaded as extra SQL tables for a
/// `JOIN` (Feature 4).
///
/// This lives in the formats layer on purpose: `core/sql` must not know what a
/// CSV or a JSON array is, so it takes [SqlSource] handles instead
/// (CLAUDE.md §4, dependency direction).
///
/// A tab that is not on screen may have no live session yet. Building its source
/// starts the load and waits for it, so picking a background tab works without
/// the user having to visit it first.
List<SqlSource> sqlSourcesForOpenTabs(WidgetRef ref, {String? excludeTabId}) {
  final tabs = ref.read(tabsControllerProvider).tabs;
  final sources = <SqlSource>[];
  for (final tab in tabs) {
    if (tab.id == excludeTabId) continue;
    final format = detectFormat(tab);
    if (format != DocumentFormat.csv && format != DocumentFormat.json) continue;
    sources.add(sqlSourceForTab(ref, tab, format));
  }
  return sources;
}

/// One tab's [SqlSource]. [format] must be CSV or JSON.
SqlSource sqlSourceForTab(
  WidgetRef ref,
  DocumentTab tab,
  DocumentFormat format,
) {
  final tableName = suggestedTableName(tab.displayName);
  return SqlSource(
    tabId: tab.id,
    displayName: tab.displayName,
    suggestedTableName: tableName,
    build: () => format == DocumentFormat.csv
        ? _buildCsv(ref, tab, tableName)
        : _buildJson(ref, tab, tableName),
  );
}

/// A plain SQL table name from a file name (`sales report.csv` → `sales_report`).
String suggestedTableName(String displayName) {
  final dot = displayName.lastIndexOf('.');
  final base = dot > 0 ? displayName.substring(0, dot) : displayName;
  return SqlDataset.sanitizeTableName(base);
}

Future<SqlDataset?> _buildCsv(
  WidgetRef ref,
  DocumentTab tab,
  String tableName,
) async {
  final session = ref.read(csvSessionManagerProvider).sessionFor(tab);
  final ready = await _waitUntil(
    session,
    () => session.status != CsvLoadStatus.loading,
  );
  if (!ready || session.status != CsvLoadStatus.ready) return null;
  if (session.table.columnCount == 0) return null;
  return csvSqlDataset(
    session.table,
    tableName: tableName,
    sourceLabel: tab.displayName,
  );
}

Future<SqlDataset?> _buildJson(
  WidgetRef ref,
  DocumentTab tab,
  String tableName,
) async {
  final session = ref.read(jsonSessionManagerProvider).sessionFor(tab);
  final ready = await _waitUntil(
    session,
    () => session.status != JsonLoadStatus.loading,
  );
  if (!ready || session.status != JsonLoadStatus.ready) return null;
  return jsonSqlDataset(
    session.jsonTable,
    tableName: tableName,
    sourceLabel: tab.displayName,
  );
}

/// Waits until [done] holds, listening to [notifier]. Returns false on timeout,
/// so a document that never finishes loading cannot hang the query screen.
Future<bool> _waitUntil(ChangeNotifier notifier, bool Function() done) async {
  if (done()) return true;
  final completer = Completer<bool>();
  void listener() {
    if (done() && !completer.isCompleted) completer.complete(true);
  }

  notifier.addListener(listener);
  try {
    return await completer.future.timeout(_loadTimeout, onTimeout: () => false);
  } finally {
    notifier.removeListener(listener);
  }
}
