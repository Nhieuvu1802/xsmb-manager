/// Provider gọi API production v1 (Cloudflare Worker).
///
/// Đây là nguồn chính: dữ liệu đã được kiểm định ở backend và đóng gói trong
/// Worker, hoạt động trên cả Android lẫn Web. Mọi chi tiết HTTP/JSON nằm trong
/// [LotteryApiClient]; provider chỉ chuyển lỗi API thành [ProviderException] để
/// chuỗi nguồn (`LotteryProviderChain`) thử nguồn kế tiếp.
library;

import '../../core/config/api_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/json_http_client.dart';
import '../../domain/lottery_domain.dart';
import '../models/draw_record.dart';
import '../models/sync_report.dart';
import '../sources/remote/lottery_api_client.dart';
import 'lottery_data_provider.dart';

class BackendApiProvider implements LotteryDataProvider {
  /// [apiClient] được ưu tiên dùng; nếu bỏ trống thì provider tự tạo client từ
  /// [baseUrlLoader] (mặc định [ApiConfig.baseUrl] — Worker production).
  BackendApiProvider({
    Future<String> Function()? baseUrlLoader,
    JsonHttpClient? client,
    AppLogger? logger,
    LotteryApiClient? apiClient,
  }) : _logger = logger ?? appLogger,
       _api =
           apiClient ??
           LotteryApiClient(
             baseUrlLoader: baseUrlLoader ?? () async => ApiConfig.baseUrl,
             client: client,
             logger: logger,
           );

  final LotteryApiClient _api;
  final AppLogger _logger;

  @override
  String get name => LotteryApiClient.providerName;

  @override
  ProviderKind get kind => ProviderKind.backend;

  @override
  bool get isAvailable => true;

  @override
  String get availabilityNote =>
      'Nguồn chính: ${ApiConfig.host}${ApiConfig.versionPath} (Cloudflare Worker)';

  /// Vùng miền Trung chưa có dữ liệu trong API v1.
  static const Set<Region> supportedRegions = LotteryApiClient.supportedRegions;

  static String regionPath(Region region) =>
      LotteryApiClient.regionPath(region);

  void _ensureSupported(Region region) {
    if (!supportedRegions.contains(region)) {
      throw ProviderException(name, '${region.label} chưa có trong backend.');
    }
  }

  /// Chuyển lỗi typed của client thành [ProviderException].
  Future<T> _run<T>(Future<T> Function() action, String context) async {
    try {
      return await action();
    } on ProviderException {
      rethrow;
    } on LotteryApiException catch (error) {
      _logger.warning('provider', '$name/$context: ${error.message}');
      throw ProviderException(name, error.message, cause: error);
    }
  }

  ProviderFetchResult _result(List<DrawRecord> draws, int latencyMs) =>
      ProviderFetchResult(
        provider: name,
        kind: kind,
        draws: draws,
        fetchedAt: DateTime.now(),
        latencyMs: latencyMs,
      );

  @override
  Future<void> healthCheck() => _run(() async {
    final health = await _api.health();
    if (!health.isOk) {
      throw ProviderException(name, 'API không trả về trạng thái ok.');
    }
  }, 'health');

  @override
  Future<ProviderFetchResult> getLatestResults({
    required Region region,
    int days = 7,
  }) async {
    _ensureSupported(region);
    return _run(() async {
      final fetched = await _api.latest(region: region, days: days);
      _logger.info(
        'provider',
        '$name: ${fetched.value.length} kỳ gần nhất (${region.code})',
      );
      return _result(fetched.value, fetched.latencyMs);
    }, 'latest');
  }

  @override
  Future<ProviderFetchResult> getResultsByDate({
    required Region region,
    required DateTime date,
  }) async {
    _ensureSupported(region);
    return _run(() async {
      final fetched = await _api.byDate(region: region, date: date);
      return _result(fetched.value, fetched.latencyMs);
    }, 'byDate');
  }

  @override
  Future<ProviderFetchResult> getHistoricalResults({
    required Region region,
    required DateTime start,
    required DateTime end,
  }) async {
    _ensureSupported(region);
    return _run(() async {
      final fetched = await _api.history(
        region: region,
        start: start,
        end: end,
      );
      return _result(fetched.value, fetched.latencyMs);
    }, 'history');
  }
}
