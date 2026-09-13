import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/domain/generator/history_match.dart';
import 'package:xsmb_manager/src/domain/generator/number_generator.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

/// Lịch sử 40 kỳ trong đó kỳ nào cũng chỉ về đúng một số.
List<LotteryDraw> onlyNumber(
  String number, {
  int days = 40,
  String start = '2026-07-01',
}) {
  final from = DateTime.parse(start);
  return <LotteryDraw>[
    for (var index = 0; index < days; index += 1)
      buildMbDomainDraw(
        isoOf(from.add(Duration(days: index))),
        lastTwos: List<String>.filled(27, number),
      ),
  ];
}

void main() {
  group('đối chiếu một bộ số', () {
    test('bộ số không bao giờ về thì 0 kỳ trúng và thấp hơn kỳ vọng', () {
      final match = HistoryMatch.backcheck(
        sets: <GeneratedSet>[
          const GeneratedSet(
            index: 1,
            numbers: <String>['00', '01', '02'],
            sum: 3,
            seed: 7,
          ),
        ],
        history: onlyNumber('99'),
        window: 30,
      );
      final row = match.rows.single;

      expect(match.windowDraws, 30);
      expect(row.hitDraws, 0);
      expect(row.hitRate, 0);
      expect(row.totalOccurrences, 0);
      expect(row.matchesExpectation, isFalse);
      expect(row.verdict, contains('Thấp hơn'));
      expect(row.neverSeenNumbers, <String>['00', '01', '02']);
      expect(row.coldestNumber, '00');
      expect(row.expectedRate, closeTo(0.5597, 0.01));
      expect(match.verdict, contains('0/1'));
    });

    test('đếm đúng lượt về, kỳ trúng và ngày gần nhất', () {
      // Cứ 6 kỳ thì có đúng một kỳ về '00' ⇒ 5 kỳ trúng trong 30 kỳ.
      final from = DateTime.parse('2026-08-01');
      final history = <LotteryDraw>[
        for (var index = 0; index < 30; index += 1)
          buildMbDomainDraw(
            isoOf(from.add(Duration(days: index))),
            lastTwos: index % 6 == 0
                ? <String>['00', ...List<String>.filled(26, '99')]
                : List<String>.filled(27, '99'),
          ),
      ];
      final match = HistoryMatch.backcheck(
        sets: <GeneratedSet>[
          const GeneratedSet(
            index: 1,
            numbers: <String>['00'],
            sum: 0,
            seed: 7,
          ),
        ],
        history: history,
        window: 30,
      );
      final row = match.rows.single;

      expect(row.hitDraws, 5);
      expect(row.occurrences['00'], 5);
      expect(row.lastSeenDates['00'], '2026-08-25');
      expect(row.hitRate, closeTo(5 / 30, 1e-9));
      expect(row.hitRateInterval.first, lessThan(row.hitRate));
      expect(row.hitRateInterval.last, greaterThan(row.hitRate));
      expect(row.matchesExpectation, isTrue);
      expect(row.verdict, contains('Khớp kỳ vọng'));
      expect(SetBackcheck.formatRate(0.5), '50.0%');
      expect(SetBackcheck.formatRate(0.1234), '12.3%');
    });

    test('cửa sổ chỉ tính các kỳ gần nhất nhưng gan vẫn theo toàn kho', () {
      final from = DateTime.parse('2026-07-01');
      final history = <LotteryDraw>[
        for (var index = 0; index < 40; index += 1)
          buildMbDomainDraw(
            isoOf(from.add(Duration(days: index))),
            lastTwos: index < 5
                ? <String>['77', ...List<String>.filled(26, '99')]
                : List<String>.filled(27, '99'),
          ),
      ];
      final match = HistoryMatch.backcheck(
        sets: <GeneratedSet>[
          const GeneratedSet(
            index: 1,
            numbers: <String>['77'],
            sum: 0,
            seed: 7,
          ),
        ],
        history: history,
        window: 10,
      );
      final row = match.rows.single;

      expect(match.windowDraws, 10);
      expect(row.occurrences['77'], 0);
      expect(row.hitDraws, 0);
      expect(row.lastSeenDates['77'], '2026-07-05');
      expect(row.neverSeenNumbers, isEmpty);
      expect(match.archiveDrawCount, 40);
    });
  });

  group('đối chiếu cả lần sinh', () {
    test('10 số trên 120 kỳ có tỷ lệ trúng bám kỳ vọng lý thuyết', () {
      final history = buildMbHistory(days: 120, seed: 23);
      final outcome = GeneratorEngine.generate(
        history: history,
        strategy: GeneratorStrategy.balanced,
        settings: const GeneratorSettings(
          numbersPerSet: 10,
          setCount: 3,
          sortOrder: GeneratorSortOrder.ascending,
        ),
        seed: 20260913,
      );
      final match = HistoryMatch.backcheck(
        sets: outcome.sets,
        history: history,
      );

      expect(match.rows.length, 3);
      expect(match.windowDraws, 30);
      expect(match.isEmpty, isFalse);
      expect(match.expectedRate, closeTo(0.9423, 0.01));
      expect((match.averageHitRate - match.expectedRate).abs(), lessThan(0.2));
      expect(match.verdict, contains('/3 bộ nằm trong khoảng tin cậy 95%'));
    });

    test('không có bộ nào thì bảng đối chiếu rỗng', () {
      final match = HistoryMatch.backcheck(
        sets: const <GeneratedSet>[],
        history: buildMbHistory(days: 10),
      );
      expect(match.isEmpty, isTrue);
      expect(match.averageHitRate, 0);
      expect(match.verdict, contains('Chưa có bộ số'));
    });
  });
}
