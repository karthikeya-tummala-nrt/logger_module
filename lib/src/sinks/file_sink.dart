import 'dart:io';
import '../models/log_record.dart';
import 'sink.dart';

class FileSink extends LogSink {
  final String basePath;
  final int maxFileSizeInBytes;
  
  late int _currentIndex;
  File? _currentFile;
  int _currentFileSize = 0;
  bool _initialized = false;

  FileSink({
    required super.formatter,
    required this.basePath,
    this.maxFileSizeInBytes = 5 * 1024 * 1024, // 5MB default
  });

  /// Lazily initializes on first write, ensuring all file I/O runs
  /// on the background Isolate (where write() is called) — never on Main.
  void _ensureInitialized() {
    if (_initialized) return;

    final dir = Directory(basePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _currentIndex = _findLatestIndex();
    _openCurrentFile();
    _initialized = true;
  }

  int _findLatestIndex() {
    if (!_fileExists(0)) return 0;

    // Exponential search for upper bound
    int low = 0;
    int high = 1;
    while (_fileExists(high)) {
      low = high;
      high *= 2;
    }

    // Binary search within [low, high]
    int latest = low;
    while (low <= high) {
      int mid = low + (high - low) ~/ 2;
      if (_fileExists(mid)) {
        latest = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return latest;
  }

  bool _fileExists(int index) {
    return File('$basePath/log_$index.txt').existsSync();
  }

  void _openCurrentFile() {
    final file = File('$basePath/log_$_currentIndex.txt');
    if (file.existsSync()) {
      _currentFileSize = file.lengthSync();
      // If the found file is already full, move to next
      if (_currentFileSize >= maxFileSizeInBytes) {
        _currentIndex++;
        _openCurrentFile();
        return;
      }
    } else {
      _currentFileSize = 0;
    }
    _currentFile = file;
  }

  @override
  void write(LogRecord record) {
    _ensureInitialized();

    final formatted = formatter.format(record) + '\n';
    final bytes = formatted.length; // Approximate for UTF-8 strings

    if (_currentFileSize + bytes >= maxFileSizeInBytes) {
      _rotate();
    }

    _currentFile?.writeAsStringSync(formatted, mode: FileMode.append, flush: true);
    _currentFileSize += formatted.length;
  }

  void _rotate() {
    _currentIndex++;
    _openCurrentFile();
  }

  @override
  void dispose() {
    _currentFile = null;
    _initialized = false;
  }
}
