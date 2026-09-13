import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xsmb_manager/src/core/network/json_http_client.dart';
import 'package:xsmb_manager/src/data/models/draw_validation.dart';
import 'package:xsmb_manager/src/data/providers/backend_api_provider.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

/// Payload thật lấy từ `/api/v1/xsmb/latest` và `/api/v1/xsmn/latest` của backend.
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

BackendApiProvider providerWith(
  String body, {
  String healthBody = '{"status":"ok","database":"ok"}',
  int status = 200,
}) {
  final client = MockClient((request) async {
    final isHealth = request.url.path == '/v1/health';
    final payload = isHealth ? healthBody : body;
    return http.Response.bytes(
      utf8.encode(payload),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
  return BackendApiProvider(
    baseUrlLoader: () async => 'https://api.test/v1',
    client: JsonHttpClient(client: client, maxAttempts: 1),
  );
}

void main() {
  group('BackendApiProvider đọc payload thật của API', () {
    test('XSMB: 2 kỳ, mỗi kỳ đủ 27 giải và hợp lệ', () async {
      final provider = providerWith(fixture('backend_xsmb_latest.json'));

      final result = await provider.getLatestResults(
        region: Region.mienBac,
        days: 2,
      );

      expect(result.draws.length, 2);
      expect(result.provider, 'VVN API');
      final first = result.draws.first;
      expect(first.region, Region.mienBac);
      expect(first.date, '2026-09-03');
      expect(first.station, 'Hội đồng XSKT miền Bắc');
      expect(first.results.length, 27);
      expect(first.resolvedDrawCode, 'MB-20260903');
      for (final draw in result.draws) {
        final outcome = validateDrawRecord(draw);
        expect(outcome.isValid, isTrue, reason: outcome.errors.join(', '));
      }
    });

    test('XSMN: tách riêng từng đài, mỗi đài 18 giải', () async {
      final provider = providerWith(fixture('backend_xsmn_latest.json'));

      final result = await provider.getResultsByDate(
        region: Region.mienNam,
        date: DateTime.utc(2026, 9, 3),
      );

      expect(result.draws.length, 3);
      expect(
        result.draws.map((item) => item.station).toSet().length,
        result.draws.length,
      );
      for (final draw in result.draws) {
        expect(draw.region, Region.mienNam);
        expect(draw.results.length, 18);
        final outcome = validateDrawRecord(draw);
        expect(outcome.isValid, isTrue, reason: outcome.errors.join(', '));
      }
    });

    test('schema sai bị từ chối bằng ProviderException', () async {
      final provider = providerWith('{"region":"mb","foo":[]}');

      expect(
        () => provider.getLatestResults(region: Region.mienBac),
        throwsA(isA<ProviderException>()),
      );
    });

    test('miền Trung chưa được hỗ trợ được báo rõ', () {
      final provider = providerWith('{"region":"mt","draws":[]}');

      expect(
        () => provider.getLatestResults(region: Region.mienTrung),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.message,
            'message',
            contains('Miền Trung'),
          ),
        ),
      );
    });

    test('healthCheck chấp nhận status ok và từ chối status khác', () async {
      await providerWith('{}').healthCheck();

      final broken = providerWith('{}', healthBody: '{"status":"degraded"}');
      expect(broken.healthCheck, throwsA(isA<ProviderException>()));
    });

    test('API base URL đã chứa /v1 nên không lặp prefix', () async {
      Uri? requested;
      final client = MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(
          utf8.encode(fixture('backend_xsmb_latest.json')),
          200,
        );
      });
      final provider = BackendApiProvider(
        baseUrlLoader: () async => 'https://api.vvn.freedev.app/v1/',
        client: JsonHttpClient(client: client, maxAttempts: 1),
      );

      await provider.getLatestResults(region: Region.mienBac, days: 1);

      expect(requested?.path, '/v1/xsmb/latest');
      expect(requested?.queryParameters['days'], '1');
    });

    test('đọc được cả định dạng API cũ (dòng phẳng)', () async {
      final legacy = jsonEncode(<Map<String, Object?>>[
        <String, Object?>{
          'draw_date': '2026-09-03',
          'prize': 'Đặc biệt',
          'position': 1,
          'full_number': '12345',
          'loto2': '45',
        },
        <String, Object?>{
          'draw_date': '2026-09-03',
          'prize': 'Giải bảy',
          'position': 1,
          'full_number': '07',
          'loto2': '07',
        },
      ]);
      final provider = providerWith(legacy);

      final result = await provider.getResultsByDate(
        region: Region.mienBac,
        date: DateTime.utc(2026, 9, 3),
      );

      expect(result.draws.length, 1);
      expect(result.draws.single.results.length, 2);
      expect(
        result.draws.single.results.map((item) => item.lastTwo).toSet(),
        <String>{'45', '07'},
      );
    });
  });
}
