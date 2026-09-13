import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xsmb_manager/src/core/network/json_http_client.dart';
import 'package:xsmb_manager/src/data/models/draw_validation.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/github_json_provider.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

GitHubJsonProvider providerWith(http.Client client) => GitHubJsonProvider(
  baseUrlLoader: () async => 'https://raw.example/repo/main/public-data/',
  client: JsonHttpClient(client: client, maxAttempts: 1),
);

void main() {
  test(
    'public-data trong repository là JSON hợp lệ và đủ cơ cấu giải',
    () async {
      for (final entry in <(Region, String)>[
        (Region.mienBac, 'xsmb'),
        (Region.mienNam, 'xsmn'),
      ]) {
        final bytes = File(
          '../public-data/${entry.$2}/latest.json',
        ).readAsBytesSync();
        final client = MockClient((_) async => http.Response.bytes(bytes, 200));

        final result = await providerWith(
          client,
        ).getLatestResults(region: entry.$1);

        expect(result.draws, isNotEmpty);
        for (final draw in result.draws) {
          final validation = validateDrawRecord(draw);
          expect(
            validation.isValid,
            isTrue,
            reason: '${draw.key}: ${validation.errors.join(', ')}',
          );
        }
      }

      final config =
          jsonDecode(File('../public-data/config.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(config['apiBaseUrl'], 'https://api.vvn.freedev.app/v1');
      expect(config['githubFallbackEnabled'], isTrue);
    },
  );

  test('đọc snapshot latest và giữ đủ các đài cùng ngày', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/repo/main/public-data/xsmn/latest.json');
      return http.Response.bytes(
        utf8.encode(fixture('backend_xsmn_latest.json')),
        200,
      );
    });

    final result = await providerWith(
      client,
    ).getLatestResults(region: Region.mienNam, days: 1);

    expect(result.kind, ProviderKind.github);
    expect(result.provider, 'GitHub JSON dự phòng');
    expect(result.draws.length, 3);
    expect(result.draws.map((draw) => draw.station).toSet().length, 3);
    for (final draw in result.draws) {
      expect(validateDrawRecord(draw).isValid, isTrue);
      expect(draw.provider, 'GitHub JSON dự phòng');
    }
  });

  test('file theo ngày không có thì đọc history.json', () async {
    final requestedPaths = <String>[];
    final client = MockClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path.endsWith('/2026-09-02.json')) {
        return http.Response('not found', 404);
      }
      return http.Response.bytes(
        utf8.encode(fixture('backend_xsmb_latest.json')),
        200,
      );
    });

    final result = await providerWith(
      client,
    ).getResultsByDate(region: Region.mienBac, date: DateTime.utc(2026, 9, 2));

    expect(requestedPaths, <String>[
      '/repo/main/public-data/xsmb/2026-09-02.json',
      '/repo/main/public-data/xsmb/history.json',
    ]);
    expect(result.draws.single.date, '2026-09-02');
  });

  test('history.json cũng thiếu thì mới rơi về latest.json', () async {
    final requestedPaths = <String>[];
    final client = MockClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path.endsWith('/latest.json')) {
        return http.Response.bytes(
          utf8.encode(fixture('backend_xsmb_latest.json')),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final result = await providerWith(client).getHistoricalResults(
      region: Region.mienBac,
      start: DateTime.utc(2026, 9, 1),
      end: DateTime.utc(2026, 9, 3),
    );

    expect(requestedPaths, <String>[
      '/repo/main/public-data/xsmb/history.json',
      '/repo/main/public-data/xsmb/latest.json',
    ]);
    expect(result.draws.map((draw) => draw.date), <String>[
      '2026-09-03',
      '2026-09-02',
    ]);
  });

  test('history.json thật phủ cửa sổ ~1 năm và đủ giải', () async {
    for (final entry in <(Region, String, int)>[
      (Region.mienBac, 'xsmb', 27),
      (Region.mienNam, 'xsmn', 18),
    ]) {
      final bytes = File(
        '../public-data/${entry.$2}/history.json',
      ).readAsBytesSync();
      final client = MockClient((_) async => http.Response.bytes(bytes, 200));

      final result = await providerWith(client).getHistoricalResults(
        region: entry.$1,
        start: DateTime.utc(2025, 9, 13),
        end: DateTime.utc(2026, 9, 12),
      );

      final dates = result.draws.map((draw) => draw.date).toSet();
      expect(
        dates.length,
        greaterThanOrEqualTo(350),
        reason: '${entry.$2}/history.json chưa đủ 1 năm',
      );
      expect(result.draws.length, greaterThanOrEqualTo(dates.length));
      for (final draw in result.draws.take(5)) {
        expect(draw.results.length, entry.$3);
        expect(validateDrawRecord(draw).isValid, isTrue);
      }
    }
  });

  test('health check yêu cầu status.json báo ok', () async {
    final healthy = MockClient(
      (_) async => http.Response('{"status":"ok"}', 200),
    );
    await providerWith(healthy).healthCheck();

    final broken = MockClient(
      (_) async => http.Response('{"status":"degraded"}', 200),
    );
    expect(providerWith(broken).healthCheck, throwsA(isA<ProviderException>()));
  });

  test('JSON không có draws bị từ chối', () {
    final client = MockClient((_) async => http.Response('{"data":{}}', 200));

    expect(
      () => providerWith(client).getLatestResults(region: Region.mienBac),
      throwsA(isA<ProviderException>()),
    );
  });
}
