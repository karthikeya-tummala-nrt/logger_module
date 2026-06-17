import '../models/log_record.dart';

abstract class LogFormatter {
  String format(LogRecord record);
}
