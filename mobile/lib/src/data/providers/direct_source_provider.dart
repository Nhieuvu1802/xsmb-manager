/// Provider đọc trực tiếp trang kết quả công khai (không cần API key).
///
/// Chỉ dùng cho Android/iOS/desktop: trình duyệt bị CORS chặn khi tải HTML
/// khác origin, nên trên Web nguồn này tự tắt và app dùng backend.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/logging/app_logger.dart';
import '../../core/network/json_http_client.dart';
import '../../core/utils/lottery_dates.dart';
import '../../domain/lottery_domain.dart';
import '../models/draw_record.dart';
import '../models/sync_report.dart';
import 'lottery_data_provider.dart';
import 'xoso_html_parser.dart';

class DirectSourceProvider implements LotteryDataProvider {
  DirectSourceProvider({
    JsonHttpClient? client,
    AppLogger? logger,
    this.mbTemplate = 'https://xoso.com.vn/xsmb-{date}.html',
    this.mnTemplate = 'https://xoso.com.vn/xsmn-{date}.html',
    this.maxDaysPerRequest = 45,
  }) : _client = client ?? JsonHttpClient(),
       _logger = logger ?? appLogger;

  final JsonHttpClient _client;
  final AppLogger _logger;
  final String mbTemplate;
  final String mnTemplate;

  /// Giới hạn số ngày cho một lần gọi để tránh quá nhiều request.
  final int maxDaysPerRequest;

  @override
  String get name => 'Trang kết quả công khai (xoso.com.vn)';

  @override
  ProviderKind get kind => ProviderKind.direct;

  @override
  bool get isAvailable => !kIsWeb;

  @override
  String get availabilityNote => isAvailable
      ? 'Đọc HTML trực tiếp; không cần API key.'
      : 'Trình duyệt chặn CORS nên Web phải đi qua API của dự án.';

  Uri _uri(Region region, DateTime date) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
    final template = region == Region.mienBac ? mbTemplate : mnTemplate;
    return Uri.parse(template.replaceFirst('{date}', formatted));
  }

  @override
  Future<void> healthCheck() async {
    if (!isAvailable) throw ProviderException(name, availabilityNote);
    final response = await _client.getText(
      _uri(Region.mienBac, todayInVietnam()),
    );
    if (response.statusCode != 200) {
      throw ProviderException(name, 'Nguồn trả về mã ${response.statusCode}.');
    }
  }

  @override
  Future<ProviderFetchResult> getResultsByDate({
    required Region region,
    required DateTime date,
  }) async {
    if (!isAvailable) throw ProviderException(name, availabilityNote);
    final day = isoDate(date);
    final response = await _client.getText(_uri(region, date));
    if (response.statusCode != 200) {
      throw ProviderException(name, 'Mã ${response.statusCode} cho ngày $day.');
    }
    final draws = _parse(region, day, response.body);
    if (draws.isEmpty) {
      throw ProviderException(name, 'Không nhận diện được kết quả ngày $day.');
    }
    return ProviderFetchResult(
      provider: name,
      kind: kind,
      draws: draws,
      fetchedAt: DateTime.now(),
      latencyMs: response.latencyMs,
    );
  }

  @override
  Future<ProviderFetchResult> getLatestResults({
    required Region region,
    int days = 7,
  }) async {
    if (!isAvailable) throw ProviderException(name, availabilityNote);
    final today = todayInVietnam();
    final errors = <String>[];
    for (var offset = 0; offset <= days; offset += 1) {
      final date = today.subtract(Duration(days: offset));
      try {
        final result = await getResultsByDate(region: region, date: date);
        if (offset == 0) return result;
        return ProviderFetchResult(
          provider: name,
          kind: kind,
          draws: result.draws,
          fetchedAt: result.fetchedAt,
          latencyMs: result.latencyMs,
          warnings: <String>['Kỳ gần nhất có dữ liệu: ${isoDate(date)}'],
        );
      } on ProviderException catch (error) {
        errors.add(error.message);
      }
    }
    throw ProviderException(
      name,
      'Không có kỳ nào trong $days ngày gần nhất (${errors.length} lần thử).',
    );
  }

  @override
  Future<ProviderFetchResult> getHistoricalResults({
    required Region region,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isAvailable) throw ProviderException(name, availabilityNote);
    final days = isoDateRange(start, end);
    if (days.length > maxDaysPerRequest) {
      throw ProviderException(
        name,
        'Yêu cầu ${days.length} ngày vượt giới hạn $maxDaysPerRequest ngày.',
      );
    }
    final collected = <DrawRecord>[];
    final warnings = <String>[];
    var failures = 0;
    for (final day in days) {
      try {
        final result = await getResultsByDate(region: region, date: day);
        collected.addAll(result.draws);
      } on ProviderException catch (error) {
        failures += 1;
        if (warnings.length < 5) warnings.add(error.message);
      }
    }
    if (collected.isEmpty) {
      throw ProviderException(
        name,
        'Không lấy được kỳ nào trong ${days.length} ngày.',
        cause: warnings.join(' | '),
      );
    }
    if (failures > 0) {
      warnings.insert(0, '$failures/${days.length} ngày không lấy được.');
    }
    return ProviderFetchResult(
      provider: name,
      kind: kind,
      draws: collected,
      fetchedAt: DateTime.now(),
      warnings: warnings,
    );
  }

  List<DrawRecord> _parse(Region region, String date, String html) {
    final now = DateTime.now().toIso8601String();
    if (region == Region.mienBac) {
      final prizes = parseXsmbHtml(html);
      if (prizes.isEmpty) return const <DrawRecord>[];
      return <DrawRecord>[
        DrawRecord(
          region: Region.mienBac,
          date: date,
          station: DrawRecord.defaultStation(Region.mienBac),
          results: prizes,
          provider: name,
          collectedAt: now,
          verification: Verification.verified,
        ),
      ];
    }
    final stations = parseXsmnHtml(html);
    if (stations.isEmpty) {
      _logger.warning(
        'provider',
        '$name: không tách được bảng nhiều đài ngày $date',
      );
      return const <DrawRecord>[];
    }
    return <DrawRecord>[
      for (final entry in stations.entries)
        if (entry.value.isNotEmpty)
          DrawRecord(
            region: region,
            date: date,
            station: entry.key,
            results: entry.value,
            provider: name,
            collectedAt: now,
            verification: Verification.verified,
          ),
    ];
  }
}
