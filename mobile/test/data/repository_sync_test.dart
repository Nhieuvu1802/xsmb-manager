import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb_manager/src/data/local/web_local_store.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/local_cache_provider.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/data/providers/provider_chain.dart';
import 'package:xsmb_manager/src/data/repositories/lottery_repository.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';
import '../support/scripted_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 2026-09-10 12:00 giờ Việt Nam.
  final fixedNow = DateTime.utc(2026, 9, 10, 5);

  late WebLocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = WebLocalStore();
    await store.open();
  });

  LotteryRepository buildRepository(List<LotteryDataProvider> providers) {
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        ...providers,
        LocalCacheProvider(store: store),
      ],
      store: store,
    );
    return LotteryRepository(store: store, chain: chain, clock: () => fixedNow);
  }

  test(
    'lần đồng bộ đầu tiên lấy khoảng ngày còn thiếu và ghi database',
    () async {
      final provider = ScriptedProvider(
        label: 'backend',
        kind: ProviderKind.backend,
        draws: <DrawRecord>[
          buildMbRecord('2026-09-09'),
          buildMbRecord('2026-09-10'),
        ],
      );
      final repository = buildRepository(<LotteryDataProvider>[provider]);

      final report = await repository.sync(region: Region.mienBac, days: 5);

      expect(report.status, SyncOutcome.success);
      expect(report.inserted, 2);
      expect(report.provider, 'backend');
      expect(await store.countDraws(Region.mienBac), 2);
      expect(await store.latestDrawDate(Region.mienBac), '2026-09-10');
    },
  );

  test(
    'lần đồng bộ sau không gọi lại nguồn khi dữ liệu đã mới nhất',
    () async {
      final provider = ScriptedProvider(
        label: 'backend',
        kind: ProviderKind.backend,
        draws: <DrawRecord>[buildMbRecord('2026-09-10')],
      );
      final repository = buildRepository(<LotteryDataProvider>[provider]);

      await repository.sync(region: Region.mienBac, days: 5);
      // Cache phải đủ sâu (không còn "gần như trống") thì mới bỏ qua gọi nguồn.
      await store.upsertDraws(<DrawRecord>[buildMbRecord('2025-09-11')]);
      final callsAfterFirst = provider.calls;
      final second = await repository.sync(region: Region.mienBac);

      expect(callsAfterFirst, 1);
      expect(provider.calls, callsAfterFirst);
      expect(second.status, SyncOutcome.upToDate);
    },
  );

  test('kỳ sai cơ cấu giải bị loại, không ghi vào database', () async {
    final broken = DrawRecord(
      region: Region.mienBac,
      date: '2026-09-10',
      station: DrawRecord.defaultStation(Region.mienBac),
      results: <PrizeRecord>[
        const PrizeRecord(prize: 'Đặc biệt', position: 1, value: '123'),
      ],
      provider: 'test',
      collectedAt: '2026-09-10T19:00:00+07:00',
    );
    final provider = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[broken, buildMbRecord('2026-09-09')],
    );
    final repository = buildRepository(<LotteryDataProvider>[provider]);

    final report = await repository.sync(region: Region.mienBac, days: 5);

    expect(report.status, SyncOutcome.partial);
    expect(report.rejected, 1);
    expect(report.inserted, 1);
    expect(await store.countDraws(Region.mienBac), 1);
  });

  test('đồng bộ lại (force) cập nhật chứ không nhân bản bản ghi', () async {
    final provider = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[buildMbRecord('2026-09-10')],
    );
    final repository = buildRepository(<LotteryDataProvider>[provider]);

    await repository.sync(region: Region.mienBac, days: 5);
    final forced = await repository.sync(region: Region.mienBac, force: true);

    expect(forced.updated, greaterThan(0));
    expect(await store.countDraws(Region.mienBac), 1);
  });

  test('cache gần như trống (< 31 ngày) thì lần đồng bộ sau tải bù cả cửa sổ', () async {
    final provider = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[buildMbRecord('2026-09-10')],
    );
    final repository = buildRepository(<LotteryDataProvider>[provider]);

    await repository.sync(region: Region.mienBac);
    provider.ranges.clear();
    final second = await repository.sync(region: Region.mienBac);

    expect(provider.calls, 2);
    expect(second.status, SyncOutcome.success);
    expect(isoOf(provider.ranges.single.start), '2025-09-11');
    expect(isoOf(provider.ranges.single.end), '2026-09-10');
  });

  test('cache đã đủ cửa sổ 1 năm thì chỉ tải phần còn thiếu', () async {
    await store.upsertDraws(<DrawRecord>[
      buildMbRecord('2025-09-11'),
      buildMbRecord('2026-09-10'),
    ]);
    final provider = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[buildMbRecord('2026-09-10')],
    );
    final repository = buildRepository(<LotteryDataProvider>[provider]);

    final report = await repository.sync(region: Region.mienBac);

    expect(provider.calls, 0);
    expect(provider.ranges, isEmpty);
    expect(report.status, SyncOutcome.upToDate);
  });

  test('khi nguồn lỗi, cache cục bộ vẫn giữ dữ liệu đã tải trước đó', () async {
    final working = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[buildMbRecord('2026-09-10')],
    );
    await buildRepository(<LotteryDataProvider>[
      working,
    ]).sync(region: Region.mienBac, days: 5);

    final failing = buildRepository(<LotteryDataProvider>[
      ScriptedProvider(
        label: 'backend',
        kind: ProviderKind.backend,
        failure: 'mất kết nối',
      ),
    ]);
    final report = await failing.sync(region: Region.mienBac, force: true);

    expect(report.status, isNot(SyncOutcome.failed));
    expect(await store.countDraws(Region.mienBac), 1);
    expect(report.attemptedProviders.first, 'backend');
  });

  test('lịch sử đồng bộ và trạng thái nguồn được ghi lại', () async {
    final provider = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[buildMbRecord('2026-09-10')],
    );
    final repository = buildRepository(<LotteryDataProvider>[provider]);

    await repository.sync(region: Region.mienBac, days: 5);

    final history = await repository.syncHistory();
    expect(history, isNotEmpty);
    expect(history.first.provider, 'backend');

    final statuses = await repository.providerStatuses(Region.mienBac);
    expect(
      statuses.any((item) => item.provider == 'backend' && item.successes > 0),
      isTrue,
    );
  });

  test('kỳ quay trả về UI ở dạng domain model', () async {
    final provider = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[
        buildMbRecord('2026-09-09'),
        buildMbRecord('2026-09-10'),
      ],
    );
    final repository = buildRepository(<LotteryDataProvider>[provider]);
    await repository.sync(region: Region.mienBac, days: 5);

    final draws = await repository.recentDomainDraws(
      region: Region.mienBac,
      limit: 10,
    );

    expect(draws.length, 2);
    expect(draws.first.date, '2026-09-10');
    expect(draws.first.results.length, 27);
  });
}
