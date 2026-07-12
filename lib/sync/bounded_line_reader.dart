// Phase 12 — P2P LAN sync: a memory-safe, newline-delimited line reader.
//
// A hostile peer must not be able to exhaust our memory by sending one endless
// line with no `\n` (a giant-line / slow-loris DoS). This reader buffers bytes
// from a byte stream, splits on `\n`, and enforces a hard cap on how many bytes
// it will hold before it has seen a newline. There is NO unbounded `readLine`
// anywhere in the sync code (security-rules; architecture.md §9.2).
//
// The handshake and the payload use different caps (small vs large), so the
// caller passes the cap it wants.
library;

import 'dart:async';
import 'dart:convert';

/// Thrown when a line grows past the configured cap. User-safe message.
class LineTooLongException implements Exception {
  final int cap;
  const LineTooLongException(this.cap);
  @override
  String toString() => 'LineTooLongException: line exceeded $cap bytes';
}

/// Reads newline-terminated UTF-8 lines from a stream of byte chunks with a
/// hard length cap.
class BoundedLineReader {
  final int maxLineBytes;

  final StreamSubscription<List<int>> _sub;
  final List<int> _buffer = [];
  final List<String> _lines = [];
  final List<Completer<String>> _waiters = [];

  final Completer<void> _closed = Completer<void>();
  Object? _error;
  bool _done = false;

  BoundedLineReader(Stream<List<int>> stream, {required this.maxLineBytes})
      : _sub = stream.listen(null) {
    _sub
      ..onData(_onData)
      ..onError(_onError)
      ..onDone(_onDone);
  }

  /// Completes when the underlying stream closes or errors, so a caller (e.g.
  /// the host) can notice the peer dropping.
  Future<void> get closed => _closed.future;

  void _onData(List<int> chunk) {
    if (_done) return;
    for (final byte in chunk) {
      if (byte == 0x0a) {
        // newline — flush the buffered line
        final line = utf8.decode(_buffer, allowMalformed: true);
        _buffer.clear();
        _emit(line);
      } else {
        _buffer.add(byte);
        if (_buffer.length > maxLineBytes) {
          _onError(LineTooLongException(maxLineBytes));
          return;
        }
      }
    }
  }

  void _emit(String line) {
    // Strip a trailing CR so CRLF senders are tolerated.
    final clean = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(clean);
    } else {
      _lines.add(clean);
    }
  }

  void _onError(Object error) {
    if (_done) return;
    _error = error;
    _finish();
  }

  void _onDone() {
    if (_done) return;
    _finish();
  }

  void _finish() {
    _done = true;
    _sub.cancel();
    // Fail any pending waiters so no one hangs forever.
    for (final w in _waiters) {
      if (!w.isCompleted) {
        w.completeError(_error ?? const _StreamClosed());
      }
    }
    _waiters.clear();
    if (!_closed.isCompleted) _closed.complete();
  }

  /// Reads the next line. If the stream already ended (or a line was too long),
  /// throws the stored error / a "closed" error. Never buffers past the cap.
  Future<String> readLine() {
    if (_lines.isNotEmpty) {
      return Future.value(_lines.removeAt(0));
    }
    if (_done) {
      return Future.error(_error ?? const _StreamClosed());
    }
    final c = Completer<String>();
    _waiters.add(c);
    return c.future;
  }

  /// Reads the next line but gives up after [timeout], throwing a
  /// [TimeoutException]. Used with the per-line socket timeout.
  Future<String> readLineWithTimeout(Duration timeout) {
    return readLine().timeout(timeout);
  }

  Future<void> dispose() async {
    if (!_done) {
      _done = true;
      await _sub.cancel();
      if (!_closed.isCompleted) _closed.complete();
    }
  }
}

/// Internal marker error used when the stream closes with no other error.
class _StreamClosed implements Exception {
  const _StreamClosed();
  @override
  String toString() => 'StreamClosed: the connection was closed';
}
