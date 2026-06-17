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

  // ──────────────────────────────────────────────────────────
  // 2. UNTAGGED logger — general-purpose logging.
  // ──────────────────────────────────────────────────────────
  final logger = Logger();
  logger.info('Application started');
  logger.debug('Running in debug mode');

  // ──────────────────────────────────────────────────────────
  // 3. TAGGED loggers — ready for dependency injection.
  //    Each instance auto-tags every log message.
  //
  //    In a real project you would register these in your DI
  //    container (e.g. GetIt) and inject them into your
  //    repositories / managers:
  //
  //      getIt.registerSingleton<Logger>(Logger('HEALTH'));
  //      getIt.registerSingleton<Logger>(Logger('COMM'), instanceName: 'comm');
  //
  // ──────────────────────────────────────────────────────────
  final healthLogger = Logger('HEALTH');
  final commLogger   = Logger('COMM_MANAGER');

  healthLogger.info('Heartbeat signal received');
  healthLogger.warn('Heart rate elevated');

  commLogger.info('CAN bus connection established');
  commLogger.debug('Sending frame 0x1A2');

  // ──────────────────────────────────────────────────────────
  // 4. Error logging with error objects and stack traces.
  // ──────────────────────────────────────────────────────────
  try {
    throw StateError('CAN bus write timeout');
  } catch (e, s) {
    commLogger.error('Failed to write to CAN bus', error: e, stackTrace: s);
  }

  // ──────────────────────────────────────────────────────────
  // 5. Per-call tag override — the instance tag can be
  //    overridden for a specific call if needed.
  // ──────────────────────────────────────────────────────────
  healthLogger.info('System-wide shutdown initiated', tag: 'SYSTEM');

  // ──────────────────────────────────────────────────────────
  // 6. Metadata support for structured context.
  // ──────────────────────────────────────────────────────────
  commLogger.warn(
    'Packet loss detected',
    metadata: {'lossRate': 0.12, 'interface': 'CAN0'},
  );

  // ──────────────────────────────────────────────────────────
  // 7. File rotation test — write enough to trigger rotation.
  // ──────────────────────────────────────────────────────────
  final spamLogger = Logger('ROTATION_TEST');
  for (var i = 0; i < 50; i++) {
    spamLogger.info('Filling log file with message #$i to trigger rotation');
  }

  // Give the background isolate time to flush
  await Future.delayed(Duration(seconds: 2));

  // ──────────────────────────────────────────────────────────
  // 8. Verify log files were created.
  // ──────────────────────────────────────────────────────────
  print('\n--- Log Directory Contents ---');
  final dir = Directory(logDir);
  if (dir.existsSync()) {
    final files = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
    print('Found ${files.length} log files:');
    for (var file in files) {
      print('  ${file.uri.pathSegments.last} (${(file as File).lengthSync()} bytes)');
    }
  }

  // ──────────────────────────────────────────────────────────
  // 9. Clean shutdown.
  // ──────────────────────────────────────────────────────────
  await Logger.dispose();
  print('\n--- Done ---');
}
