/// Typed errors for scoped-storage (SAF) file access.
///
/// The native side returns a small, stable set of error codes; the Dart wrapper
/// maps each one to a subclass here. Callers catch [SafException] and show a
/// friendly message — the app must never crash on a bad or revoked file
/// (CLAUDE.md §3.4). Messages are user-safe and never include file contents.
sealed class SafException implements Exception {
  /// A short, user-safe reason.
  final String message;

  const SafException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The user dismissed the system file picker without choosing a file. This is a
/// normal outcome, not a failure — callers usually just do nothing.
class SafCancelled extends SafException {
  const SafCancelled([super.message = 'File selection was cancelled.']);
}

/// The app has no (longer any) permission to read/write this URI. Typically the
/// user revoked the grant, or it was never persisted.
class SafPermissionDenied extends SafException {
  const SafPermissionDenied([
    super.message = 'Permission to access this file was denied.',
  ]);
}

/// The URI no longer points at a reachable document — the file was moved,
/// deleted, or the storage volume is gone.
class SafUriStale extends SafException {
  const SafUriStale([
    super.message = 'This file is no longer available.',
  ]);
}

/// A read or write failed part-way (I/O error). The original file is untouched
/// for writes (the atomic saver in Phase 3 guarantees temp-write-then-replace).
class SafIoFailure extends SafException {
  const SafIoFailure([super.message = 'Could not read or write the file.']);
}

/// Any error the native side reported that does not map to the cases above.
class SafUnknownFailure extends SafException {
  const SafUnknownFailure([super.message = 'File access failed.']);
}
