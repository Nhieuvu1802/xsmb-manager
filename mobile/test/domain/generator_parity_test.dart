import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/domain/generator/number_generator.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

/// Lịch sử tổng hợp dùng chung với backend Python
/// (`backend/tests/test_generator.py`, hàm `synthetic_history`).
List<LotteryDraw> syntheticHistory({int days = 40}) {
  final start = DateTime.utc(2026, 7, 1);
  return <LotteryDraw>[
    for (var index = 0; index < days; index += 1)
      buildMbDomainDraw(
        isoOf(start.add(Duration(days: index))),
        lastTwos: <String>[
          for (var slot = 0; slot < 27; slot += 1)
            ((index * 37 + slot * 11) % 100).toString().padLeft(2, '0'),
        ],
      ),
  ];
}

/// `(tên ca, chiến lược, cấu hình, seed, ngày mục tiêu, các bộ số mong đợi)`.
typedef GoldenCase = (
  String,
  GeneratorStrategy,
  GeneratorSettings,
  int,
  String?,
  List<String>,
);

const List<GeneratorSettings> _settings = <GeneratorSettings>[
  GeneratorSettings(
    numbersPerSet: 6,
    setCount: 3,
    sortOrder: GeneratorSortOrder.none,
  ),
  GeneratorSettings(numbersPerSet: 5, setCount: 2, specialMax: 12),
  GeneratorSettings(numbersPerSet: 4, setCount: 2),
  GeneratorSettings(numbersPerSet: 6, setCount: 2),
  GeneratorSettings(numbersPerSet: 6, setCount: 2),
  GeneratorSettings(
    numbersPerSet: 6,
    setCount: 2,
    uniqueWithinSet: false,
    sortOrder: GeneratorSortOrder.none,
  ),
];

void main() {
  final history = syntheticHistory();
  final cases = <GoldenCase>[
    (
      'hot',
      GeneratorStrategy.hot,
      _settings[0],
      20260913,
      null,
      <String>['94-64-73-33-35-93', '90-73-97-43-12-61', '16-17-92-73-97-11'],
    ),
    (
      'balanced',
      GeneratorStrategy.balanced,
      _settings[1],
      777,
      null,
      <String>['20-41-45-49-73|03', '11-25-42-65-83|01'],
    ),
    (
      'weekday',
      GeneratorStrategy.weekday,
      _settings[2],
      4242,
      '2026-08-12',
      <String>['13-40-51-91', '23-64-76-98'],
    ),
    (
      'uniform',
      GeneratorStrategy.uniform,
      _settings[3],
      99,
      null,
      <String>['24-27-50-76-81-95', '05-23-34-48-52-54'],
    ),
    (
      'cold',
      GeneratorStrategy.cold,
      _settings[4],
      31415,
      null,
      <String>['36-56-76-84-90-95', '03-27-73-76-78-91'],
    ),
    (
      'hot-không-hoàn-lại',
      GeneratorStrategy.hot,
      _settings[5],
      5,
      null,
      <String>['69-77-21-62-08-59', '72-45-90-23-78-74'],
    ),
  ];

  group('giá trị vàng khớp backend Python', () {
    for (final (name, strategy, settings, seed, targetDate, expected)
        in cases) {
      test(name, () {
        final outcome = GeneratorEngine.generate(
          history: history,
          strategy: strategy,
          settings: settings,
          targetDate: targetDate,
          seed: seed,
        );
        final produced = <String>[
          for (final set in outcome.sets)
            '${set.numbers.join('-')}'
                '${set.special == null ? '' : '|${set.special}'}',
        ];
        expect(produced, expected);
        expect(outcome.seed, seed);
        expect(
          outcome.sets.every((set) => set.seed == seed),
          isTrue,
          reason: 'mọi bộ phải ghi lại đúng seed để tái lập',
        );
      });
    }
  });
}
