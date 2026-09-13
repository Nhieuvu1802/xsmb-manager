/// Provider cuối chuỗi: đọc từ database cục bộ trên thiết bị.
library;

import '../../core/utils/lottery_dates.dart';
import '../../domain/lottery_domain.dart';
import '../local/local_store.dart';
import '../models/draw_record.dart';
import '../models/sync_report.dart';
import 'lottery_data_provider.dart';

class LocalCacheProvider implements LotteryDataProvider {
  LocalCacheProvider({required this.store});

  final LocalStore store;

  @override
  String get name => 'Bộ nhớ máy (${store.backendName})';

  @override
  ProviderKind get kind => ProviderKind.cache;

  @override
  bool get isAvailable => store.isOpen;

  @override
  String get availabilityNote => isAvailable
      ? 'Dữ liệu đã tải trước đó trên thiết bị.'
      : 'Database cục bộ chưa mở.';

  @override
  Future<void> healthCheck() async {
    if (!isAvailable) throw ProviderException(name, availabilityNote);
    await store.stats();
  }

  @override
  Future<ProviderFetchResult> getLatestResults({
    required Region region,
    int days = 7,
  }) async {
    final draws = await store.loadDraws(region: region, limit: days);
    return _result(draws);
  }

  @override
  Future<ProviderFetchResult> getResultsByDate({
    required Region region,
    required DateTime date,
  }) async {
    final day = isoDate(date);
    final draws = await store.loadDraws(region: region, start: day, end: day);
    return _result(draws);
  }

  @override
  Future<ProviderFetchResult> getHistoricalResults({
    required Region region,
    required DateTime start,
    required DateTime end,
  }) async {
    final draws = await store.loadDraws(
      region: region,
      start: isoDate(start),
      end: isoDate(end),
      ascending: true,
    );
    return _result(draws);
  }

  ProviderFetchResult _result(List<DrawRecord> draws) => ProviderFetchResult(
    provider: name,
    kind: kind,
    draws: draws,
    fetchedAt: DateTime.now(),
    fromCache: true,
  );
}
