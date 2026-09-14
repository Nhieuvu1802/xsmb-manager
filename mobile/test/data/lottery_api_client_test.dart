import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xsmb_manager/src/core/config/api_config.dart';
import 'package:xsmb_manager/src/core/network/json_http_client.dart';
import 'package:xsmb_manager/src/data/models/draw_validation.dart';
import 'package:xsmb_manager/src/data/sources/remote/lottery_api_client.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

/// Payload thật chụp từ production Worker (2026-09-13).
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Client với một phản hồi cố định, ghi lại URL đã gọi.
LotteryApiClient clientWith(
  String body, {
  int status = 200,
  List<Uri>? requested,
  String baseUrl = 'https://xsmb-api.nhieuvu1802.workers.dev/v1',
}) {
  final client = MockClient((request) async {
    requested?.add(request.url);
    return http.Response.bytes(
      utf8.encode(body),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
  return LotteryApiClient(
    baseUrlLoader: () async => baseUrl,
    client: JsonHttpClient(client: client, maxAttempts: 1),
  );
}

void main() {
  group('Nhóm metadata của Worker API v1', () {
    test('/health đọc được dataset, regions và stations', () async {
      final requested = <Uri>[];
      final health = await clientWith(
        fixture('worker_health.json'),
        requested: requested,
      ).health();

      expect(requested.single.path, '/v1/health');
      expect(health.isOk, isTrue);
      expect(health.hasDataset, isTrue);
      expect(health.datasetDate, '2026-09-13');
      expect(health.datasetVersion, '1c88f61aba6c40a9');
      expect(health.environment, 'production');
      expect(health.providers, contains('cloudflare-worker'));
      expect(health.regions['xsmb']?.draws, 361);
      expect(health.regions['xsmb']?.prizesPerDraw, 27);
      expect(health.regions['xsmn']?.draws, 1147);
      expect(health.regions['xsmn']?.stations, hasLength(21));
      expect(health.regions['xsmn']?.stations, contains('Long An'));
    });

    test('/manifest khớp datasetVersion với /health', () async {
      final manifest = await clientWith(
        fixture('worker_manifest.json'),
      ).manifest();
      final health = await clientWith(fixture('worker_health.json')).health();

      expect(manifest.datasetVersion, health.datasetVersion);
      expect(manifest.xsmbLatestDate, health.datasetDate);
      expect(manifest.xsmnLatestDate, health.datasetDate);
      expect(manifest.servedBy, 'cloudflare-worker');
      expect(manifest.files.keys, contains('xsmb/latest.json'));
      expect(manifest.latestDate('xsmb'), '2026-09-13');
      expect(manifest.latestDate('xsmn'), '2026-09-13');
    });

    test('/config đọc cờ maintenance và github fallback', () async {
      final config = await clientWith(fixture('worker_config.json')).config();

      expect(config.maintenance, isFalse);
      expect(config.githubFallbackEnabled, isTrue);
      expect(config.apiVersion, 'v1');
      expect(config.minimumAppVersion, '2.0.0');
      expect(config.fallbackDataUrl, contains('public-data'));
    });

    test('JSON sai kiểu bị bỏ qua an toàn, không ném lỗi', () async {
      final health = await clientWith(
        '{"status":123,"regions":"khong-phai-map","providers":null}',
      ).health();

      expect(health.status, '123');
      expect(health.regions, isEmpty);
      expect(health.providers, isEmpty);
      expect(health.isOk, isFalse);
    });
  });

  group('XSMB — /v1/xsmb/latest', () {
    test('1 kỳ, đủ 27 giải và hợp lệ theo cơ cấu miền Bắc', () async {
      final requested = <Uri>[];
      final fetched = await clientWith(
        fixture('worker_xsmb_latest.json'),
        requested: requested,
      ).latest(region: Region.mienBac, days: 1);

      expect(requested.single.path, '/v1/xsmb/latest');
      expect(requested.single.queryParameters['days'], '1');

      final draws = fetched.value;
      expect(draws, hasLength(7));
      final draw = draws.first;
      expect(draw.region, Region.mienBac);
      expect(draw.date, '2026-09-13');
      expect(draw.station, 'Hội đồng XSKT miền Bắc');
      expect(draw.resolvedDrawCode, 'MB-20260913');
      expect(draw.results, hasLength(27));
      expect(draw.provider, LotteryApiClient.providerName);
      expect(fetched.latencyMs, greaterThanOrEqualTo(0));

      final validation = validateDrawRecord(draw);
      expect(validation.isValid, isTrue, reason: validation.errors.join(', '));
      expect(draw.results.firstWhere((r) => r.prize == 'Đặc biệt').value, '83799');
      expect(
        draw.results.where((r) => r.prize == 'Giải bảy').map((r) => r.lastTwo),
        <String>['21', '88', '40', '27'],
      );
    });

    test('latestDraw trả kỳ mới nhất hoặc null khi rỗng', () async {
      final draw = await clientWith(
        fixture('worker_xsmb_latest.json'),
      ).latestDraw(Region.mienBac);
      expect(draw?.date, '2026-09-13');

      final empty = await clientWith('{"success":true,"draws":[]}').latestDraw(
        Region.mienBac,
      );
      expect(empty, isNull);
    });
  });

  group('XSMN — nhiều đài trong cùng ngày', () {
    test('nhiều đài, mỗi đài đủ 18 giải và hợp lệ theo cơ cấu miền Nam', () async {
      final requested = <Uri>[];
      final fetched = await clientWith(
        fixture('worker_xsmn_latest.json'),
        requested: requested,
      ).latest(region: Region.mienNam, days: 1);

      expect(requested.single.path, '/v1/xsmn/latest');
      final draws = fetched.value;
      expect(draws.length, greaterThanOrEqualTo(1));
      for (final draw in draws) {
        expect(draw.region, Region.mienNam);
        expect(draw.date, '2026-09-13');
        expect(draw.results, hasLength(18));
        final validation = validateDrawRecord(draw);
        expect(
          validation.isValid,
          isTrue,
          reason: '${draw.station}: ${validation.errors.join(', ')}',
        );
        expect(draw.resolvedDrawCode, startsWith('MN-20260913-'));
      }
    });

    test('/v1/xsmn/{date} lọc đúng ngày và giữ nguyên đài', () async {
      final requested = <Uri>[];
      final fetched = await clientWith(
        fixture('worker_xsmn_by_date.json'),
        requested: requested,
      ).byDate(region: Region.mienNam, date: DateTime.utc(2026, 9, 13));

      expect(requested.single.path, '/v1/xsmn/2026-09-13');
      expect(fetched.value, hasLength(3));
      for (final draw in fetched.value) {
        expect(draw.results, hasLength(18));
        expect(validateDrawRecord(draw).isValid, isTrue);
      }
    });

    test('ngày không có dữ liệu trả danh sách rỗng, không crash', () async {
      final fetched = await clientWith(
        fixture('worker_xsmn_by_date.json'),
      ).byDate(region: Region.mienNam, date: DateTime.utc(2026, 9, 1));

      expect(fetched.value, isEmpty);
    });
  });

  group('History', () {
    test('gửi start/end và trả kỳ trong khoảng', () async {
      final requested = <Uri>[];
      final fetched = await clientWith(
        fixture('worker_xsmb_history.json'),
        requested: requested,
      ).history(
        region: Region.mienBac,
        start: DateTime.utc(2026, 9, 11),
        end: DateTime.utc(2026, 9, 13),
      );

      expect(requested.single.path, '/v1/xsmb/history');
      expect(requested.single.queryParameters['start'], '2026-09-11');
      expect(requested.single.queryParameters['end'], '2026-09-13');
      expect(fetched.value, hasLength(3));
      expect(fetched.value.first.date, '2026-09-13');
    });

    test('history hỗ trợ tham số days', () async {
      final requested = <Uri>[];
      await clientWith(
        fixture('worker_xsmb_history.json'),
        requested: requested,
      ).history(region: Region.mienBac, days: 3);

      expect(requested.single.queryParameters['days'], '3');
    });

    test('thiếu tham số khoảng ngày bị từ chối', () {
      expect(
        () => clientWith('{}').history(region: Region.mienBac),
        throwsA(isA<LotteryApiException>()),
      );
    });
  });

  group('Nhánh lỗi và fallback', () {
    test('404 báo isNotFound và không cần retry', () async {
      try {
        await clientWith('{"status":"error"}', status: 404).byDate(
          region: Region.mienBac,
          date: DateTime.utc(1990, 1, 1),
        );
        fail('Phải ném LotteryApiException');
      } on LotteryApiException catch (error) {
        expect(error.statusCode, 404);
        expect(error.isNotFound, isTrue);
        expect(error.isRetryable, isFalse);
        expect(error.endpoint, '/xsmb/1990-01-01');
      }
    });

    test('500 là lỗi tạm thời để chuỗi provider chuyển nguồn', () async {
      try {
        await clientWith('{"status":"error"}', status: 500).latest(
          region: Region.mienBac,
        );
        fail('Phải ném LotteryApiException');
      } on LotteryApiException catch (error) {
        expect(error.statusCode, 500);
        expect(error.isRetryable, isTrue);
      }
    });

    test('JSON không hợp lệ bị từ chối', () async {
      expect(
        () => clientWith('khong-phai-json').health(),
        throwsA(isA<LotteryApiException>()),
      );
    });

    test('mất internet (SocketException) là lỗi tạm thời', () async {
      final client = LotteryApiClient(
        baseUrlLoader: () async =>
            'https://xsmb-api.nhieuvu1802.workers.dev/v1',
        client: JsonHttpClient(
          client: MockClient(
            (_) async => throw const SocketException('mất kết nối'),
          ),
          maxAttempts: 1,
        ),
      );

      try {
        await client.latest(region: Region.mienBac);
        fail('Phải ném LotteryApiException');
      } on LotteryApiException catch (error) {
        expect(error.statusCode, isNull);
        expect(error.isRetryable, isTrue);
        expect(error.message, contains('Không kết nối được'));
      }
    });

    test('schema thiếu mảng draws bị từ chối', () async {
      expect(
        () => clientWith('{"region":"mb","foo":[]}').latest(
          region: Region.mienBac,
        ),
        throwsA(
          isA<LotteryApiException>().having(
            (error) => error.message,
            'message',
            contains('draws'),
          ),
        ),
      );
    });

    test('success=false bị từ chối', () async {
      expect(
        () => clientWith('{"success":false,"draws":[]}').latest(
          region: Region.mienBac,
        ),
        throwsA(isA<LotteryApiException>()),
      );
    });

    test('miền Trung chưa có dữ liệu', () {
      expect(
        () => clientWith('{}').latest(region: Region.mienTrung),
        throwsA(
          isA<LotteryApiException>().having(
            (error) => error.message,
            'message',
            contains('Miền Trung'),
          ),
        ),
      );
    });

    test('payload XSMB hỏi như XSMN trả rỗng, không trả sai miền', () async {
      final fetched = await clientWith(
        fixture('worker_xsmb_latest.json'),
      ).latest(region: Region.mienNam);

      expect(fetched.value, isEmpty);
    });

    test('client dùng đúng host/version của ApiConfig', () async {
      final requested = <Uri>[];
      await clientWith(
        fixture('worker_health.json'),
        requested: requested,
        baseUrl: ApiConfig.baseUrl,
      ).health();

      expect(requested.single.host, ApiConfig.workerHost);
      expect(requested.single.path, '/v1/health');
      expect(ApiConfig.baseUrl, endsWith('/v1'));
    });
  });
}
