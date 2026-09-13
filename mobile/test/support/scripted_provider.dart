/// Provider giả có kịch bản cố định, dùng cho test chuỗi dự phòng và repository.
library;

import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

class ScriptedProvider implements LotteryDataProvider {
  ScriptedProvider({
    required this.label,
    required this.kind,
    this.draws = const <DrawRecord>[],
    this.failure,
    this.available = true,
  });

  final String label;

  @override
  final ProviderKind kind;

  final List<DrawRecord> draws;
  final String? failure;
  final bool available;

  /// Số lần provider được gọi (kể cả lần lỗi).
  int calls = 0;

  /// Các khoảng ngày đã yêu cầu qua `getHistoricalResults` (kiểm tra cửa sổ đồng bộ).
  final List<({DateTime start, DateTime end})> ranges =
      <({DateTime start, DateTime end})>[];

  @override
  String get name => label;

  @override
  bool get isAvailable => available;

  @override
  String get availabilityNote => 'provider giả';

  @override
  Future<void> healthCheck() async {
    if (!available) throw ProviderException(label, availabilityNote);
  }

  Future<ProviderFetchResult> _result() async {
    calls += 1;
    if (failure != null) throw ProviderException(label, failure!);
    return ProviderFetchResult(
      provider: label,
      kind: kind,
      draws: draws,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ProviderFetchResult> getLatestResults({
    required Region region,
    int days = 7,
  }) => _result();

  @override
  Future<ProviderFetchResult> getResultsByDate({
    required Region region,
    required DateTime date,
  }) => _result();

  @override
  Future<ProviderFetchResult> getHistoricalResults({
    required Region region,
    required DateTime start,
    required DateTime end,
  }) {
    ranges.add((start: start, end: end));
    return _result();
  }
}
