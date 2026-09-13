/// Log nhẹ, không phụ thuộc package ngoài.
///
/// Log được giữ trong bộ đệm vòng để màn hình "Nguồn dữ liệu" hiển thị được
/// lịch sử đồng bộ gần nhất ngay cả khi không có DevTools.
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  const LogEntry({
    required this.at,
    required this.level,
    required this.tag,
    required this.message,
  });

  final DateTime at;
  final LogLevel level;
  final String tag;
  final String message;

  String get timestamp =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}:'
      '${at.second.toString().padLeft(2, '0')}';

  @override
  String toString() => '[$timestamp][${level.name}] $tag: $message';
}

class AppLogger {
  AppLogger({this.capacity = 200});

  final int capacity;
  final Queue<LogEntry> _entries = Queue<LogEntry>();

  /// Toàn bộ log gần nhất, mới nhất ở cuối.
  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);

  void debug(String tag, String message) => _add(LogLevel.debug, tag, message);

  void info(String tag, String message) => _add(LogLevel.info, tag, message);

  void warning(String tag, String message) =>
      _add(LogLevel.warning, tag, message);

  void error(String tag, String message, [Object? cause]) =>
      _add(LogLevel.error, tag, cause == null ? message : '$message — $cause');

  void clear() => _entries.clear();

  void _add(LogLevel level, String tag, String message) {
    final entry = LogEntry(
      at: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
    if (kDebugMode || level != LogLevel.debug) {
      debugPrint(entry.toString());
    }
  }
}

/// Logger dùng chung cho toàn app (đủ nhỏ để không cần thư viện DI).
final AppLogger appLogger = AppLogger();
