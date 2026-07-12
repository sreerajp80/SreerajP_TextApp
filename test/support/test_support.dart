import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/preferences_store.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/storage/secure_store.dart';
import 'package:text_data/core/storage/storage_models.dart';
import 'package:text_data/shell/home/recents_controller.dart';

/// Builds an in-memory [KeyValueStore] for tests: real `shared_preferences`
/// with mock initial values, plus an in-memory secure store.
///
/// Call inside a test after the binding is initialized (testWidgets does this;
/// a plain unit test must call `TestWidgetsFlutterBinding.ensureInitialized()`).
Future<KeyValueStore> inMemoryKeyValueStore([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await PreferencesStore.open();
  return KeyValueStore(prefs: prefs, secure: InMemorySecureStore());
}

/// Wraps [home] in a [MaterialApp] with the app's localization delegates, so any
/// screen using `AppLocalizations.of(context)` resolves in widget tests. Use this
/// instead of a bare `MaterialApp(home: ...)` for any localized screen.
MaterialApp localizedApp({required Widget home}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// A [SafService] with no device behind it. Answers accessibility from a fixed
/// set, serves fixed byte content, and returns a preset pick result.
class FakeSafService extends SafService {
  final Set<String> accessibleUris;
  final Map<String, Uint8List> contents;
  final SafFile? pickResult;
  final SafFile? createResult;
  final SafException? createError;
  String? lastSuggestedName;
  String? lastMimeType;
  Uint8List? lastCreatedBytes;

  FakeSafService({
    this.accessibleUris = const {},
    this.contents = const {},
    this.pickResult,
    this.createResult,
    this.createError,
  });

  @override
  Future<bool> isAccessible(String uri) async => accessibleUris.contains(uri);

  @override
  Future<Uint8List> readBytes(String uri) async {
    if (uri == createResult?.uri && lastCreatedBytes != null) {
      return lastCreatedBytes!;
    }
    return contents[uri] ?? Uint8List(0);
  }

  @override
  Future<void> writeBytes(String uri, Uint8List bytes) async {}

  @override
  Future<SafFile> pickFile({List<String> mimeTypes = const ['*/*']}) async {
    final result = pickResult;
    if (result == null) throw const SafCancelled();
    return result;
  }

  @override
  Future<SafFile> createDocument({
    required String suggestedName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    lastSuggestedName = suggestedName;
    lastMimeType = mimeType;
    lastCreatedBytes = Uint8List.fromList(bytes);
    final error = createError;
    if (error != null) throw error;
    final result = createResult;
    if (result == null) throw const SafCancelled();
    return result;
  }

  @override
  Future<List<String>> persistedUris() async =>
      accessibleUris.toList(growable: false);

  @override
  Future<void> releasePermission(String uri) async {}
}

/// A recents controller that serves a fixed list with no database, so widget
/// tests run under the fake-async test clock (a real sqflite isolate would
/// never resolve there). Also used to keep the Home screen inert in tests that
/// only care about the shell around it.
class StubRecentsController extends RecentsController {
  final List<RecentEntry> initial;
  final bool refreshWhenRecorded;

  StubRecentsController([
    this.initial = const [],
    this.refreshWhenRecorded = false,
  ]);

  @override
  Future<List<RecentEntry>> build() async => initial;

  @override
  Future<void> remove(String fingerprint) async {
    final current = state.value ?? const [];
    state = AsyncData(
      current.where((e) => e.file.fingerprint != fingerprint).toList(),
    );
  }

  @override
  Future<void> clearAll() async {
    state = const AsyncData([]);
  }

  @override
  Future<void> recordOpen(SafFile file, String fingerprint) async {
    if (!refreshWhenRecorded) return;
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    state = AsyncData(initial);
  }
}

/// Helper to build a Home recents [RecentEntry] for tests.
RecentEntry recentEntry(String name, {bool available = true}) => RecentEntry(
  file: RecentFile(
    fingerprint: '10-$name',
    uri: 'content://$name',
    displayName: name,
    lastOpenedAt: 1000,
  ),
  available: available,
);
