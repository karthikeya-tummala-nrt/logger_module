import 'src/models/log_level.dart';
import 'src/models/log_record.dart';
import 'src/sinks/sink.dart';
import 'src/internal/isolate_controller.dart';

export 'src/models/log_level.dart';
export 'src/models/log_record.dart';
export 'src/sinks/sink.dart';
export 'src/sinks/console_sink.dart';
export 'src/sinks/file_sink.dart';
export 'src/formatters/formatter.dart';
export 'src/formatters/pretty_formatter.dart';
export 'src/formatters/json_formatter.dart';

/// A high-performance, non-blocking logger that offloads all formatting
/// and I/O to a background Isolate.
///
/// **Instantiable & DI-friendly**: Create tagged instances for dependency
/// injection, or untagged instances for general-purpose logging.
///
/// ```dart
/// // Tagged instance — ideal for DI registration
/// final healthLogger = Logger('HEALTH');
/// healthLogger.info('Heartbeat received'); // auto-tagged [HEALTH]
///
/// // Untagged instance
/// final logger = Logger();
/// logger.info('App started');
/// ```
///
/// All instances share a single background Isolate, initialized once
/// via [Logger.init].
class Logger {
  /// Shared backend — all Logger instances use the same isolate controller.
  static final IsolateController _controller = IsolateController();
  static LogLevel _level = LogLevel.info;

  /// The tag automatically applied to all log messages from this instance.
  /// Can be overridden per-call by passing a `tag` argument to any log method.
  final String? tag;

  /// Creates a [Logger] instance with an optional [tag].
  ///
  /// The [tag] is automatically prepended to every log message from this
  /// instance, eliminating the need to pass it on every call.
  ///
  /// ```dart
  /// // For dependency injection
  /// final commLogger = Logger('COMM_MANAGER');
  /// getIt.registerSingleton<Logger>(commLogger);
  ///
  /// // Untagged
  /// final logger = Logger();
  /// ```
  const Logger([this.tag]);

  /// Initializes the shared logging backend with the global [level] and [sinks].
  ///
  /// Must be called once at app startup before any logging occurs.
  /// All [Logger] instances — regardless of tag — share the same backend.
  ///
  /// ```dart
  /// await Logger.init(
  ///   level: LogLevel.info,
  ///   sinks: [
  ///     ConsoleSink(formatter: PrettyFormatter()),
  ///     FileSink(basePath: './logs', formatter: JsonFormatter()),
  ///   ],
  /// );
  /// ```
  static Future<void> init({
    LogLevel level = LogLevel.info,
    required List<LogSink> sinks,
  }) async {
    _level = level;
    await _controller.init(sinks);
  }

  /// Logs a message at [LogLevel.verbose].
  ///
  /// If [tag] is provided, it overrides this instance's default tag.
  void verbose(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.verbose, message, tag ?? this.tag, error, stackTrace, metadata);
  }

  /// Logs a message at [LogLevel.debug].
  ///
  /// If [tag] is provided, it overrides this instance's default tag.
  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, message, tag ?? this.tag, error, stackTrace, metadata);
  }

  /// Logs a message at [LogLevel.info].
  ///
  /// If [tag] is provided, it overrides this instance's default tag.
  void info(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, tag ?? this.tag, error, stackTrace, metadata);
  }

  /// Logs a message at [LogLevel.warn].
  ///
  /// If [tag] is provided, it overrides this instance's default tag.
  void warn(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warn, message, tag ?? this.tag, error, stackTrace, metadata);
  }

  /// Logs a message at [LogLevel.error].
  ///
  /// If [tag] is provided, it overrides this instance's default tag.
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.error, message, tag ?? this.tag, error, stackTrace, metadata);
  }

  void _log(LogLevel level, String message, String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata) {
    if (level >= _level) {
      final record = LogRecord(
        level: level,
        message: message,
        tag: tag,
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );
      _controller.log(record);
    }
  }

  /// Shuts down the background isolate and flushes pending logs.
  static Future<void> dispose() async {
    await _controller.dispose();
  }
}
