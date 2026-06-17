import 'dart:io';
import '../models/log_record.dart';
import 'sink.dart';

class ConsoleSink extends LogSink {
  ConsoleSink({required super.formatter});

  @override
  void write(LogRecord record) {
    stdout.writeln(formatter.format(record));
  }
}
