import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/domain/archive/lotto_archive.dart';
import 'package:xsmb_manager/src/domain/generator/number_generator.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';
import 'package:xsmb_manager/src/logic/statistics.dart';

import '../support/fixtures.dart';

void main() {
  final history = buildMbHistory(days: 120, seed: 17);

  group('cấu hình sinh số', () {
    test('cấu hình mặc định hợp lệ và đủ 100 số', () {
      expect(const GeneratorSettings().validate(), isEmpty);
      expect(const GeneratorSettings().availableCount, 100);
      expect(const GeneratorSettings().copyWith(min: 10).min, 10);
    });

    test('bắt được các cấu hình sai', () {
      expect(const GeneratorSettings(numbersPerSet: 0).validate(), isNotEmpty);
      expect(
        const GeneratorSettings(numbersPerSet: 101).validate(),
        isNotEmpty,
      );
      expect(const GeneratorSettings(setCount: 0).validate(), isNotEmpty);
      expect(const GeneratorSettings(setCount: 51).validate(), isNotEmpty);
      expect(const GeneratorSettings(min: -1).validate(), isNotEmpty);
      expect(const GeneratorSettings(min: 90, max: 80).validate(), isNotEmpty);
      expect(
        const GeneratorSettings(excluded: <int>[150]).validate(),
        isNotEmpty,
      );
      expect(const GeneratorSettings(specialMax: 0).validate(), isNotEmpty);
      expect(
        const GeneratorSettings(
          min: 0,
          max: 3,
          numbersPerSet: 2,
          setCount: 50,
        ).validate(),
        isNotEmpty,
      );
    });

    test('loại trừ số làm giảm kho chọn', () {
      const settings = GeneratorSettings(excluded: <int>[0, 1, 2]);
      expect(settings.availableCount, 97);
      expect(settings.copyWith(clearSpecialMax: true).specialMax, isNull);
      expect(
        const GeneratorSettings(
          specialMax: 12,
          seed: 5,
        ).copyWith(clearSeed: true).seed,
        isNull,
      );
      expect(GeneratorStrategy.fromName('hot'), GeneratorStrategy.hot);
      expect(GeneratorStrategy.fromName(''), GeneratorStrategy.balanced);
      expect(
        GeneratorSortOrder.fromName('descending'),
        GeneratorSortOrder.descending,
      );
      expect(GeneratorSortOrder.fromName('?'), GeneratorSortOrder.ascending);
    });
  });

  group('trọng số theo lịch sử', () {
    test('chiến lược hot ưu tiên số hay về', () {
      final weights = NumberWeights.fromHistory(
        history: history,
        strategy: GeneratorStrategy.hot,
      );
      final archive = LottoArchive.fromDraws(history);
      final table = archive.frequencyTable();
      expect(weights.totalWeight, greaterThan(0));
      expect(
        table[weights.topNumbers(1).single],
        archive.ranking(count: 1).single.count,
      );
      expect(weights.weightOf('00'), greaterThan(0));
    });

    test('chiến lược cold ưu tiên số lâu chưa về', () {
      final weights = NumberWeights.fromHistory(
        history: history,
        strategy: GeneratorStrategy.cold,
      );
      final archive = LottoArchive.fromDraws(history);
      final top = weights.topNumbers(1).single;
      final maxWeight = weights.weights.values.reduce((a, b) => a > b ? a : b);
      final maxGap = kAllNumbers
          .map(archive.drawsSinceLastSeen)
          .reduce(math.max);

      expect(weights.weightOf(top), maxWeight);
      expect(archive.drawsSinceLastSeen(top), maxGap);
    });

    test('chiến lược weekday đếm theo đúng thứ của ngày mục tiêu', () {
      final monday = buildMbDomainDraw(
        '2026-09-07',
        lastTwos: List<String>.filled(27, '07'),
      );
      final tuesday = buildMbDomainDraw(
        '2026-09-08',
        lastTwos: List<String>.filled(27, '08'),
      );
      final table = <LotteryDraw>[monday, tuesday];
      final weights = NumberWeights.fromHistory(
        history: table,
        strategy: GeneratorStrategy.weekday,
        targetDate: '2026-09-14',
      );

      expect(weights.targetWeekday, 'Thứ Hai');
      expect(weights.weightOf('07'), greaterThan(weights.weightOf('08')));
      expect(weights.source, contains('Thứ Hai'));

      final noData = NumberWeights.fromHistory(
        history: table,
        strategy: GeneratorStrategy.weekday,
        targetDate: '2026-09-10',
      );
      expect(noData.source, contains('Không có kỳ đúng thứ'));
    });

    test('chiến lược uniform cho mọi số trọng số bằng nhau', () {
      final weights = NumberWeights.fromHistory(
        history: history,
        strategy: GeneratorStrategy.uniform,
      );
      expect(weights.weights.length, 100);
      expect(weights.totalWeight, 100);
      expect(weights.weightOf('00'), weights.weightOf('99'));
    });

    test('chiến lược balanced dùng engine 00–99 và có nguồn giải thích', () {
      final weights = NumberWeights.fromHistory(
        history: history,
        strategy: GeneratorStrategy.balanced,
      );
      expect(weights.source, contains('30 kỳ'));
      expect(weights.weights.values.every((value) => value > 0), isTrue);
    });
  });

  group('engine sinh số', () {
    test('cùng seed cho ra cùng bộ số (tái lập được)', () {
      final first = GeneratorEngine.generate(
        history: history,
        strategy: GeneratorStrategy.balanced,
        settings: const GeneratorSettings(setCount: 3, numbersPerSet: 6),
        seed: 20260913,
      );
      final second = GeneratorEngine.generate(
        history: history,
        strategy: GeneratorStrategy.balanced,
        settings: const GeneratorSettings(setCount: 3, numbersPerSet: 6),
        seed: 20260913,
      );

      expect(first.sets.length, 3);
      expect(
        first.sets.map((set) => set.numbers.join('-')).toList(),
        second.sets.map((set) => set.numbers.join('-')).toList(),
      );
      expect(first.seed, 20260913);
      expect(first.sets.every((set) => set.seed == 20260913), isTrue);
      expect(first.summary, contains('seed 20260913'));
      expect(first.weights.source, isNotEmpty);
    });

    test('seed khác cho ra bộ số khác', () {
      final first = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(setCount: 2, numbersPerSet: 6),
        seed: 1,
      );
      final second = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(setCount: 2, numbersPerSet: 6),
        seed: 2,
      );
      expect(
        first.sets.first.numbers,
        isNot(equals(second.sets.first.numbers)),
      );
    });

    test('không trùng số trong bộ, không dùng số bị loại trừ', () {
      final outcome = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(
          numbersPerSet: 8,
          setCount: 5,
          excluded: <int>[0, 5, 42, 99],
        ),
        seed: 77,
      );

      for (final set in outcome.sets) {
        expect(set.numbers.length, 8);
        expect(set.numbers.toSet().length, 8);
        for (final number in set.numbers) {
          expect(number.length, 2);
          expect(<String>['00', '05', '42', '99'], isNot(contains(number)));
          expect(int.parse(number), inInclusiveRange(0, 99));
        }
      }
    });

    test('các bộ trong cùng lần sinh không trùng nhau', () {
      final outcome = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(setCount: 12, numbersPerSet: 6),
        seed: 4242,
      );
      final keys = outcome.sets.map((set) => set.numbers.join('-')).toSet();
      expect(keys.length, 12);
    });

    test('số đặc biệt nằm trong 1..specialMax và có thể tắt', () {
      final withSpecial = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(setCount: 6, specialMax: 12),
        seed: 88,
      );
      for (final set in withSpecial.sets) {
        final special = int.parse(set.special!);
        expect(special, inInclusiveRange(1, 12));
        expect(set.text, endsWith('| ${set.special}'));
      }

      final withoutSpecial = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(setCount: 2),
        seed: 88,
      );
      expect(withoutSpecial.sets.every((set) => set.special == null), isTrue);
    });

    test('sắp xếp, tổng và định dạng khớp với bộ số', () {
      final ascending = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(setCount: 3, numbersPerSet: 7),
        seed: 9,
      );
      for (final set in ascending.sets) {
        final values = [for (final n in set.numbers) int.parse(n)];
        expect(values, orderedEquals(values.toList()..sort()));
        expect(set.sum, values.fold(0, (a, b) => a + b));
        expect(set.display, set.numbers.join(' · '));
        expect(set.csv, set.numbers.join(','));
        expect(set.index, inInclusiveRange(1, 3));
      }

      final descending = GeneratorEngine.generate(
        history: history,
        settings: const GeneratorSettings(
          setCount: 1,
          numbersPerSet: 7,
          sortOrder: GeneratorSortOrder.descending,
        ),
        seed: 9,
      );
      final values = [
        for (final n in descending.sets.single.numbers) int.parse(n),
      ];
      expect(values, orderedEquals(values.toList()..sort((a, b) => b - a)));
    });

    test('không đủ tổ hợp thì ném ArgumentError', () {
      expect(
        () => GeneratorEngine.generate(
          history: history,
          settings: const GeneratorSettings(
            min: 0,
            max: 4,
            numbersPerSet: 2,
            setCount: 20,
          ),
        ),
        throwsArgumentError,
      );
      expect(GeneratorEngine.randomSeed(), inInclusiveRange(0, 1 << 30));
      expect(GeneratorEngine.modelName, isNotEmpty);
      expect(GeneratorOutcome.disclaimer, contains('không phải xác suất'));
    });

    test('chiến lược hot nghiêng hẳn về số hay về', () {
      var hits = 0;
      for (var run = 0; run < 6; run += 1) {
        final outcome = GeneratorEngine.generate(
          history: _flatHistory(number: '05'),
          strategy: GeneratorStrategy.hot,
          settings: const GeneratorSettings(
            min: 0,
            max: 9,
            numbersPerSet: 1,
            setCount: 50,
            uniqueAcrossSets: false,
          ),
          seed: 1000 + run,
        );
        hits += outcome.sets.where((set) => set.numbers.single == '05').length;
      }
      // Trọng số của '05' cao gấp ~136 lần các số còn lại trong kho 0–9.
      expect(hits, greaterThan(240));
    });

    test('chiến lược cold nghiêng hẳn về số lâu chưa về', () {
      var zero = 0;
      var fresh = 0;
      for (var run = 0; run < 6; run += 1) {
        final outcome = GeneratorEngine.generate(
          history: _flatHistory(number: '05'),
          strategy: GeneratorStrategy.cold,
          settings: const GeneratorSettings(
            min: 0,
            max: 9,
            numbersPerSet: 1,
            setCount: 50,
            uniqueAcrossSets: false,
          ),
          seed: 2000 + run,
        );
        for (final set in outcome.sets) {
          if (set.numbers.single == '00') zero += 1;
          if (set.numbers.single == '05') fresh += 1;
        }
      }
      expect(zero, greaterThan(fresh * 2));
    });
  });
}

/// 60 kỳ mà **mọi** giải đều về cùng một số `number`.
List<LotteryDraw> _flatHistory({required String number}) => <LotteryDraw>[
  for (var index = 0; index < 60; index += 1)
    buildMbDomainDraw(
      '2026-${index < 30 ? '06' : '07'}-'
      '${(index % 30 + 1).toString().padLeft(2, '0')}',
      lastTwos: List<String>.filled(27, number),
    ),
];
