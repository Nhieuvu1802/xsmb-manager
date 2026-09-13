import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';
import 'package:xsmb_manager/src/domain/statistics/number_statistics.dart';

import '../support/fixtures.dart';

void main() {
  DateTime day(int index) =>
      DateTime.utc(2026, 9, 1).add(Duration(days: index));

  group('thống kê 00–99', () {
    test('trả đủ 100 số với cửa sổ rolling 10/30/60/90', () {
      final snapshot = analyseNumbers(buildMbHistory(days: 90));

      expect(snapshot.metrics.length, 100);
      expect(snapshot.drawCount, 90);
      expect(snapshot.totalSlots, 90 * 27);
      final first = snapshot.metrics.first;
      expect(first.windowHits.keys.toSet(), <int>{10, 30, 60, 90});
      expect(first.number, '00');
    });

    test('số chỉ xuất hiện ở kỳ cuối có gap 0 và recency cao nhất', () {
      final history = <LotteryDraw>[
        for (var index = 0; index < 19; index += 1)
          buildMbDomainDraw(
            isoOf(day(index)),
            lastTwos: List<String>.filled(27, '99'),
          ),
        buildMbDomainDraw(
          isoOf(day(19)),
          lastTwos: <String>['00', ...List<String>.filled(26, '99')],
        ),
      ];

      final snapshot = analyseNumbers(history);
      final zero = snapshot.lookup('00')!;
      final ninetyNine = snapshot.lookup('99')!;

      expect(zero.drawHits, 1);
      expect(zero.occurrences, 1);
      expect(zero.gap, 0);
      expect(zero.recency, 1.0);
      expect(zero.windowRates[10], closeTo(0.1, 1e-9));
      expect(zero.windowRates[30], closeTo(1 / 20, 1e-9));
      expect(zero.momentum, closeTo(0.1, 1e-9));

      expect(ninetyNine.gap, 0);
      expect(ninetyNine.windowRates[10], 1.0);
      expect(ninetyNine.drawRate, 1.0);
      expect(ninetyNine.zScore, greaterThan(0));
    });

    test('các chỉ số đều nằm trong khoảng hợp lý', () {
      final snapshot = analyseNumbers(buildMbHistory(days: 120));

      for (final metrics in snapshot.metrics) {
        expect(metrics.ewma, inInclusiveRange(0, 1));
        expect(metrics.recency, inInclusiveRange(0, 1));
        expect(metrics.stability, inInclusiveRange(0, 1));
        expect(metrics.momentum, inInclusiveRange(-1, 1));
        expect(metrics.trendShort, inInclusiveRange(-1, 1));
        expect(metrics.trendMedium, inInclusiveRange(-1, 1));
        expect(metrics.trendLong, inInclusiveRange(-1, 1));
        expect(metrics.effectiveGap, greaterThanOrEqualTo(0));
      }
    });

    test('khoảng cách trung bình khớp khi số xuất hiện cách đều 5 kỳ', () {
      final history = <LotteryDraw>[
        for (var index = 0; index < 25; index += 1)
          buildMbDomainDraw(
            isoOf(day(index)),
            lastTwos: <String>[
              if (index % 5 == 0) '07' else '11',
              ...List<String>.filled(26, '11'),
            ],
          ),
      ];

      final metrics = analyseNumbers(history).lookup('07')!;

      expect(metrics.drawHits, 5);
      expect(metrics.averageGap, closeTo(5, 1e-9));
      expect(metrics.gapStdDev, closeTo(0, 1e-9));
      expect(metrics.stability, 1.0);
    });

    test('lọc theo đài hoạt động với dữ liệu XSMN nhiều đài', () {
      final draws = <LotteryDraw>[
        buildMnRecord('2026-09-10', 'An Giang').toDomain(),
        buildMnRecord('2026-09-10', 'Bình Thuận').toDomain(),
      ];

      expect(stationsOf(draws), <String>['An Giang', 'Bình Thuận']);
      expect(filterByStation(draws, 'An Giang').length, 1);
      expect(analyseNumbers(draws).totalSlots, 36);
    });

    test('dữ liệu rỗng không gây lỗi chia cho 0', () {
      final snapshot = analyseNumbers(const <LotteryDraw>[]);
      expect(snapshot.drawCount, 0);
      final metrics = snapshot.lookup('00')!;
      expect(metrics.drawRate, 0);
      expect(metrics.effectiveGap, 1);
      expect(metrics.averageGap, isNull);
    });
  });
}
