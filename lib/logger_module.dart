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

class Logger {
  static final IsolateController _controller = IsolateController();
  static LogLevel _level = LogLevel.info;

  /// Initializes the logger with the global [level] and a list of [sinks].
  /// Sinks will be offloaded to a background isolate.
  static Future<void> init({
    LogLevel level = LogLevel.info,
    required List<LogSink> sinks,
  }) async {
    _level = level;
    await _controller.init(sinks);
  }

  static void verbose(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.verbose, message, tag, error, stackTrace, metadata);
  }

  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, message, tag, error, stackTrace, metadata);
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, tag, error, stackTrace, metadata);
  }

  static void warn(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warn, message, tag, error, stackTrace, metadata);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.error, message, tag, error, stackTrace, metadata);
  }

  static void _log(LogLevel level, String message, String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata) {
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
