import 'dart:async';
import 'dart:isolate';
import '../models/log_record.dart';
import '../sinks/sink.dart';
import 'logger_worker.dart';

class IsolateController {
  SendPort? _sendPort;
  final List<LogRecord> _buffer = [];
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  Future<void> init(List<LogSink> sinks) async {
    if (_isInitialized) return;
    
    _initCompleter = Completer<void>();
    final receivePort = ReceivePort();
    
    // We send a map because it's definitely sendable.
    // Note: The 'sinks' might still fail if they contain non-sendable data.
    // If that happens, we'd need a different initialization strategy.
    await Isolate.spawn(LoggerWorker.entryPoint, {
      'sendPort': receivePort.sendPort,
      'sinks': sinks,
    });

    final firstMessage = await receivePort.first;
    if (firstMessage is SendPort) {
      _sendPort = firstMessage;
      _isInitialized = true;
      _flushBuffer();
      _initCompleter?.complete();
    }
  }

  void log(LogRecord record) {
    if (_sendPort != null) {
      _sendPort!.send(record);
    } else {
      _buffer.add(record);
    }
  }

  void _flushBuffer() {
    for (final record in _buffer) {
      _sendPort?.send(record);
    }
    _buffer.clear();
  }

  Future<void> dispose() async {
    if (_sendPort != null) {
      _sendPort!.send('shutdown');
    }
    _isInitialized = false;
    _sendPort = null;
  }
}
