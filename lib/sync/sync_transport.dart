// Phase 12 — P2P LAN sync: the TCP transport (connect-then-choose flow).
//
// This layer is APP-AGNOSTIC: it moves opaque strings only, never app types
// (architecture.md §2, §9.2). Security lives entirely at the payload layer — a
// wrong code fails the AES-GCM tag during the handshake and the connection is
// refused (architecture.md §9.1).
//
// Flow (each line newline-terminated; everything after the salt is sealed):
//   Host   -> Client   base64(salt)          (clear; salt is not secret)
//   Client -> Host     encrypt(HELLO_SYNC)    (proves it has the code)
//   Host   -> Client   encrypt(ACCEPT_SYNC)   (immediately, on good auth)
//          ...host holds open; sender picks data...
//   Host   -> Client   encrypt(payloadJson)   (pushed on the sender's action)
//
// A wrong code: the host's decrypt of HELLO throws -> host sends DENIED (clear)
// and keeps listening; or the client's decrypt of ACCEPT throws -> client
// reports "incorrect code".
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'bounded_line_reader.dart';
import 'sync_constants.dart';
import 'sync_crypto.dart';

/// Host-side phases surfaced to the UI/provider.
enum HostPhase { listening, connected, denied, stopped, error }

/// Thrown for transport-level failures. User-safe messages.
class SyncTransportException implements Exception {
  final String message;
  const SyncTransportException(this.message);
  @override
  String toString() => 'SyncTransportException: $message';
}

/// The host (sender). Binds a socket, does the handshake with one client at a
/// time, holds the connection open, and pushes the payload on request.
class SyncHost {
  final ServerSocket _server;
  final Uint8List _salt;
  final Uint8List _sessionKey;

  final StreamController<HostPhase> _phases =
      StreamController<HostPhase>.broadcast();

  Socket? _client;
  BoundedLineReader? _reader;
  bool _authenticated = false;
  bool _stopped = false;

  final Completer<void> _clientConnected = Completer<void>();

  SyncHost._(this._server, this._salt, this._sessionKey) {
    _server.listen(_onConnection, onError: (_) => _emit(HostPhase.error));
    _emit(HostPhase.listening);
  }

  /// Binds an ephemeral port on all interfaces and starts listening. [code] is
  /// the fresh pairing code (from [SyncCrypto.generatePairingCode]). The salt
  /// is generated here and the session key derived once.
  static Future<SyncHost> start({required String code, int port = 0}) async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    final salt = SyncCrypto.randomBytes(SyncConstants.saltLength);
    final key = SyncCrypto.deriveKey(code, salt);
    return SyncHost._(server, salt, key);
  }

  int get port => _server.port;

  /// Live host phases (listening → connected → …).
  Stream<HostPhase> get phases => _phases.stream;

  /// Completes once a client has authenticated successfully.
  Future<void> get clientConnected => _clientConnected.future;

  bool get hasClient => _authenticated && _client != null;

  void _emit(HostPhase p) {
    if (!_phases.isClosed) _phases.add(p);
  }

  Future<void> _onConnection(Socket socket) async {
    // Single client at a time: if we already have one, refuse the newcomer.
    if (_client != null) {
      socket.destroy();
      return;
    }
    _client = socket;
    final reader = BoundedLineReader(socket, maxLineBytes: SyncConstants.handshakeLineCap);
    _reader = reader;
    try {
      // 1. Send the salt in the clear.
      socket.add(utf8.encode('${base64.encode(_salt)}\n'));
      await socket.flush();

      // 2. Read the client's HELLO and verify by decrypting it.
      final helloWire =
          await reader.readLineWithTimeout(SyncConstants.socketTimeout);
      String hello;
      try {
        hello = SyncCrypto.decryptWire(_sessionKey, helloWire);
      } catch (_) {
        // Wrong code — tell the client and keep listening for another.
        socket.add(utf8.encode('${SyncConstants.denied}\n'));
        await socket.flush();
        _emit(HostPhase.denied);
        await _dropClient();
        return;
      }
      if (hello != SyncConstants.helloSync) {
        socket.add(utf8.encode('${SyncConstants.denied}\n'));
        await socket.flush();
        _emit(HostPhase.denied);
        await _dropClient();
        return;
      }

      // 3. Good auth — accept immediately and hold open.
      socket.add(utf8.encode(
          '${SyncCrypto.encryptWire(_sessionKey, SyncConstants.acceptSync)}\n'));
      await socket.flush();
      _authenticated = true;
      _emit(HostPhase.connected);
      if (!_clientConnected.isCompleted) _clientConnected.complete();

      // Notice if the client drops while we hold the connection open.
      reader.closed.then((_) {
        if (!_stopped && _authenticated) {
          _authenticated = false;
          _client = null;
          _emit(HostPhase.listening);
        }
      });
    } catch (_) {
      await _dropClient();
      if (!_stopped) _emit(HostPhase.listening);
    }
  }

  Future<void> _dropClient() async {
    final c = _client;
    _client = null;
    _authenticated = false;
    try {
      await _reader?.dispose();
    } catch (_) {}
    _reader = null;
    c?.destroy();
  }

  /// Pushes the opaque [payload] string to the connected, authenticated client.
  /// Throws if there is no such client (arch §12 test).
  Future<void> sendToConnectedClient(String payload) async {
    final c = _client;
    if (!_authenticated || c == null) {
      throw const SyncTransportException('No device is connected.');
    }
    // Switch to the larger payload cap is not needed on the host (it only
    // writes); the write is a single sealed line.
    c.add(utf8.encode('${SyncCrypto.encryptWire(_sessionKey, payload)}\n'));
    await c.flush();
  }

  Future<void> stop() async {
    _stopped = true;
    await _dropClient();
    try {
      await _server.close();
    } catch (_) {}
    _emit(HostPhase.stopped);
    await _phases.close();
  }
}

/// The client (receiver). Connects, authenticates with the code, then waits for
/// the sender to push a payload.
class SyncClient {
  final Socket _socket;
  final BoundedLineReader _reader;
  final Uint8List _sessionKey;

  SyncClient._(this._socket, this._reader, this._sessionKey);

  /// Connects to [host]:[port], reads the salt, derives the key from [code],
  /// sends HELLO, and waits for ACCEPT. Throws [SyncTransportException] on a
  /// wrong code, a refusal, or a timeout.
  static Future<SyncClient> connect({
    required String host,
    required int port,
    required String code,
  }) async {
    final socket = await Socket.connect(host, port,
        timeout: SyncConstants.connectTimeout);
    // The payload can be large, so read with the payload cap from the start.
    final reader =
        BoundedLineReader(socket, maxLineBytes: SyncConstants.payloadLineCap);
    try {
      // 1. Read the salt (clear).
      final saltLine =
          await reader.readLineWithTimeout(SyncConstants.socketTimeout);
      final salt = base64.decode(saltLine.trim());
      final key = SyncCrypto.deriveKey(code, Uint8List.fromList(salt));

      // 2. Send HELLO sealed under the derived key.
      socket.add(utf8.encode(
          '${SyncCrypto.encryptWire(key, SyncConstants.helloSync)}\n'));
      await socket.flush();

      // 3. Read the reply: either DENIED (clear) or a sealed ACCEPT.
      final reply =
          await reader.readLineWithTimeout(SyncConstants.socketTimeout);
      if (reply.trim() == SyncConstants.denied) {
        socket.destroy();
        throw const SyncTransportException('The code was not accepted.');
      }
      String accept;
      try {
        accept = SyncCrypto.decryptWire(key, reply);
      } catch (_) {
        socket.destroy();
        throw const SyncTransportException('Incorrect code.');
      }
      if (accept != SyncConstants.acceptSync) {
        socket.destroy();
        throw const SyncTransportException('Unexpected reply from the host.');
      }
      return SyncClient._(socket, reader, key);
    } on SyncTransportException {
      rethrow;
    } catch (e) {
      socket.destroy();
      throw SyncTransportException('Could not connect: ${_safe(e)}');
    }
  }

  /// Waits for the sender to push the payload. Uses the long
  /// [SyncConstants.payloadWaitTimeout] because a person is choosing on the
  /// other device. Returns the opaque payload string.
  Future<String> awaitPayload() async {
    final wire =
        await _reader.readLineWithTimeout(SyncConstants.payloadWaitTimeout);
    try {
      return SyncCrypto.decryptWire(_sessionKey, wire);
    } catch (_) {
      throw const SyncTransportException('The received data could not be read.');
    }
  }

  Future<void> close() async {
    await _reader.dispose();
    _socket.destroy();
  }

  static String _safe(Object e) {
    // Keep timeouts readable, hide anything that might carry detail we should
    // not surface.
    if (e is TimeoutException) return 'timed out';
    if (e is SocketException) return 'network error';
    return 'network error';
  }
}

/// Lists this device's non-loopback IPv4 addresses so the host can advertise a
/// LAN address in the QR / connection details. Not used by the loopback tests.
Future<List<String>> localIpv4Addresses() async {
  final result = <String>[];
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        result.add(addr.address);
      }
    }
  } catch (_) {
    // No network — return empty; the UI shows manual entry only.
  }
  return result;
}
