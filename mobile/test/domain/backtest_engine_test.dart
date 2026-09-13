import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/data/models/backtest.dart';
import 'package:xsmb_manager/src/domain/backtest/backtest_engine.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

void main() {
  group('cấu hình backtest', () {
    test('phát hiện cấu hình sai', () {
      expect(const BacktestConfig().validate(), isEmpty);
      expect(const BacktestConfig(minTrain: 2).validate(), isNotEmpty);
      expect(
        const BacktestConfig(minTrain: 30, trainWindow: 10).validate(),
        isNotEmpty,
      );
      expect(
        const BacktestConfig(evaluationWindows: <int>[]).validate(),
        isNotEmpty,
      );
    });

    test('không đủ dữ liệu thì trả về ghi chú thay vì kết quả', () {
      final outcome = BacktestEngine.run(
        draws: buildMbHistory(days: 20),
        config: const BacktestConfig(minTrain: 30),
      );
      expect(outcome.isEmpty, isTrue);
      expect(outcome.notes, isNotEmpty);
      expect(outcome.verdict, contains('Chưa đủ'));
    });
  });

  group('walk-forward', () {
    final draws = buildMbHistory(days: 150);

    test('chỉ dùng dữ liệu trước ngày kiểm tra (không rò rỉ tương lai)', () {
      final outcome = BacktestEngine.run(
        draws: draws,
        config: const BacktestConfig(
          minTrain: 30,
          trainWindow: 120,
          evaluationWindows: <int>[0],
        ),
      );

      expect(outcome.daily.length, draws.length - 30);
      expect(outcome.daily.first.date, draws[30].date);
      expect(
        outcome.daily.map((item) => item.date).toSet().length,
        outcome.daily.length,
      );
      expect(outcome.notes.first, contains('chỉ dùng tối đa'));
    });

    test('mỗi cửa sổ có đủ 3 mô hình và số mẫu đúng', () {
      final outcome = BacktestEngine.run(
        draws: draws,
        config: const BacktestConfig(
          minTrain: 30,
          trainWindow: 120,
          evaluationWindows: <int>[30, 90, 0],
        ),
      );

      expect(outcome.results.length, 9);
      final allWindow = outcome.results
          .where((item) => item.windowDays == 0)
          .toList();
      expect(allWindow.length, 3);
      expect(allWindow.map((item) => item.model).toSet(), <String>{
        kScoreModel,
        kFrequencyBaseline,
        kRandomBaseline,
      });
      for (final row in allWindow) {
        expect(row.samples, draws.length - 30);
      }
      final window30 = outcome.results
          .where((item) => item.windowDays == 30)
          .toList();
      for (final row in window30) {
        expect(row.samples, 30);
      }
    });

    test('các chỉ số nằm trong khoảng hợp lệ', () {
      final outcome = BacktestEngine.run(
        draws: draws,
        config: const BacktestConfig(
          minTrain: 30,
          trainWindow: 120,
          evaluationWindows: <int>[30, 0],
        ),
      );

      for (final row in outcome.results) {
        expect(row.top1HitRate, inInclusiveRange(0, 1));
        expect(row.top4HitRate, inInclusiveRange(0, 1));
        expect(row.top10HitRate, inInclusiveRange(0, 1));
        expect(row.averageHitsAt4, inInclusiveRange(0, 4));
        expect(row.averageHitsAt10, inInclusiveRange(0, 10));
      }
    });

    test('chạy lại cho kết quả giống nhau (baseline ngẫu nhiên có seed)', () {
      const config = BacktestConfig(
        minTrain: 30,
        trainWindow: 120,
        evaluationWindows: <int>[30],
      );
      final first = BacktestEngine.run(draws: draws, config: config);
      final second = BacktestEngine.run(draws: draws, config: config);

      expect(
        first.results.map((item) => item.top4Hits).toList(),
        second.results.map((item) => item.top4Hits).toList(),
      );
      expect(
        first.results.map((item) => item.averageHitsAt10).toList(),
        second.results.map((item) => item.averageHitsAt10).toList(),
      );
    });

    test('kết luận nói rõ khi mô hình không vượt baseline', () {
      final outcome = BacktestEngine.run(
        draws: draws,
        config: const BacktestConfig(
          minTrain: 30,
          trainWindow: 120,
          evaluationWindows: <int>[30, 90, 0],
        ),
      );

      expect(outcome.verdict, isNotEmpty);
      if (outcome.beatsBaselineEverywhere) {
        expect(outcome.verdict, contains('vượt baseline'));
      } else {
        expect(
          outcome.verdict.contains('KHÔNG vượt') ||
              outcome.verdict.contains('chưa ổn định'),
          isTrue,
        );
      }
    });

    test(
      'BacktestRunRecord.beatsBaseline chỉ đúng khi mọi cửa sổ đều dương',
      () {
        const better = BacktestRunRecord(
          region: Region.mienBac,
          createdAt: '2026-09-10T19:00:00',
          results: <BacktestWindowResult>[
            BacktestWindowResult(
              model: kScoreModel,
              windowDays: 30,
              samples: 30,
              top1Hits: 3,
              top4Hits: 12,
              top10Hits: 20,
              top4BaselineHits: 10,
              top4RandomHits: 5,
              averageHitsAt4: 0.4,
              averageHitsAt10: 0.9,
            ),
          ],
        );
        const worse = BacktestRunRecord(
          region: Region.mienBac,
          createdAt: '2026-09-10T19:00:00',
          results: <BacktestWindowResult>[
            BacktestWindowResult(
              model: kScoreModel,
              windowDays: 30,
              samples: 30,
              top1Hits: 1,
              top4Hits: 5,
              top10Hits: 12,
              top4BaselineHits: 10,
              top4RandomHits: 5,
              averageHitsAt4: 0.2,
              averageHitsAt10: 0.5,
            ),
          ],
        );

        expect(better.beatsBaseline, isTrue);
        expect(worse.beatsBaseline, isFalse);
        expect(worse.bestModel!.edgeOverBaseline, lessThan(0));
      },
    );
  });
}
