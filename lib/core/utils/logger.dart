import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide structured logger.
///
/// In debug builds it prints everything from [Level.debug] up. In release
/// builds it suppresses anything below [Level.warning], so verbose diagnostics
/// never reach production logs.
///
/// Never pass secrets, tokens, credentials, emails, or other PII to these
/// methods — log identifiers and states, not sensitive values.
abstract final class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message) => _logger.d(message);

  static void info(String message) => _logger.i(message);

  static void warning(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _logger.w(message, error: error, stackTrace: stackTrace);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
