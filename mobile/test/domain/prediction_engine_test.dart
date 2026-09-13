import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';
import 'package:xsmb_manager/src/domain/scoring/prediction_engine.dart';
import 'package:xsmb_manager/src/domain/statistics/number_statistics.dart';

import '../support/fixtures.dart';

void main() {
  DateTime day(int index) =>
      DateTime.utc(2026, 9, 1).add(Duration(days: index));

  group('trọng số', () {
    test('chuẩn hoá về tổng bằng 1', () {
      final weights = FeatureWeights.balanced.normalized();
      expect(weights.total, closeTo(1.0, 1e-9));
    });

    test('phát hiện trọng số không hợp lệ', () {
      expect(const FeatureWeights().validate(), isEmpty);
      expect(const FeatureWeights(frequencyShort: -1).validate(), isNotEmpty);
      expect(
        const FeatureWeights(
          frequencyShort: 0,
          frequencyMedium: 0,
          frequencyLong: 0,
          recency: 0,
          gapScore: 0,
          trendScore: 0,
          momentumScore: 0,
          stabilityScore: 0,
          ewmaScore: 0,
        ).validate(),
        isNotEmpty,
      );
    });
  });

  group('xếp hạng 00–99', () {
    test('trả đủ 100 số, điểm 0–100 và thứ hạng liên tục', () {
      final snapshot = analyseNumbers(buildMbHistory(days: 90));
      final result = PredictionEngine.rank(snapshot: snapshot);

      expect(result.ranked.length, 100);
      expect(result.ranked.first.rank, 1);
      expect(result.ranked.last.rank, 100);
      for (var index = 0; index < result.ranked.length; index += 1) {
        final item = result.ranked[index];
        expect(item.score, inInclusiveRange(0, 100));
        if (index > 0) {
          expect(
            result.ranked[index - 1].score,
            greaterThanOrEqualTo(item.score),
          );
        }
      }
    });

    test('top 4 gồm 4 số khác nhau và có đủ chỉ số kèm theo', () {
      final snapshot = analyseNumbers(buildMbHistory(days: 60));
      final result = PredictionEngine.rank(snapshot: snapshot);

      final top4 = result.top4;
      expect(top4.length, 4);
      expect(top4.map((item) => item.number).toSet().length, 4);
      for (final item in top4) {
        expect(item.metrics.number, item.number);
        expect(item.topDrivers.length, 3);
        expect(item.features.keys, contains('recency'));
      }
    });

    test('số xuất hiện liên tục gần đây được xếp hạng cao', () {
      final history = <LotteryDraw>[
        for (var index = 0; index < 40; index += 1)
          buildMbDomainDraw(
            isoOf(day(index)),
            lastTwos: <String>[
              ...List<String>.filled(26, '99'),
              if (index >= 30) '07' else '11',
            ],
          ),
      ];

      final result = PredictionEngine.rank(snapshot: analyseNumbers(history));
      final rankOf07 = result.byNumber('07')!;

      expect(rankOf07.rank, lessThanOrEqualTo(3));
      expect(rankOf07.metrics.windowRates[10], closeTo(1.0, 1e-9));
    });

    test('cảnh báo không gọi điểm thống kê là xác suất trúng', () {
      expect(PredictionResult.disclaimer, contains('không phải xác'));
      expect(PredictionEngine.modelName, 'statistical-score-v1');
    });

    test('trọng số tuỳ biến làm thay đổi thứ hạng', () {
      final snapshot = analyseNumbers(buildMbHistory(days: 90));
      final balanced = PredictionEngine.rank(snapshot: snapshot);
      final recencyOnly = PredictionEngine.rank(
        snapshot: snapshot,
        weights: const FeatureWeights(
          frequencyShort: 0,
          frequencyMedium: 0,
          frequencyLong: 0,
          recency: 1,
          gapScore: 0,
          trendScore: 0,
          momentumScore: 0,
          stabilityScore: 0,
          ewmaScore: 0,
        ),
      );

      expect(
        recencyOnly.ranked.first.number,
        isNot(equals(balanced.ranked.first.number)),
      );
      expect(
        recencyOnly.ranked.first.metrics.recency,
        greaterThanOrEqualTo(recencyOnly.ranked.last.metrics.recency),
      );
    });
  });
}
