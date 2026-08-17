import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// How serious a log line is.
///
/// The order matters: anything below [AppLogger.minimumLevel] is dropped.
/// The set is fixed by the shared engineering standard
/// (`docs/guidelines/flutter_project_engineering_standard.md` §14.1).
enum LogLevel {
  /// Very fine detail — single rows, loop steps. Development builds only.
  trace(500, 'TRACE'),

  /// Useful development context — what a service is about to do.
  debug(700, 'DEBUG'),

  /// A normal, significant event — app started, file opened, save finished.
  info(800, 'INFO'),

  /// Unexpected but recoverable — a retry, a fallback path.
  warning(900, 'WARN'),

  /// An operation failed — a save failed, a parse broke.
  error(1000, 'ERROR'),

  /// The app cannot carry on — unrecoverable state or data corruption.
  fatal(1200, 'FATAL');

  const LogLevel(this.severity, this.label);

  /// Value handed to `dart:developer`, matching its usual severity scale.
  final int severity;

  /// Short name printed in the log line.
  final String label;
}

/// The one logging entry point for the whole app.
///
/// Why this exists: the app must never reach for `print` or `debugPrint`
/// (`avoid_print` is on, and both are banned in committed code). Routing every
/// line through one class gives us a single place to set the level and a single
/// place to enforce the privacy rule below.
///
/// ## What must never be logged
///
/// This app holds real secrets. **Never** pass any of these to `AppLogger`, not
/// even in a debug build:
///
/// - PINs, recovery codes, pairing codes, or derived keys
/// - Decrypted vault or document content, and any part of a user's file
/// - SAF URIs, file paths, or file names that came from the user
/// - LAN addresses, ports, or anything else identifying the user's network
///
/// Log the *operation* and the *error type* instead: `'save failed'` and the
/// exception's runtime type, never the exception message from a parser, which
/// often quotes the file content that broke it.
///
/// Nothing is written to disk. Lines go to the debug console only, so there is
/// no log file to leak and no rotation to manage. If file output is ever added,
/// the rotation rules in the engineering standard §14.4 apply.
class AppLogger {
  const AppLogger._();

  /// Set once at startup by [init]. Defaults to a safe production level so a
  /// missed `init()` call cannot turn on verbose logging in a release build.
  static LogLevel _minimumLevel = LogLevel.info;

  static bool _initialised = false;

  /// The level below which lines are dropped.
  static LogLevel get minimumLevel => _minimumLevel;

  /// Whether [init] has run. Logging before it works; it just uses the safe
  /// production default.
  static bool get isInitialised => _initialised;

  /// Chooses the log level for this build and marks the logger ready.
  ///
  /// Call this once from `main()` before `runApp`. The `dev` flavor gets the
  /// full firehose; every other build keeps `info` and above, so `trace` and
  /// `debug` produce no output in production.
  static void init({String? flavor}) {
    final name = flavor ?? const String.fromEnvironment('FLUTTER_APP_FLAVOR');
    _minimumLevel = name == 'dev' ? LogLevel.trace : LogLevel.info;
    _initialised = true;
  }

  /// Resets the logger to its startup state. For tests only.
  @visibleForTesting
  static void reset() {
    _minimumLevel = LogLevel.info;
    _initialised = false;
  }

  /// Very fine detail. Dropped outside the `dev` flavor.
  static void trace(String message, {String? area}) =>
      _write(LogLevel.trace, message, area: area);

  /// Development context. Dropped outside the `dev` flavor.
  static void debug(String message, {String? area}) =>
      _write(LogLevel.debug, message, area: area);

  /// A normal, significant event.
  static void info(String message, {String? area}) =>
      _write(LogLevel.info, message, area: area);

  /// Unexpected but recoverable.
  static void warning(String message, {String? area, Object? error}) =>
      _write(LogLevel.warning, message, area: area, error: error);

  /// An operation failed. Pass the `error` and, where you have it, the
  /// `stackTrace` — the standard requires both on this level.
  static void error(
    String message, {
    String? area,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    LogLevel.error,
    message,
    area: area,
    error: error,
    stackTrace: stackTrace,
  );

  /// The app cannot carry on. Pass the `error` and `stackTrace`.
  static void fatal(
    String message, {
    String? area,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    LogLevel.fatal,
    message,
    area: area,
    error: error,
    stackTrace: stackTrace,
  );

  /// Whether a line at [level] would be written right now.
  static bool isEnabled(LogLevel level) =>
      level.severity >= _minimumLevel.severity;

  static void _write(
    LogLevel level,
    String message, {
    String? area,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isEnabled(level)) return;

    developer.log(
      '[${level.label}] $message',
      name: area ?? 'TextData',
      level: level.severity,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
