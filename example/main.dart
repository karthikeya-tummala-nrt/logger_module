import 'dart:io';
import 'package:logger_module/logger_module.dart';

void main() async {
  print('--- Logger Initialization ---');
  final logDir = '${Directory.current.path}/logs';
  
  await Logger.init(
    level: LogLevel.verbose,
    sinks: [
      ConsoleSink(formatter: PrettyFormatter()),
      FileSink(
        basePath: logDir,
        maxFileSizeInBytes: 1024, // 1KB for testing rotation
        formatter: JsonFormatter(),
      ),
    ],
  );

  print('--- Testing Levels and Filtering ---');
  Logger.verbose('This is a verbose message', tag: 'Test');
  Logger.debug('This is a debug message', tag: 'Test');
  Logger.info('This is an info message', tag: 'Test');
  Logger.warn('This is a warning', tag: 'Test');
  Logger.error('This is an error', tag: 'Test', error: Exception('Something went wrong'));

  print('--- Testing Metadata and StackTrace ---');
  try {
    throw StateError('Invalid state');
  } catch (e, s) {
    Logger.error('Caught error', tag: 'Lifecycle', error: e, stackTrace: s, metadata: {'id': 123});
  }

  print('--- Testing Rotation (Logging 100 messages) ---');
  for (var i = 0; i < 100; i++) {
    Logger.info('Filling log file with message #$i to trigger rotation', tag: 'Spam');
  }

  // Wait a bit for the isolate to process logs
  await Future.delayed(Duration(seconds: 2));

  print('--- Checking Log Directory ---');
  final dir = Directory(logDir);
  if (dir.existsSync()) {
    final files = dir.listSync();
    print('Found ${files.length} log files:');
    for (var file in files) {
      print(' - ${file.path} (${(file as File).lengthSync()} bytes)');
    }
  }

  print('--- Disposing Logger ---');
  await Logger.dispose();
  
  print('--- Verification Done ---');
}
