import 'dart:convert';
import '../models/log_record.dart';
import 'formatter.dart';

class JsonFormatter implements LogFormatter {
  @override
  String format(LogRecord record) {
    return jsonEncode(
      record.toJson(),
      toEncodable: (dynamic object) {
        try {
          return object.toJson();
        } catch (_) {
          return object.toString();
        }
      },
    );
  }
}
