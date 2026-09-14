/// Kiểm thử luồng ngoại tuyến đầu–cuối (STEP 9–13).
///
/// Bộ test này dùng **fixture thật chụp từ Worker production** đi qua đúng các
/// lớp của app (MockClient → JsonHttpClient → LotteryApiClient → chuỗi provider
/// → repository → cache → model dùng chung), rồi tắt mạng để chắc chắn app vẫn
/// đọc được dữ liệu đã lưu.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb_manager/src/core/network/json_http_client.dart';
import 'package:xsmb_manager/src/data/local/web_local_store.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/lottery_models.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/backend_api_provider.dart';
import 'package:xsmb_manager/src/data/providers/local_cache_provider.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/data/providers/provider_chain.dart';
import 'package:xsmb_manager/src/data/repositories/lottery_repository.dart';
import 'package:xsmb_manager/src/data/sources/remote/lottery_api_client.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 2026-09-13 12:00 giờ Việt Nam — trùng ngày kỳ mới nhất của fixture.
  final clock = DateTime.utc(2026, 9, 13, 5);
  const baseUrl = 'https://xsmb-api.nhieuvu1802.workers.dev/v1';
  const host = 'xsmb-api.nhieuvu1802.workers.dev';

  late WebLocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = WebLocalStore();
    await store.open();
  });

  String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

  /// Worker giả: trả đúng fixture production; `offline = true` để mô phỏng mất mạng.
  LotteryApiClient mockApi({List<Uri>? requested, bool offline = false}) {
    final client = MockClient((request) async {
      requested?.add(request.url);
      if (offline) {
        throw http.ClientException('mất kết nối', request.url);
      }
      final path = request.url.path;
      final body = path.endsWith('/health')
          ? fixture('worker_health.json')
          : path.endsWith('/config')
          ? fixture('worker_config.json')
          : fixture('worker_xsmb_latest.json');
      return http.Response.bytes(
        utf8.encode(body),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    return LotteryApiClient(
      baseUrlLoader: () async => baseUrl,
      client: JsonHttpClient(client: client, maxAttempts: 1),
    );
  }

  LotteryRepository buildRepository(LotteryApiClient api) => LotteryRepository(
    store: store,
    chain: LotteryProviderChain(
      providers: <LotteryDataProvider>[
        BackendApiProvider(apiClient: api),
        LocalCacheProvider(store: store),
      ],
      store: store,
    ),
    api: api,
    apiBaseUrlLoader: () async => baseUrl,
    clock: () => clock,
  );

  Uri historyCall(List<Uri> requested) =>
      requested.firstWhere((uri) => uri.path.endsWith('/history'));

  group('Đồng bộ và metadata dataset', () {
    test('lần đồng bộ đầu tải cửa sổ bootstrap và ghi dataset_meta', () async {
      final requested = <Uri>[];
      final repository = buildRepository(mockApi(requested: requested));

      final report = await repository.sync(region: Region.mienBac);

      expect(report.status, SyncOutcome.success);
      expect(report.inserted, 7);
      expect(await store.latestDrawDate(Region.mienBac), '2026-09-13');

      // Cache trống → tải trọn cửa sổ bootstrap 365 ngày (≥ 1 năm kỳ).
      final call = historyCall(requested);
      expect(call.queryParameters['start'], '2025-09-14');
      expect(call.queryParameters['end'], '2026-09-13');

      final meta = await store.datasetMeta(Region.mienBac);
      expect(meta, isNotNull);
      expect(meta!.source, DataSourceKind.cloudflare);
      expect(meta.datasetVersion, '1c88f61aba6c40a9');
      expect(meta.datasetDate, '2026-09-13');
      expect(meta.apiHost, host);
      expect(meta.recordCount, 7);
      expect(meta.fetchedAt, report.finishedAt);
    });

    test('đồng bộ lần sau chỉ hỏi khoảng còn thiếu', () async {
      // Cache đã đủ sâu (không "gần như trống") thì đi nhánh chỉ tải phần thiếu.
      await store.upsertDraws(<DrawRecord>[
        buildMbRecord('2025-09-01'),
        buildMbRecord('2026-09-09'),
      ]);
      final requested = <Uri>[];
      final repository = buildRepository(mockApi(requested: requested));

      final report = await repository.sync(region: Region.mienBac);

      expect(report.status, SyncOutcome.success);
      expect(
        historyCall(requested).queryParameters['start'],
        '2026-09-10',
        reason: 'chỉ tải từ ngày kế tiếp kỳ cuối trong cache',
      );
      expect(await store.countDraws(Region.mienBac), 6);
    });
  });

  group('Chế độ ngoại tuyến', () {
    test('mất mạng: đọc được cache và systemStatus báo Offline', () async {
      await store.upsertDraws(<DrawRecord>[buildMbRecord('2026-09-10')]);
      final repository = buildRepository(mockApi(offline: true));

      final health = await repository.remoteHealth();
      expect(health.status, 'offline');

      final status = await repository.systemStatus(
        region: Region.mienBac,
        apiBaseUrl: baseUrl,
      );
      expect(status.apiOnline, isFalse);
      expect(status.apiStatusLabel, 'Offline');
      expect(status.source, DataSourceKind.cache);
      expect(status.sourceLabel, 'Bộ nhớ máy (offline)');
      expect(status.cacheDate, '2026-09-10');
      expect(status.cacheDraws, 1);
      expect(status.lastSyncLabel, 'Chưa đồng bộ');
      expect(status.apiHost, host);
      expect(status.summary, contains('ngoại tuyến'));
      expect(status.cacheBehindApi, isFalse);

      // UI vẫn có dữ liệu dù API chết.
      final draws = await repository.recentDomainDraws(
        region: Region.mienBac,
      );
      expect(draws.single.date, '2026-09-10');
      expect(draws.single.results.length, 27);
    });

    test('đồng bộ khi API chết vẫn rơi về cache, không báo thất bại', () async {
      await store.upsertDraws(<DrawRecord>[buildMbRecord('2026-09-10')]);
      final repository = buildRepository(mockApi(offline: true));

      final report = await repository.sync(
        region: Region.mienBac,
        force: true,
      );

      expect(report.status, isNot(SyncOutcome.failed));
      expect(report.provider, contains('Bộ nhớ máy'));
      expect(report.attemptedProviders.first, 'VVN API');
      expect(await store.countDraws(Region.mienBac), 1);
      // Nguồn phục vụ là cache → metadata phản ánh đúng nguồn đó.
      final meta = await store.datasetMeta(Region.mienBac);
      expect(meta?.source, DataSourceKind.cache);
      expect(meta?.datasetDate, '2026-09-10');
    });

    test('API trả lỗi và cache trống: app báo chưa có dữ liệu ngoại tuyến', () async {
      final repository = buildRepository(mockApi(offline: true));

      final status = await repository.systemStatus(
        region: Region.mienBac,
        apiBaseUrl: baseUrl,
      );

      expect(status.source, DataSourceKind.none);
      expect(status.hasCache, isFalse);
      expect(status.summary, contains('chưa có dữ liệu ngoại tuyến'));

      final report = await repository.sync(region: Region.mienBac);
      expect(report.status, SyncOutcome.failed);
      expect(await store.countDraws(Region.mienBac), 0);
    });
  });

  group('Metadata và cảnh báo endpoint', () {
    test('API online: systemStatus lấy dataset từ /health', () async {
      final repository = buildRepository(mockApi());

      final status = await repository.systemStatus(
        region: Region.mienBac,
        apiBaseUrl: baseUrl,
      );

      expect(status.apiOnline, isTrue);
      expect(status.source, DataSourceKind.cloudflare);
      expect(status.datasetDateLabel, '2026-09-13');
      expect(status.datasetVersionLabel, '1c88f61a…40a9');
      expect(status.appVersion, isNotEmpty);
    });

    test('/v1/config khai host khác → chỉ cảnh báo, không tự đổi endpoint', () async {
      final repository = buildRepository(mockApi());

      final status = await repository.systemStatus(
        region: Region.mienBac,
        apiBaseUrl: baseUrl,
      );

      expect(status.apiBaseUrl, baseUrl);
      expect(status.apiHost, host);
      expect(status.apiReportedBaseUrl, 'https://api.vvn.freedev.app/v1');
      expect(status.hasEndpointMismatch, isTrue);
    });

    test('API có kỳ mới hơn cache → nhắc cập nhật', () async {
      await store.upsertDraws(<DrawRecord>[buildMbRecord('2026-09-10')]);
      final repository = buildRepository(mockApi());

      final status = await repository.systemStatus(
        region: Region.mienBac,
        apiBaseUrl: baseUrl,
      );

      expect(status.cacheDate, '2026-09-10');
      expect(status.datasetDate, '2026-09-13');
      expect(status.cacheBehindApi, isTrue);
      expect(status.summary, contains('mới hơn cache'));
    });
  });

  group('Model dùng chung (STEP 5)', () {
    test('kỳ quay của Worker giữ nguyên hình dạng khi vào cache', () async {
      final api = mockApi();
      final fetched = await api.latest(region: Region.mienBac, days: 1);
      final LotteryResult record = fetched.value.first;

      expect(record.date, '2026-09-13');
      expect(record.station, 'Hội đồng XSKT miền Bắc');
      expect(record.results.length, 27);
      expect(record.resolvedDrawCode, 'MB-20260913');

      await store.upsertDraws(<DrawRecord>[record]);
      final cached = await store.loadDraws(region: Region.mienBac);
      final restored = cached.first;

      expect(restored.key, record.key);
      expect(restored.date, record.date);
      expect(restored.station, record.station);
      expect(restored.loto2, record.loto2);
      expect(restored.toJson(), record.toJson());
    });

    test('DatasetMeta roundtrip qua row và JSON', () {
      final meta = DatasetMeta(
        region: Region.mienNam,
        source: DataSourceKind.github,
        fetchedAt: '2026-09-12T19:05:00+07:00',
        datasetVersion: 'abc123',
        datasetDate: '2026-09-13',
        apiHost: 'xsmb-api.nhieuvu1802.workers.dev',
        recordCount: 4,
      );

      final fromRow = DatasetMeta.fromRow(meta.toRow());
      final fromJson = DatasetMeta.fromJson(meta.toJson());

      expect(fromRow.source, DataSourceKind.github);
      expect(fromRow.region, Region.mienNam);
      expect(fromRow.recordCount, 4);
      expect(fromRow.datasetDate, '2026-09-13');
      expect(fromJson.datasetVersion, 'abc123');
      expect(fromJson.fetchedAt, meta.fetchedAt);
      expect(DatasetMeta.empty(Region.mienBac).isEmpty, isTrue);
      expect(meta.copyWith(recordCount: 9).recordCount, 9);
      expect(meta.copyWith().datasetDate, '2026-09-13');
    });

    test('LotteryStation suy ra mã đài và trạm mặc định', () {
      final longAn = LotteryStation.fromJson(<String, dynamic>{
        'station': 'Long An',
        'region': 'mn',
        'code': 'long_an',
        'weekday': 4,
      });
      expect(longAn.id, 'long_an');
      expect(longAn.region, Region.mienNam);
      expect(longAn.weekday, 4);
      expect(longAn.isNorthernBoard, isFalse);

      final mb = LotteryStation.defaultFor(Region.mienBac);
      expect(mb.id, 'hội-đồng-xskt-miền-bắc');
      expect(mb.isNorthernBoard, isTrue);
      expect(mb.toJson()['region'], 'mb');
    });

    test('tên nguồn trong cache được quy về nguồn hiển thị', () {
      expect(dataSourceFromProviderName('VVN API'), DataSourceKind.cloudflare);
      expect(
        dataSourceFromProviderName('GitHub JSON dự phòng'),
        DataSourceKind.github,
      );
      expect(
        dataSourceFromProviderName('Bộ nhớ máy (SQLite (sqflite))'),
        DataSourceKind.cache,
      );
      expect(dataSourceFromProviderName('không có'), DataSourceKind.none);
      expect(dataSourceFromProviderName(null), DataSourceKind.none);
      expect(DataSourceKind.cache.isLive, isFalse);
      expect(DataSourceKind.cloudflare.isLive, isTrue);
    });

    test('web store lưu dataset_meta riêng cho từng vùng', () async {
      await store.saveDatasetMeta(
        DatasetMeta(
          region: Region.mienBac,
          source: DataSourceKind.cloudflare,
          fetchedAt: '2026-09-12T19:00:00+07:00',
          datasetVersion: 'v1',
          datasetDate: '2026-09-13',
          recordCount: 1,
        ),
      );
      await store.saveDatasetMeta(
        DatasetMeta(
          region: Region.mienNam,
          source: DataSourceKind.cache,
          fetchedAt: '2026-09-11T19:00:00+07:00',
          datasetVersion: 'v1',
          datasetDate: '2026-09-11',
          recordCount: 4,
        ),
      );

      expect((await store.datasetMeta(Region.mienBac))?.datasetDate, '2026-09-13');
      expect((await store.datasetMeta(Region.mienNam))?.recordCount, 4);
      expect(
        (await store.datasetMeta(Region.mienNam))?.source,
        DataSourceKind.cache,
      );

      // Ghi lại cùng vùng thì thay thế, không nhân bản.
      await store.saveDatasetMeta(
        DatasetMeta(
          region: Region.mienBac,
          source: DataSourceKind.cache,
          fetchedAt: '2026-09-13T19:00:00+07:00',
          datasetDate: '2026-09-13',
        ),
      );
      final updated = await store.datasetMeta(Region.mienBac);
      expect(updated?.datasetDate, '2026-09-13');
      expect(updated?.source, DataSourceKind.cache);
      final snapshot = await store.stats();
      expect(snapshot.draws, 0);
    });

    test('nhãn phiên bản và mốc thời gian dễ đọc', () {
      expect(shortVersion('c38bd612c87c942d'), 'c38bd612…942d');
      expect(shortVersion('abc'), 'abc');
      expect(shortVersion(null), '—');
      expect(formatIsoMoment('2026-09-12T12:05:00Z'), '12/09/2026 19:05');
      expect(
        formatIsoMoment('2026-09-12T12:05:00Z', withDate: false),
        '19:05',
      );
      expect(formatIsoMoment('không-phải-iso'), 'không-phải-iso');
    });
  });
}
