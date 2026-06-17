import 'log_level.dart';

class LogRecord {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogRecord({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  /// Converts the record to a map for structured logging (e.g. JSON).
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'metadata': metadata,
    };
  }
}
