/// Trừu tượng hoá nguồn dữ liệu xổ số.
///
/// Flutter không phụ thuộc trực tiếp vào một website/API nào: mỗi nguồn chỉ cần
/// hiện thực interface này, còn thứ tự ưu tiên do `LotteryProviderChain` quyết
/// định. Mọi kết quả đều kèm tên nguồn, thời điểm lấy và độ trễ để minh bạch
/// nguồn gốc dữ liệu.
library;

import '../../domain/lottery_domain.dart';
import '../models/draw_record.dart';
import '../models/sync_report.dart';

/// Kết quả một lần lấy dữ liệu thành công.
class ProviderFetchResult {
  const ProviderFetchResult({
    required this.provider,
    required this.kind,
    required this.draws,
    required this.fetchedAt,
    this.latencyMs = 0,
    this.fromCache = false,
    this.warnings = const <String>[],
  });

  final String provider;
  final ProviderKind kind;
  final List<DrawRecord> draws;
  final DateTime fetchedAt;
  final int latencyMs;
  final bool fromCache;
  final List<String> warnings;

  int get recordCount => draws.length;

  String get sourceLabel => fromCache ? '$provider (cache)' : provider;
}

/// Lỗi của một nguồn dữ liệu; chuỗi provider sẽ thử nguồn kế tiếp.
class ProviderException implements Exception {
  const ProviderException(this.provider, this.message, {this.cause});

  final String provider;
  final String message;
  final Object? cause;

  @override
  String toString() => '$provider: $message';
}

abstract class LotteryDataProvider {
  /// Tên hiển thị, cũng là khoá lưu `provider_status`.
  String get name;

  ProviderKind get kind;

  /// Nguồn có dùng được trên nền tảng hiện tại hay không.
  bool get isAvailable;

  /// Lý do nếu [isAvailable] là false.
  String get availabilityNote;

  /// Kiểm tra nguồn còn sống; ném [ProviderException] nếu không.
  Future<void> healthCheck();

  Future<ProviderFetchResult> getLatestResults({
    required Region region,
    int days = 7,
  });

  Future<ProviderFetchResult> getResultsByDate({
    required Region region,
    required DateTime date,
  });

  Future<ProviderFetchResult> getHistoricalResults({
    required Region region,
    required DateTime start,
    required DateTime end,
  });
}
