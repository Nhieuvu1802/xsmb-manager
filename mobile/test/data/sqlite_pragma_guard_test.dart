/// Chốt chặn hồi quy cho lỗi "màn hình trắng khi cài mới".
///
/// sqflite chạy `onCreate`/`onUpgrade` **bên trong một transaction**, mà SQLite
/// từ chối đổi chế độ journal/synchronous lúc đó:
///
/// * `PRAGMA journal_mode = WAL` → "cannot change into wal mode from within a transaction"
/// * `PRAGMA synchronous = NORMAL` → "Safety level may not be changed inside a transaction"
///
/// Khi hai lệnh này nằm trong `onCreate`, `openDatabase()` ném lỗi ngay trước
/// `runApp()` trên máy cài mới ⇒ app chỉ còn nền trắng. Test này đọc chính mã
/// nguồn store để bảo đảm các PRAGMA đó luôn nằm ở `onConfigure` (ngoài
/// transaction) — thứ mà test dùng store giả không thể phát hiện.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/data/local/sqlite_local_store.dart';

/// Trả về đoạn mã nằm giữa `marker` và lần xuất hiện `stop` kế tiếp.
String _section(String source, String marker, String stop) {
  final start = source.indexOf(marker);
  expect(start, isNonNegative, reason: 'Không tìm thấy "$marker"');
  final end = source.indexOf(stop, start);
  expect(end, isNonNegative, reason: 'Không tìm thấy "$stop" sau "$marker"');
  return source.substring(start, end);
}

void main() {
  group('SQLite – PRAGMA phải chạy ngoài transaction', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/src/data/local/sqlite_local_store.dart',
      ).readAsStringSync();
    });

    test('onCreate chỉ tạo schema, không đổi journal_mode/synchronous', () {
      final onCreate = _section(source, 'onCreate:', 'onUpgrade:');
      expect(onCreate, contains('_createSchema'));
      expect(onCreate, isNot(contains('journal_mode')));
      expect(onCreate, isNot(contains('synchronous')));
      expect(onCreate, isNot(contains('foreign_keys')));
    });

    test('onConfigure giữ PRAGMA cấp kết nối', () {
      final configure = _section(
        source,
        'Future<void> _configure(',
        'Future<void> _createSchema(',
      );
      expect(configure, contains('foreign_keys'));
      expect(configure, contains('journal_mode'));
      expect(configure, contains('synchronous'));
      expect(configure, contains('busy_timeout'));
    });

    test('openDatabase truyền onConfigure', () {
      final open = _section(
        source,
        'Future<Database> _openDatabase(',
        'onCreate:',
      );
      expect(open, contains('onConfigure: _configure'));
      expect(open, contains('version: kLocalSchemaVersion'));
    });

    test('schema không chứa PRAGMA', () {
      expect(kLocalSchema.toLowerCase(), isNot(contains('pragma')));
      expect(kLocalSchema, contains('CREATE TABLE IF NOT EXISTS dataset_meta'));
    });

    test('mở database có đường thoát khi schema hỏng', () {
      expect(source, contains('deleteDatabase(path)'));
      expect(source, contains('inMemoryDatabasePath'));
    });
  });
}
