/// Provider dự phòng chỉ đọc dữ liệu JSON công khai trong repository GitHub.
///
/// GitHub không phải database hay backend chính. Provider này đọc snapshot
/// `public-data/{xsmb,xsmn}/history.json` (cửa sổ 365 ngày), file theo ngày và
/// `latest.json`; repository vẫn kiểm định đầy đủ trước khi ghi cache cục bộ.
library;

import '../../core/network/json_http_client.dart';
import '../../core/utils/lottery_dates.dart';
import '../../domain/lottery_domain.dart';
import '../models/draw_record.dart';
import '../models/sync_report.dart';
import 'lottery_data_provider.dart';

class GitHubJsonProvider implements LotteryDataProvider {
  GitHubJsonProvider({
    required Future<String> Function() baseUrlLoader,
    JsonHttpClient? client,
    this.enabled = true,
  }) : _baseUrlLoader = baseUrlLoader,
       _client = client ?? JsonHttpClient();

  final Future<String> Function() _baseUrlLoader;
  final JsonHttpClient _client;

  /// Bật/tắt nguồn này.
  ///
  /// STEP 8: repo `xsmb-manager` đang private nên
  /// `raw.githubusercontent.com/.../public-data/...` trả 404. Bản phát hành vì
  /// vậy tắt nguồn này (`ApiConfig.githubFallbackEnabled = false`) và chỉ dùng
  /// cache cục bộ + thử lại Worker; khi snapshot được công khai thì bật lại.
  final bool enabled;

  @override
  String get name => 'GitHub JSON dự phòng';

  @override
  ProviderKind get kind => ProviderKind.github;

  @override
  bool get isAvailable => enabled;

  @override
  String get availabilityNote => enabled
      ? 'Snapshot public chỉ đọc; không chứa database hoặc secret.'
      : 'Repo snapshot chưa công khai (raw trả 404) nên tạm tắt.';

  static String regionPath(Region region) =>
      region == Region.mienBac ? 'xsmb' : 'xsmn';

  void _ensureSupported(Region region) {
    if (region == Region.mienTrung) {
      throw ProviderException(name, '${region.label} chưa có JSON dự phòng.');
    }
  }

  Future<Uri> _uri(String path) async {
    final base = (await _baseUrlLoader()).trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/$path');
  }

  @override
  Future<void> healthCheck() async {
    try {
      final response = await _client.getJson(await _uri('status.json'));
      final body = response.body;
      if (body is! Map || body['status'] != 'ok') {
        throw ProviderException(name, 'status.json không báo trạng thái ok.');
      }
    } on ProviderException {
      rethrow;
    } on NetworkException catch (error) {
      throw ProviderException(name, error.message, cause: error);
    }
  }

  @override
  Future<ProviderFetchResult> getLatestResults({
    required Region region,
    int days = 7,
  }) async {
    _ensureSupported(region);
    final response = await _fetch('${regionPath(region)}/latest.json', region);
    final draws = _takeLatestDays(response.draws, days);
    return _result(response, draws);
  }

  @override
  Future<ProviderFetchResult> getResultsByDate({
    required Region region,
    required DateTime date,
  }) async {
    _ensureSupported(region);
    final dateText = isoDate(date);
    final response = await _fetchFirst(<String>[
      '${regionPath(region)}/$dateText.json',
      '${regionPath(region)}/history.json',
      '${regionPath(region)}/latest.json',
    ], region);
    return _result(
      response,
      response.draws
          .where((draw) => draw.date == dateText)
          .toList(growable: false),
    );
  }

  @override
  Future<ProviderFetchResult> getHistoricalResults({
    required Region region,
    required DateTime start,
    required DateTime end,
  }) async {
    _ensureSupported(region);
    // `history.json` là cửa sổ 365 ngày (mỗi kỳ giữ đài riêng của ngày đó) nên
    // lần bootstrap đầu tiên của app lấy được đủ dữ liệu thống kê/backtest.
    final response = await _fetchFirst(<String>[
      '${regionPath(region)}/history.json',
      '${regionPath(region)}/latest.json',
    ], region);
    final first = isoDate(start);
    final last = isoDate(end);
    return _result(
      response,
      response.draws
          .where((draw) => draw.date.compareTo(first) >= 0)
          .where((draw) => draw.date.compareTo(last) <= 0)
          .toList(growable: false),
    );
  }

  /// Tải file đầu tiên thành công trong [paths]; chỉ bỏ qua lỗi 404.
  Future<_GitHubPayload> _fetchFirst(List<String> paths, Region region) async {
    ProviderException? lastError;
    for (final path in paths) {
      try {
        return await _fetch(path, region);
      } on ProviderException catch (error) {
        lastError = error;
        final cause = error.cause;
        if (cause is! NetworkException || cause.statusCode != 404) rethrow;
      }
    }
    throw lastError!;
  }

  Future<_GitHubPayload> _fetch(String path, Region region) async {
    try {
      final response = await _client.getJson(await _uri(path));
      return _GitHubPayload(
        draws: _parseDraws(response.body, region),
        latencyMs: response.latencyMs,
      );
    } on ProviderException {
      rethrow;
    } on NetworkException catch (error) {
      throw ProviderException(name, error.message, cause: error);
    }
  }

  List<DrawRecord> _parseDraws(dynamic body, Region region) {
    if (body is Map && body['success'] == false) {
      throw ProviderException(name, 'Snapshot báo success=false.');
    }

    dynamic payload = body;
    if (body is Map) {
      final data = body['data'];
      payload = body['draws'] ?? body['results'] ?? body['items'];
      if (payload == null && data is Map) {
        payload = data['draws'] ?? data['results'] ?? data['items'];
      } else if (payload == null && data is List) {
        payload = data;
      }
    }
    if (payload is! List) {
      throw ProviderException(name, 'JSON backup thiếu mảng "draws".');
    }

    return <DrawRecord>[
      for (final item in payload.whereType<Map<String, dynamic>>())
        if (regionFromCode(item['region']?.toString()) == region)
          DrawRecord.fromJson(item, provider: name),
    ];
  }

  List<DrawRecord> _takeLatestDays(List<DrawRecord> draws, int days) {
    final sorted = List<DrawRecord>.of(draws)
      ..sort((a, b) => b.date.compareTo(a.date));
    final selectedDates = <String>[];
    for (final draw in sorted) {
      if (!selectedDates.contains(draw.date)) selectedDates.add(draw.date);
      if (selectedDates.length == days) break;
    }
    return sorted
        .where((draw) => selectedDates.contains(draw.date))
        .toList(growable: false);
  }

  ProviderFetchResult _result(_GitHubPayload payload, List<DrawRecord> draws) =>
      ProviderFetchResult(
        provider: name,
        kind: kind,
        draws: draws,
        fetchedAt: DateTime.now(),
        latencyMs: payload.latencyMs,
        warnings: const <String>[
          'Đang dùng snapshot GitHub; có thể chậm hơn API production.',
        ],
      );
}

class _GitHubPayload {
  const _GitHubPayload({required this.draws, required this.latencyMs});

  final List<DrawRecord> draws;
  final int latencyMs;
}
