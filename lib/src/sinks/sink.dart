import '../models/log_record.dart';
import '../formatters/formatter.dart';

abstract class LogSink {
  final LogFormatter formatter;

  LogSink({required this.formatter});

  void write(LogRecord record);
  
  void dispose() {}
}
