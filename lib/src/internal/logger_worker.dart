import 'dart:isolate';
import '../models/log_record.dart';
import '../sinks/sink.dart';

class LoggerWorker {
  final List<LogSink> sinks;
  final ReceivePort _receivePort = ReceivePort();

  LoggerWorker(this.sinks);

  static void entryPoint(Map<String, dynamic> initialParams) {
    final SendPort sendPort = initialParams['sendPort'];
    final List<LogSink> sinks = initialParams['sinks'];
    
    final worker = LoggerWorker(sinks);
    sendPort.send(worker._receivePort.sendPort);

    worker._receivePort.listen((message) {
      if (message is LogRecord) {
        for (final sink in worker.sinks) {
          sink.write(message);
        }
      } else if (message == 'shutdown') {
        for (final sink in worker.sinks) {
          sink.dispose();
        }
        worker._receivePort.close();
      }
    });
  }
}
