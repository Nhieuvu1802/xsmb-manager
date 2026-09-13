/// Client typed cho API production v1 (Cloudflare Worker).
///
/// Đây là tầng duy nhất biết chi tiết hợp đồng JSON của Worker. Provider chỉ
/// cần gọi các hàm ở đây để nhận model đã kiểm tra kiểu dữ liệu:
///
/// ```text
/// Cloudflare Worker → LotteryApiClient (HTTP + JSON) → LotteryRepository
///                   → LotteryLocalDataSource (SQLite) → Flutter UI
/// ```
library;

import '../../../core/logging/app_logger.dart';
import '../../../core/network/json_http_client.dart';
import '../../../core/utils/lottery_dates.dart';
import '../../../domain/lottery_domain.dart';
import '../../models/api_models.dart';
import '../../models/draw_record.dart';

/// Lỗi đã chuẩn hoá của API production.
class LotteryApiException implements Exception {
  const LotteryApiException(
    this.message, {
    this.statusCode,
    this.endpoint,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final String? endpoint;
  final Object? cause;

  /// Lỗi tạm thời (nên thử lại hoặc chuyển nguồn kế tiếp).
  bool get isRetryable =>
      statusCode == null || statusCode! >= 500 || statusCode == 429;

  /// Endpoint không có dữ liệu cho ngày/khoảng đang hỏi.
  bool get isNotFound => statusCode == 404;

  @override
  String toString() =>
      'LotteryApiException($message'
      '${statusCode == null ? '' : ', status=$statusCode'}'
      '${endpoint == null ? '' : ', endpoint=$endpoint'})';
}

/// Kết quả thô kèm độ trễ để báo cáo trong màn hình Đồng bộ.
class ApiFetch<T> {
  const ApiFetch({
    required this.value,
    required this.latencyMs,
    required this.uri,
  });

  final T value;
  final int latencyMs;
  final Uri uri;
}

class LotteryApiClient {
  LotteryApiClient({
    required Future<String> Function() baseUrlLoader,
    JsonHttpClient? client,
    AppLogger? logger,
  }) : _baseUrlLoader = baseUrlLoader,
       _client = client ?? JsonHttpClient(),
       _logger = logger ?? appLogger;

  /// Tên hiển thị của nguồn (cũng là khoá lưu `provider_status`).
  static const String providerName = 'VVN API';

  /// Vùng miền Trung chưa có dữ liệu trong API hiện tại.
  static const Set<Region> supportedRegions = <Region>{
    Region.mienBac,
    Region.mienNam,
  };

  static String regionPath(Region region) =>
      region == Region.mienBac ? 'xsmb' : 'xsmn';

  final Future<String> Function() _baseUrlLoader;
  final JsonHttpClient _client;
  final AppLogger _logger;

  void close() => _client.close();

  // ---------------------------------------------------------------- HTTP lõi

  Future<String> _base() async {
    final value = (await _baseUrlLoader()).trim();
    final normalized = value.replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw const LotteryApiException('URL API chưa được cấu hình.');
    }
    return normalized;
  }

  Future<Uri> _uri(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('${await _base()}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<ApiFetch<dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = await _uri(path, query);
    try {
      final response = await _client.getJson(uri);
      return ApiFetch<dynamic>(
        value: response.body,
        latencyMs: response.latencyMs,
        uri: uri,
      );
    } on NetworkException catch (error) {
      _logger.warning('api', 'GET $uri → ${error.message}');
      throw LotteryApiException(
        error.message,
        statusCode: error.statusCode,
        endpoint: path,
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------- metadata

  /// `GET /v1/health`
  Future<ApiHealth> health() async {
    final payload = await _get('/health');
    return ApiHealth.fromJson(_asMap(payload.value, '/health'));
  }

  /// `GET /v1/config`
  Future<ApiRemoteConfig> config() async {
    final payload = await _get('/config');
    return ApiRemoteConfig.fromJson(_asMap(payload.value, '/config'));
  }

  /// `GET /v1/manifest`
  Future<ApiManifest> manifest() async {
    final payload = await _get('/manifest');
    return ApiManifest.fromJson(_asMap(payload.value, '/manifest'));
  }

  Map<String, dynamic> _asMap(dynamic body, String endpoint) {
    if (body is! Map) {
      throw LotteryApiException(
        'Schema không hợp lệ ở $endpoint: cần một JSON object.',
        endpoint: endpoint,
      );
    }
    return Map<String, dynamic>.from(body);
  }

  // ---------------------------------------------------------------- kết quả quay

  /// `GET /v1/{xsmb|xsmn}/latest?days=n`
  Future<ApiFetch<List<DrawRecord>>> latest({
    required Region region,
    int days = 1,
  }) async {
    _ensureSupported(region);
    final payload = await _get(
      '/${regionPath(region)}/latest',
      days > 0 ? <String, String>{'days': '$days'} : null,
    );
    return ApiFetch<List<DrawRecord>>(
      value: parseDraws(payload.value, region: region),
      latencyMs: payload.latencyMs,
      uri: payload.uri,
    );
  }

  /// Kỳ mới nhất của một vùng (tiện cho màn hình chính và kiểm tra sức khoẻ).
  Future<DrawRecord?> latestDraw(Region region) async {
    final fetched = await latest(region: region, days: 1);
    return fetched.value.isEmpty ? null : fetched.value.first;
  }

  /// `GET /v1/{xsmb|xsmn}/{yyyy-MM-dd}`
  Future<ApiFetch<List<DrawRecord>>> byDate({
    required Region region,
    required DateTime date,
  }) async {
    _ensureSupported(region);
    final iso = isoDate(date);
    final payload = await _get('/${regionPath(region)}/$iso');
    final draws = parseDraws(
      payload.value,
      region: region,
    ).where((draw) => draw.date == iso).toList(growable: false);
    return ApiFetch<List<DrawRecord>>(
      value: draws,
      latencyMs: payload.latencyMs,
      uri: payload.uri,
    );
  }

  /// `GET /v1/{xsmb|xsmn}/history?start=&end=` (hoặc `?days=`).
  Future<ApiFetch<List<DrawRecord>>> history({
    required Region region,
    DateTime? start,
    DateTime? end,
    int? days,
  }) async {
    _ensureSupported(region);
    if (start == null && end == null && (days == null || days <= 0)) {
      throw const LotteryApiException(
        'Cần tham số start/end (hoặc days) cho endpoint history.',
      );
    }
    final first = start == null ? null : isoDate(start);
    final last = end == null ? null : isoDate(end);
    final payload =
        await _get('/${regionPath(region)}/history', <String, String>{
          if (first != null) 'start': first,
          if (last != null) 'end': last,
          if (days != null && days > 0) 'days': '$days',
        });
    final draws = parseDraws(payload.value, region: region)
        .where((draw) => first == null || draw.date.compareTo(first) >= 0)
        .where((draw) => last == null || draw.date.compareTo(last) <= 0)
        .toList(growable: false);
    return ApiFetch<List<DrawRecord>>(
      value: draws,
      latencyMs: payload.latencyMs,
      uri: payload.uri,
    );
  }

  void _ensureSupported(Region region) {
    if (!supportedRegions.contains(region)) {
      throw LotteryApiException(
        '${region.label} chưa có dữ liệu trong API v1.',
      );
    }
  }

  /// Parse mảng `draws` của API v1; vẫn đọc được dòng phẳng của API cũ.
  ///
  /// Ném [LotteryApiException] khi thiếu mảng hoặc kiểu dữ liệu sai để chuỗi
  /// provider chuyển sang nguồn kế tiếp thay vì hiện dữ liệu rác.
  static List<DrawRecord> parseDraws(
    dynamic body, {
    required Region region,
    String? provider,
  }) {
    if (body is Map && body['success'] == false) {
      throw const LotteryApiException('API báo success=false.');
    }
    // API v1 trả object có `draws`; API cũ trả thẳng mảng dòng phẳng.
    final payload = body is Map
        ? (body['draws'] ?? body['results'] ?? body['items'])
        : body;
    if (payload is! List) {
      throw const LotteryApiException(
        'Schema không hợp lệ: thiếu mảng "draws".',
      );
    }
    if (payload.isEmpty) return const <DrawRecord>[];

    final first = payload.first;
    if (first is Map && first.containsKey('results')) {
      final draws = <DrawRecord>[
        for (final item in payload)
          if (item is Map<String, dynamic>)
            DrawRecord.fromJson(item, provider: provider ?? providerName),
      ];
      final filtered = draws
          .where((draw) => draw.region == region)
          .toList(growable: false);
      return List<DrawRecord>.of(filtered)
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return DrawRecord.fromLegacyRows(
      payload,
      region: region,
      provider: provider ?? providerName,
    );
  }
}
