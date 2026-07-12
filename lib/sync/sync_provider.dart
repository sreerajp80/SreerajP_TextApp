// Phase 12 — P2P LAN sync: state orchestration (task 12.7).
//
// A [ChangeNotifier] that drives the transport, builds the payload from the
// chosen categories, and applies imports through [SyncDataAccess]. It is the
// only place the host and client flows are wired together.
//
// It never logs the code, keys, or payload contents (security-rules). The
// device key is provisioned once with Random.secure() and kept in secure
// storage; it is never synced.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/key_value_store.dart';
import '../core/storage/storage_providers.dart';
import '../core/theme/theme_controller.dart';
import '../shell/home/recents_controller.dart';
import '../shell/tabs/tabs_controller.dart';
import 'payload.dart';
import 'sync_constants.dart';
import 'sync_crypto.dart';
import 'sync_data_access.dart';
import 'sync_transport.dart';

/// Which side (if any) this device is currently acting as.
enum SyncRole { idle, host, client }

/// Client-side progress.
enum ClientPhase { idle, connecting, connected, waiting, applying, done, error }

/// The result of applying a received payload, for the summary UI.
class SyncSummary {
  final Map<String, RecordMergeResult> records;
  final SettingsMergeResult settings;

  const SyncSummary({required this.records, required this.settings});

  int get totalAdded =>
      records.values.fold(0, (sum, r) => sum + r.added) + settings.applied;
  int get totalKept =>
      records.values.fold(0, (sum, r) => sum + r.kept) + settings.kept;
}

/// Orchestrates a host or client sync session.
class SyncController extends ChangeNotifier {
  final SyncDataAccess _dataAccess;
  final KeyValueStore _store;

  /// Called once after a receive has applied a payload, with the summary that
  /// was just built. The provider wiring uses this to reload the UI (recents,
  /// settings) so freshly added data shows without an app restart. Optional so
  /// the controller stays testable without Riverpod.
  final void Function(SyncSummary summary)? onApplied;

  SyncController({
    required SyncDataAccess dataAccess,
    required KeyValueStore store,
    this.onApplied,
  })  : _dataAccess = dataAccess,
        _store = store;

  // --- Shared state ---------------------------------------------------------

  SyncRole _role = SyncRole.idle;
  SyncRole get role => _role;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- Host state -----------------------------------------------------------

  SyncHost? _host;
  StreamSubscription<HostPhase>? _phaseSub;
  bool _disposed = false;
  String? _code;
  int? _port;
  List<String> _ips = const [];
  HostPhase _hostPhase = HostPhase.stopped;
  bool _sending = false;
  bool _payloadSent = false;

  String? get pairingCode => _code;
  String? get formattedCode => _code == null ? null : SyncCrypto.formatCode(_code!);
  int? get port => _port;
  List<String> get ips => _ips;
  HostPhase get hostPhase => _hostPhase;
  bool get isSending => _sending;
  bool get payloadSent => _payloadSent;
  bool get hostConnected => _hostPhase == HostPhase.connected;

  /// The QR URI for the first advertised IP (or a chosen [ip]). Null until the
  /// host is listening and an IP is known.
  String? qrUri({String? ip}) {
    final code = _code;
    final port = _port;
    final host = ip ?? (_ips.isNotEmpty ? _ips.first : null);
    if (code == null || port == null || host == null) return null;
    return SyncCrypto.buildQrUri(QrPairing(host: host, port: port, code: code));
  }

  // --- Client state ---------------------------------------------------------

  ClientPhase _clientPhase = ClientPhase.idle;
  ClientPhase get clientPhase => _clientPhase;
  SyncSummary? _summary;
  SyncSummary? get summary => _summary;

  // --- Host flow ------------------------------------------------------------

  /// Starts hosting: provisions the device key, generates a fresh code, binds a
  /// socket, and begins listening.
  Future<void> startHost() async {
    await _ensureDeviceKey();
    _reset();
    _role = SyncRole.host;
    _code = SyncCrypto.generatePairingCode();
    try {
      final host = await SyncHost.start(code: _code!);
      _host = host;
      _port = host.port;
      _ips = await localIpv4Addresses();
      _phaseSub = host.phases.listen((p) {
        _hostPhase = p;
        _notify();
      });
      _hostPhase = HostPhase.listening;
    } catch (e) {
      _fail('Could not start sharing.');
    }
    _notify();
  }

  /// Full sync (fresh device): all categories + settings, overwrite settings.
  Future<void> pushFullSync() => _push(
        categories: SyncConstants.allCategories,
        includeSettings: true,
        mode: SyncConstants.syncModeFull,
      );

  /// Selective sync: chosen categories (add-only), settings fill-only if asked.
  Future<void> pushSelective({
    required List<String> categories,
    required bool includeSettings,
  }) =>
      _push(
        categories: categories,
        includeSettings: includeSettings,
        mode: SyncConstants.syncModeIncremental,
      );

  Future<void> _push({
    required List<String> categories,
    required bool includeSettings,
    required String mode,
  }) async {
    final host = _host;
    if (host == null || !host.hasClient) {
      _errorMessage = 'No device is connected yet.';
      _notify();
      return;
    }
    _sending = true;
    _errorMessage = null;
    _notify();
    try {
      final payload = await _buildPayload(
        categories: categories,
        includeSettings: includeSettings,
        mode: mode,
      );
      await host.sendToConnectedClient(payload.toWireJson());
      _payloadSent = true;
    } catch (e) {
      _errorMessage = 'Could not send the data.';
    } finally {
      _sending = false;
      _notify();
    }
  }

  Future<SyncPayload> _buildPayload({
    required List<String> categories,
    required bool includeSettings,
    required String mode,
  }) async {
    final recordsByCategory = <String, List<Map<String, Object?>>>{};
    for (final c in categories) {
      recordsByCategory[c] = await _dataAccess.exportCategory(c);
    }
    final settings =
        includeSettings ? _dataAccess.exportSettings() : <String, Object?>{};
    return SyncPayload.build(
      syncMode: mode,
      categories: categories,
      recordsByCategory: recordsByCategory,
      settings: settings,
    );
  }

  Future<void> stopHost() async {
    await _host?.stop();
    _host = null;
    _role = SyncRole.idle;
    _hostPhase = HostPhase.stopped;
    _notify();
  }

  // --- Client flow ----------------------------------------------------------

  /// Connects from a scanned QR string, then waits for and applies the payload.
  Future<void> connectFromScan(String rawQr) async {
    final parsed = SyncCrypto.parseQrUri(rawQr);
    if (!parsed.isOk) {
      _clientPhase = ClientPhase.error;
      _errorMessage = parsed.error;
      _role = SyncRole.client;
      _notify();
      return;
    }
    final p = parsed.pairing!;
    await connectManual(host: p.host, port: p.port, code: p.code);
  }

  /// Connects with typed details, then waits for and applies the payload.
  Future<void> connectManual({
    required String host,
    required int port,
    required String code,
  }) async {
    await _ensureDeviceKey();
    _reset();
    _role = SyncRole.client;
    _clientPhase = ClientPhase.connecting;
    _errorMessage = null;
    _notify();

    final normalized = SyncCrypto.normalizeCode(code);
    if (!SyncCrypto.isValidCode(normalized)) {
      _clientPhase = ClientPhase.error;
      _errorMessage = 'That code does not look right.';
      _notify();
      return;
    }

    SyncClient? client;
    try {
      client =
          await SyncClient.connect(host: host, port: port, code: normalized);
      _clientPhase = ClientPhase.waiting;
      _notify();

      final json = await client.awaitPayload();
      _clientPhase = ClientPhase.applying;
      _notify();

      final payload = SyncPayload.validateAndParse(json);
      final summary = await _apply(payload);
      _summary = summary;
      _clientPhase = ClientPhase.done;
      // Tell the UI to reload the data we just wrote (recents, settings) so it
      // shows without an app restart. Guarded so a listener error cannot turn a
      // successful sync into a failure.
      try {
        onApplied?.call(summary);
      } catch (_) {}
    } on SyncTransportException catch (e) {
      _clientPhase = ClientPhase.error;
      _errorMessage = e.message;
    } on PayloadException catch (e) {
      _clientPhase = ClientPhase.error;
      _errorMessage = e.message;
    } catch (_) {
      _clientPhase = ClientPhase.error;
      _errorMessage = 'The sync could not be completed.';
    } finally {
      await client?.close();
      _notify();
    }
  }

  /// Applies a validated payload: add-only records + merged settings.
  Future<SyncSummary> _apply(SyncPayload payload) async {
    final recordResults = <String, RecordMergeResult>{};
    for (final entry in payload.records.entries) {
      final existing = await _dataAccess.existingKeys(entry.key);
      final result = mergeRecords(
        category: entry.key,
        records: entry.value,
        existingKeys: existing,
      );
      await _dataAccess.addRecords(entry.key, result.toAdd);
      recordResults[entry.key] = result;
    }
    final settingsResult = mergeSettings(
      incoming: payload.settings,
      existingKeys: _dataAccess.existingSettingKeys(),
      isFull: payload.isFull,
    );
    await _dataAccess.applySettings(settingsResult.toApply);
    return SyncSummary(records: recordResults, settings: settingsResult);
  }

  // --- Device key -----------------------------------------------------------

  /// Ensures this device has its own P2P key in secure storage. Generated once
  /// with Random.secure(); never synced, never logged. Used by the secret
  /// re-seal machinery for any future secret-bearing record category.
  Future<void> _ensureDeviceKey() async {
    final existing = await _store.getString(SyncConstants.deviceKeyStorageKey);
    if (existing == null) {
      final key = base64.encode(SyncCrypto.randomBytes(32));
      await _store.setString(SyncConstants.deviceKeyStorageKey, key);
    }
  }

  // --- Helpers --------------------------------------------------------------

  /// Notifies listeners unless the controller has been disposed (the host phase
  /// stream can fire during teardown).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _reset() {
    _errorMessage = null;
    _summary = null;
    _payloadSent = false;
    _sending = false;
    _clientPhase = ClientPhase.idle;
  }

  void _fail(String message) {
    _errorMessage = message;
    _role = SyncRole.idle;
  }

  @override
  void dispose() {
    _disposed = true;
    _phaseSub?.cancel();
    _host?.stop();
    super.dispose();
  }
}

/// Builds the real data access from the Phase 1 repositories + settings store.
final syncDataAccessProvider = FutureProvider<SyncDataAccess>((ref) async {
  final favorites = await ref.watch(favoritesRepositoryProvider.future);
  final bookmarks = await ref.watch(bookmarksRepositoryProvider.future);
  final recents = await ref.watch(recentsRepositoryProvider.future);
  final store = ref.watch(keyValueStoreSyncProvider);
  return RepositorySyncDataAccess(
    favorites: favorites,
    bookmarks: bookmarks,
    recents: recents,
    store: store,
  );
});

/// The sync controller. Reads it only after [syncDataAccessProvider] has data
/// (the sync screen shows a loader until then).
final syncControllerProvider = Provider<SyncController>((ref) {
  final access = ref.watch(syncDataAccessProvider).requireValue;
  final store = ref.watch(keyValueStoreSyncProvider);
  final controller = SyncController(
    dataAccess: access,
    store: store,
    onApplied: (summary) {
      // Reload the UI that reads the data a receive may have just written, so
      // added records and applied settings show without an app restart.
      if (summary.records.containsKey(SyncConstants.categoryRecents)) {
        ref.invalidate(recentsControllerProvider);
      }
      if (summary.settings.applied > 0) {
        ref.invalidate(themeControllerProvider);
        ref.invalidate(tabsControllerProvider);
      }
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});
