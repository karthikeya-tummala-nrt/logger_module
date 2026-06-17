import '../models/log_record.dart';
import '../models/log_level.dart';
import 'formatter.dart';

class PrettyFormatter implements LogFormatter {
  final bool useColors;

  PrettyFormatter({this.useColors = true});

  @override
  String format(LogRecord record) {
    final color = useColors ? _getColor(record.level) : '';
    final reset = useColors ? '\x1B[0m' : '';
    
    final tagPart = record.tag != null ? '[${record.tag}] ' : '';
    final timeStr = record.timestamp.toIso8601String().split('T').last;
    
    var output = '$color[$timeStr] ${record.level.name.toUpperCase().padRight(7)}: $tagPart${record.message}$reset';
    
    if (record.error != null) {
      output += '\nError: ${record.error}';
    }
    
    if (record.stackTrace != null) {
      output += '\n${record.stackTrace}';
    }
    
    if (record.metadata != null && record.metadata!.isNotEmpty) {
      output += '\nMetadata: ${record.metadata}';
    }
    
    return output;
  }

  String _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose: return '\x1B[37m'; // Gray
      case LogLevel.debug: return '\x1B[34m';   // Blue
      case LogLevel.info: return '\x1B[32m';    // Green
      case LogLevel.warn: return '\x1B[33m';    // Yellow
      case LogLevel.error: return '\x1B[31m';   // Red
    }
  }
}
