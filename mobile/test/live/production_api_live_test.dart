/// Test tích hợp gọi API production **thật** bằng chính code của app.
///
/// Mặc định bị bỏ qua để CI không phụ thuộc mạng. Chạy khi cần xác nhận Worker
/// còn phục vụ đúng trước khi phát hành:
///
/// ```powershell
/// $env:XSM_LIVE_API='1'; flutter test test/live/production_api_live_test.dart
/// ```
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/core/config/api_config.dart';
import 'package:xsmb_manager/src/data/models/draw_validation.dart';
import 'package:xsmb_manager/src/data/sources/remote/lottery_api_client.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

/// Bật kiểm thử thật bằng biến môi trường `XSM_LIVE_API=1`.
final bool liveEnabled = Platform.environment['XSM_LIVE_API'] == '1';

const String skipReason =
    'Test live bị bỏ qua (đặt XSM_LIVE_API=1 để chạy với API production).';

void main() {
  final client = LotteryApiClient(baseUrlLoader: () async => ApiConfig.baseUrl);
  tearDownAll(client.close);

  group('API production (live) — ${ApiConfig.baseUrl}', () {
    test('/health báo ok và có dataset', () async {
      final health = await client.health();

      expect(health.isOk, isTrue, reason: 'status=${health.status}');
      expect(health.hasDataset, isTrue);
      expect(health.datasetDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(health.datasetVersion, isNotEmpty);
      expect(ApiConfig.host, ApiConfig.workerHost);
    }, skip: liveEnabled ? false : skipReason);

    test('/manifest khớp datasetVersion với /health', () async {
      final health = await client.health();
      final manifest = await client.manifest();

      expect(manifest.datasetVersion, health.datasetVersion);
      expect(manifest.latestDate('xsmb'), health.datasetDate);
      expect(manifest.latestDate('xsmn'), health.datasetDate);
    }, skip: liveEnabled ? false : skipReason);

    test('XSMB latest đủ 27 số và hợp lệ theo cơ cấu', () async {
      final fetched = await client.latest(region: Region.mienBac, days: 1);

      expect(fetched.value, isNotEmpty);
      final draw = fetched.value.first;
      expect(draw.region, Region.mienBac);
      expect(draw.results, hasLength(27));
      final validation = validateDrawRecord(draw);
      expect(validation.isValid, isTrue, reason: validation.errors.join(', '));
      expect(fetched.latencyMs, greaterThan(0));
    }, skip: liveEnabled ? false : skipReason);

    test('XSMN latest giữ đủ mọi đài trong ngày', () async {
      final fetched = await client.latest(region: Region.mienNam, days: 1);

      expect(fetched.value.length, greaterThanOrEqualTo(3));
      expect(
        fetched.value.map((draw) => draw.station).toSet().length,
        fetched.value.length,
        reason: 'mỗi đài chỉ xuất hiện một lần',
      );
      for (final draw in fetched.value) {
        expect(draw.results, hasLength(18));
        final validation = validateDrawRecord(draw);
        expect(
          validation.isValid,
          isTrue,
          reason: '${draw.station}: ${validation.errors.join(', ')}',
        );
      }
    }, skip: liveEnabled ? false : skipReason);

    test('endpoint theo ngày trả đúng kỳ của latest', () async {
      final latest = await client.latest(region: Region.mienBac, days: 1);
      final byDate = await client.byDate(
        region: Region.mienBac,
        date: DateTime.parse(latest.value.first.date),
      );

      expect(byDate.value, isNotEmpty);
      expect(byDate.value.first.date, latest.value.first.date);
      expect(
        byDate.value.first.results.length,
        latest.value.first.results.length,
      );
    }, skip: liveEnabled ? false : skipReason);

    test('ngày không tồn tại trả lỗi 404 đã chuẩn hoá', () async {
      try {
        await client.byDate(
          region: Region.mienBac,
          date: DateTime.utc(1990, 1, 1),
        );
        fail('Phải ném LotteryApiException');
      } on LotteryApiException catch (error) {
        expect(error.isNotFound, isTrue);
        expect(error.isRetryable, isFalse);
      }
    }, skip: liveEnabled ? false : skipReason);
  });
}
