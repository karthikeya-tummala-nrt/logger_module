import 'dart:io';
import '../models/log_record.dart';
import 'sink.dart';

class FileSink extends LogSink {
  final String basePath;
  final int maxFileSizeInBytes;
  
  late int _currentIndex;
  File? _currentFile;
  int _currentFileSize = 0;

  FileSink({
    required super.formatter,
    required this.basePath,
    this.maxFileSizeInBytes = 5 * 1024 * 1024, // 5MB default
  }) {
    _init();
  }

  void _init() {
    final dir = Directory(basePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _currentIndex = _findLatestIndex();
    _openCurrentFile();
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
    // No explicit close needed for writeAsStringSync, but good to null out
    _currentFile = null;
  }
}
