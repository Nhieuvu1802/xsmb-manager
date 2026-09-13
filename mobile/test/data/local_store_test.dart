import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb_manager/src/data/local/web_local_store.dart';
import 'package:xsmb_manager/src/data/models/backtest.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/generated_run.dart';
import 'package:xsmb_manager/src/data/models/prediction.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/domain/generator/number_generator.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WebLocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = WebLocalStore(maxDrawsPerRegion: 10);
    await store.open();
  });

  test('ghi kỳ mới rồi cập nhật cùng ngày không sinh bản ghi trùng', () async {
    final first = await store.upsertDraws(<DrawRecord>[
      buildMbRecord('2026-09-01'),
    ]);
    expect(first.inserted, 1);
    expect(first.updated, 0);

    final second = await store.upsertDraws(<DrawRecord>[
      buildMbRecord('2026-09-01', seed: 99),
    ]);
    expect(second.inserted, 0);
    expect(second.updated, 1);
    expect(await store.countDraws(Region.mienBac), 1);
  });

  test('đọc theo khoảng ngày và thứ tự', () async {
    await store.upsertDraws(<DrawRecord>[
      buildMbRecord('2026-09-01'),
      buildMbRecord('2026-09-02'),
      buildMbRecord('2026-09-03'),
    ]);

    final descending = await store.loadDraws(region: Region.mienBac);
    expect(descending.map((item) => item.date).toList(), <String>[
      '2026-09-03',
      '2026-09-02',
      '2026-09-01',
    ]);

    final ascending = await store.loadDraws(
      region: Region.mienBac,
      ascending: true,
    );
    expect(ascending.first.date, '2026-09-01');

    final windowed = await store.loadDraws(
      region: Region.mienBac,
      start: '2026-09-02',
      end: '2026-09-03',
    );
    expect(windowed.length, 2);

    final limited = await store.loadDraws(region: Region.mienBac, limit: 1);
    expect(limited.single.date, '2026-09-03');
  });

  test('giữ đúng số kỳ tối đa của cửa sổ web', () async {
    for (var day = 1; day <= 12; day += 1) {
      await store.upsertDraws(<DrawRecord>[
        buildMbRecord('2026-09-${day.toString().padLeft(2, '0')}'),
      ]);
    }
    expect(await store.countDraws(Region.mienBac), 10);
    expect(await store.latestDrawDate(Region.mienBac), '2026-09-12');
  });

  test('không trộn vùng miền khi đọc', () async {
    await store.upsertDraws(<DrawRecord>[
      buildMbRecord('2026-09-01'),
      buildMnRecord('2026-09-01', 'An Giang'),
      buildMnRecord('2026-09-01', 'Bình Thuận'),
    ]);

    expect(await store.countDraws(Region.mienBac), 1);
    expect(await store.countDraws(Region.mienNam), 2);

    final stats = await store.stats();
    expect(stats.draws, 3);
    expect(stats.results, 27 + 18 + 18);
    expect(stats.perRegion['mb'], 1);
    expect(stats.perRegion['mn'], 2);
  });

  test('lịch sử đồng bộ và trạng thái nguồn được lưu', () async {
    await store.addSyncHistory(
      SyncHistoryRecord(
        region: Region.mienBac,
        startedAt: '2026-09-03T18:00:00',
        finishedAt: '2026-09-03T18:00:05',
        provider: 'API dự án (FastAPI)',
        status: SyncOutcome.success,
        inserted: 3,
      ),
    );
    final history = await store.recentSyncHistory();
    expect(history.single.status, SyncOutcome.success);
    expect(history.single.inserted, 3);

    await store.upsertProviderStatus(
      ProviderStatusRecord(
        provider: 'API dự án (FastAPI)',
        region: Region.mienBac,
        successes: 1,
        latencyMs: 120,
      ),
    );
    await store.upsertProviderStatus(
      ProviderStatusRecord(
        provider: 'API dự án (FastAPI)',
        region: Region.mienBac,
        successes: 2,
        failures: 1,
        latencyMs: 200,
      ),
    );
    final statuses = await store.providerStatuses(region: Region.mienBac);
    expect(statuses.length, 1);
    expect(statuses.single.successes, 2);
    expect(statuses.single.failures, 1);
  });

  test('lưu và đọc lại lượt xếp hạng', () async {
    final id = await store.savePredictionRun(
      PredictionRunRecord(
        region: Region.mienBac,
        createdAt: '2026-09-03T19:00:00',
        model: 'statistical-score-v1',
        windowDays: 90,
        targetDate: '2026-09-04',
        entries: const <PredictionEntryRecord>[
          PredictionEntryRecord(number: '27', score: 82.4, rank: 1),
          PredictionEntryRecord(number: '68', score: 79.1, rank: 2),
        ],
      ),
    );
    expect(id, greaterThan(0));

    final runs = await store.recentPredictionRuns(region: Region.mienBac);
    expect(runs.single.entries.length, 2);
    expect(runs.single.entries.first.number, '27');
    expect(runs.single.model, 'statistical-score-v1');
  });

  test('lưu kết quả backtest theo dòng mô hình/cửa sổ', () async {
    await store.saveBacktestResults(
      Region.mienBac,
      '2026-09-03T19:05:00',
      <BacktestWindowResult>[
        const BacktestWindowResult(
          model: 'statistical-score-v1',
          windowDays: 90,
          samples: 90,
          top1Hits: 10,
          top4Hits: 30,
          top10Hits: 70,
          top4BaselineHits: 25,
          top4RandomHits: 16,
          averageHitsAt4: 0.4,
          averageHitsAt10: 1.1,
        ),
      ],
    );
    final rows = await store.recentBacktestResults();
    expect(rows.single.top4HitRate, closeTo(30 / 90, 0.0001));
    expect(rows.single.edgeOverBaseline, greaterThan(0));
  });

  test('lưu và đọc lại lần sinh bộ số (giữ nguyên seed + cấu hình)', () async {
    final outcome = GeneratorEngine.generate(
      history: buildMbHistory(days: 60, seed: 4),
      strategy: GeneratorStrategy.weekday,
      settings: const GeneratorSettings(
        setCount: 3,
        numbersPerSet: 6,
        excluded: <int>[0, 99],
        specialMax: 12,
        sortOrder: GeneratorSortOrder.descending,
      ),
      targetDate: '2026-09-14',
      seed: 20260913,
    );

    final id = await store.saveGeneratedRun(
      GeneratedRunRecord.fromOutcome(
        region: Region.mienBac,
        outcome: outcome,
        targetDate: '2026-09-14',
        note: 'kiểm thử',
      ),
    );
    expect(id, greaterThan(0));

    final runs = await store.recentGeneratedRuns(region: Region.mienBac);
    expect(runs.length, 1);
    final run = runs.single;
    expect(run.setCount, 3);
    expect(run.seed, 20260913);
    expect(run.model, GeneratorEngine.modelName);
    expect(run.strategy, GeneratorStrategy.weekday);
    expect(run.settings.excluded, <int>[0, 99]);
    expect(run.settings.specialMax, 12);
    expect(run.settings.sortOrder.name, 'descending');
    expect(run.targetDate, '2026-09-14');
    expect(run.sets.first.numbers, outcome.sets.first.numbers);
    expect(
      run.sets.first.toDomain(run.seed).special,
      outcome.sets.first.special,
    );

    // Bản ghi đọc lại phải tái lập được đúng bộ số cũ khi chạy lại engine.
    final replay = GeneratorEngine.generate(
      history: buildMbHistory(days: 60, seed: 4),
      strategy: run.strategy,
      settings: run.settings,
      targetDate: run.targetDate,
      seed: run.seed,
    );
    expect(replay.sets.first.numbers, run.sets.first.numbers);
    expect(run.toOutcome().sets.first.numbers, run.sets.first.numbers);

    expect(await store.recentGeneratedRuns(region: Region.mienNam), isEmpty);
  });

  test('purgeBefore xoá đúng dữ liệu cũ', () async {
    await store.upsertDraws(<DrawRecord>[
      buildMbRecord('2026-08-01'),
      buildMbRecord('2026-09-01'),
    ]);
    final removed = await store.purgeBefore('2026-09-01');
    expect(removed, 1);
    expect(await store.countDraws(Region.mienBac), 1);
    expect(await store.latestDrawDate(Region.mienBac), '2026-09-01');
  });
}
