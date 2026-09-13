import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb_manager/src/data/local/web_local_store.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/local_cache_provider.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/data/providers/provider_chain.dart';
import 'package:xsmb_manager/src/data/repositories/lottery_repository.dart';
import 'package:xsmb_manager/src/data/sources/local/lottery_local_data_source.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WebLocalStore store;
  late LotteryLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = WebLocalStore(maxDrawsPerRegion: 30);
    local = LotteryLocalDataSource(store: store);
    await local.open();
  });

  test('open() mở đúng một lần và đọc được metadata cache', () async {
    expect(local.isOpen, isTrue);
    await local.open();
    expect(local.backendName, isNotEmpty);
    expect(local.location, isNotEmpty);
  });

  test('saveDraws ghi kỳ hợp lệ rồi đọc lại được', () async {
    final result = await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-09-12'),
    ]);

    expect(result.inserted, 1);
    expect(result.updated, 0);
    expect(result.rejected, 0);
    expect(result.errors, isEmpty);
    expect(await local.countDraws(Region.mienBac), 1);
    expect(await local.latestDate(Region.mienBac), '2026-09-12');
    expect(
      await local.hasDate(region: Region.mienBac, isoDate: '2026-09-12'),
      isTrue,
    );
    expect(
      await local.hasDate(region: Region.mienBac, isoDate: '2026-09-11'),
      isFalse,
    );
    expect((await local.stats()).results, 27);
  });

  test('saveDraws từ chối kỳ sai cơ cấu giải và không ghi gì', () async {
    final broken = DrawRecord(
      region: Region.mienBac,
      date: '2026-09-12',
      station: DrawRecord.defaultStation(Region.mienBac),
      results: buildPrizes(kMbPrizeLayout, seededLastTwos(1, 27))
          .take(10)
          .toList(growable: false),
      provider: 'test',
      collectedAt: '2026-09-12T19:00:00+07:00',
      verification: Verification.verified,
    );

    final result = await local.saveDraws(<DrawRecord>[broken]);

    expect(result.inserted, 0);
    expect(result.rejected, 1);
    expect(result.errors.single, contains('2026-09-12'));
    expect(await local.countDraws(Region.mienBac), 0);
  });

  test('saveDraws giữ kỳ hợp lệ và loại kỳ sai trong cùng một lô', () async {
    final broken = DrawRecord(
      region: Region.mienBac,
      date: '2026-09-11',
      station: DrawRecord.defaultStation(Region.mienBac),
      results: buildPrizes(kMbPrizeLayout, seededLastTwos(2, 27))
          .take(20)
          .toList(growable: false),
      provider: 'test',
      collectedAt: '2026-09-11T19:00:00+07:00',
      verification: Verification.verified,
    );

    final result = await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-09-12'),
      broken,
    ]);

    expect(result.inserted, 1);
    expect(result.rejected, 1);
    expect(await local.countDraws(Region.mienBac), 1);
    expect(await local.latestDate(Region.mienBac), '2026-09-12');
  });

  test('ghi nhiều đài XSMN cùng ngày mà không trộn vùng miền', () async {
    final result = await local.saveDraws(<DrawRecord>[
      buildMnRecord('2026-09-12', 'Long An'),
      buildMnRecord('2026-09-12', 'Bình Phước'),
      buildMnRecord('2026-09-12', 'TPHCM'),
    ]);

    expect(result.inserted, 3);
    expect(await local.countDraws(Region.mienNam), 3);
    expect(await local.countDraws(Region.mienBac), 0);
    expect((await local.stats()).results, 54);
  });

  test('loadLatestDays trả kỳ theo thứ tự thời gian và giữ đủ đài', () async {
    await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-09-10'),
      buildMbRecord('2026-09-11'),
      buildMbRecord('2026-09-12'),
      buildMnRecord('2026-09-12', 'Long An'),
      buildMnRecord('2026-09-12', 'TPHCM'),
    ]);

    final twoDays = await local.loadLatestDays(region: Region.mienBac, days: 2);
    expect(twoDays.map((draw) => draw.date).toList(), <String>[
      '2026-09-11',
      '2026-09-12',
    ]);

    final mnDay = await local.loadLatestDays(region: Region.mienNam, days: 1);
    expect(mnDay, hasLength(2));
    expect(mnDay.map((draw) => draw.station).toSet(), <String>{
      'Long An',
      'TPHCM',
    });
  });

  test('snapshot tổng hợp cho màn hình Trạng thái', () async {
    await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-09-12'),
      buildMnRecord('2026-09-12', 'Long An'),
    ]);
    await local.recordSyncHistory(
      SyncHistoryRecord(
        region: Region.mienBac,
        startedAt: '2026-09-13T09:37:00',
        finishedAt: '2026-09-13T09:37:05',
        provider: 'VVN API',
        status: SyncOutcome.success,
        inserted: 1,
      ),
    );

    final snapshot = await local.snapshot();

    expect(snapshot.hasData, isTrue);
    expect(snapshot.isOpen, isTrue);
    expect(snapshot.stats.draws, 2);
    expect(snapshot.stats.results, 27 + 18);
    expect(snapshot.newestDate, '2026-09-12');
    expect(snapshot.latestMbDate, '2026-09-12');
    expect(snapshot.latestMnDate, '2026-09-12');
    expect(snapshot.lastSync?.provider, 'VVN API');
    expect(snapshot.summary, contains('kỳ'));
  });

  test('purgeBefore xoá dữ liệu cũ nhưng giữ kỳ mới', () async {
    await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-08-01'),
      buildMbRecord('2026-09-12'),
    ]);

    expect(await local.purgeBefore('2026-09-01'), 1);
    expect(await local.countDraws(Region.mienBac), 1);
    expect(await local.latestDate(Region.mienBac), '2026-09-12');
  });

  test('repository vẫn phục vụ UI bằng cache khi không có nguồn mạng', () async {
    await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-09-12'),
      buildMnRecord('2026-09-12', 'Long An'),
    ]);

    final repository = LotteryRepository(
      store: store,
      chain: LotteryProviderChain(
        providers: <LotteryDataProvider>[LocalCacheProvider(store: store)],
        store: store,
      ),
    );

    final mb = await repository.recentDraws(region: Region.mienBac);
    final mn = await repository.recentDraws(region: Region.mienNam);
    expect(mb, hasLength(1));
    expect(mn, hasLength(1));
    expect(repository.api, isNull);

    final snapshot = await repository.cacheSnapshot();
    expect(snapshot.hasData, isTrue);
    expect(repository.cacheHasDate(region: Region.mienBac, isoDate: '2026-09-12'), completion(isTrue));

    final health = await repository.remoteHealth();
    expect(health.status, 'unknown');
    expect(health.hasDataset, isFalse);
    expect(await repository.remoteManifest(), isNull);
  });

  test('processor đọc cache lần hai không nhân đôi bản ghi', () async {
    await local.saveDraws(<DrawRecord>[buildMbRecord('2026-09-12', seed: 1)]);
    final second = await local.saveDraws(<DrawRecord>[
      buildMbRecord('2026-09-12', seed: 99),
    ]);

    expect(second.inserted, 0);
    expect(second.updated, 1);
    expect(await local.countDraws(Region.mienBac), 1);
  });
}

