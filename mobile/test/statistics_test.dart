/// Kiểm thử đối chiếu (parity) giữa bản Dart và bản web Next.js.
///
/// Vector được sinh từ chính `frontend/lib/statistics.ts` bằng
/// `frontend/tests/_vectors.test.ts` và lưu tại
/// `test/fixtures/parity_vectors.json`. Nhờ vậy hai bản dùng cùng công thức.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/data/sample_data.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';
import 'package:xsmb_manager/src/logic/statistics.dart';

late final Map<String, Object?> _v;

String _fixed(double? value, [int digits = 10]) =>
    value == null ? 'null' : value.toStringAsFixed(digits);

String _statLine(NumberStat stat) => [
  stat.number,
  stat.count,
  stat.drawHits,
  _fixed(stat.rate),
  _fixed(stat.drawRate),
  stat.gap?.toString() ?? 'null',
  _fixed(stat.averageGap),
  _fixed(stat.zScore),
].join('|');

String _drawLine(LotteryDraw draw) => [
  draw.id,
  draw.drawCode,
  draw.lotteryType.code,
  draw.date,
  draw.drawnAt,
  draw.region.label,
  draw.station,
  draw.source,
  draw.collectedAt,
  draw.verification.code,
].join('|');

String _resultLine(LotteryDraw draw) => draw.results
    .map((result) => '${result.prize}|${result.position}|${result.value}')
    .join(',');

String _drawEntry(LotteryDraw draw) =>
    '${_drawLine(draw)}#${_resultLine(draw)}';

/// Bỏ `collectedAt` (thời điểm chạy) để so sánh được giữa hai lần chạy.
String _stripTimestamps(String joined) => joined
    .split(';;')
    .map((entry) {
      final parts = entry.split('#');
      final fields = parts[0].split('|')..removeAt(8);
      return '${fields.join('|')}#${parts[1]}';
    })
    .join(';;');

void _expectText(String key, String actual) {
  final expected = _v[key];
  expect(expected, isA<String>(), reason: 'Thiếu vector $key');
  expect(actual, expected, reason: key);
}

void _expectDraws(String key, List<LotteryDraw> draws) {
  final expected = _v[key];
  expect(expected, isA<String>(), reason: 'Thiếu vector $key');
  expect(
    _stripTimestamps(draws.map(_drawEntry).join(';;')),
    _stripTimestamps(expected! as String),
    reason: key,
  );
}

void _expectNumber(String key, num actual) {
  final expected = _v[key];
  expect(expected, isA<num>(), reason: 'Thiếu vector $key');
  if (expected is int) {
    expect(actual, equals(expected), reason: key);
  } else {
    expect(actual, closeTo(expected as num, 1e-9), reason: key);
  }
}

Map<String, Object?> _loadVectors() {
  const relativePath = 'test/fixtures/parity_vectors.json';
  final file = File(relativePath);
  if (!file.existsSync()) {
    throw StateError(
      'Không tìm thấy $relativePath. Hãy sinh lại vector bằng '
      '`cd frontend && npx vitest run tests/_vectors.test.ts`.',
    );
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  _v = _loadVectors();
  final draws = kSampleDraws;

  group('dữ liệu mẫu', () {
    test('khớp bản web', () {
      _expectNumber('sampleDrawsLength', draws.length);
      _expectNumber('firstDrawResultCount', draws.first.results.length);
      _expectText('firstDrawMeta', _drawLine(draws[0]));
      _expectText('firstDrawResults', _resultLine(draws[0]));
      _expectText('secondDrawMeta', _drawLine(draws[1]));
      _expectText('secondDrawResults', _resultLine(draws[1]));
      _expectText('lastDrawMeta', _drawLine(draws.last));
    });
  });

  group('thống kê 100 số', () {
    test('khớp bản web ở 30 kỳ và 365 kỳ', () {
      final stats30 = calculateNumberStats(draws.sublist(0, 30));
      final stats365 = calculateNumberStats(draws);

      _expectNumber(
        'stats30TotalSlots',
        stats30.fold<int>(0, (sum, item) => sum + item.count),
      );
      _expectText(
        'stats30Flagship',
        ['00', '01', '42', '99']
            .map(
              (number) => _statLine(
                stats30.firstWhere((item) => item.number == number),
              ),
            )
            .join(';'),
      );
      _expectNumber('stats30ChiSquare', chiSquareUniform(stats30));

      _expectNumber(
        'stats365TotalSlots',
        stats365.fold<int>(0, (sum, item) => sum + item.count),
      );
      _expectText(
        'stats365Flagship',
        ['00', '07', '42', '99']
            .map(
              (number) => _statLine(
                stats365.firstWhere((item) => item.number == number),
              ),
            )
            .join(';'),
      );
      _expectNumber('stats365ChiSquare', chiSquareUniform(stats365));
      _expectText(
        'stats365Counts',
        stats365.map((item) => item.count).join(','),
      );
      _expectText(
        'stats365DrawHits',
        stats365.map((item) => item.drawHits).join(','),
      );
      expect(kAllNumbers.length, 100);
      expect(kAllNumbers.first, '00');
      expect(kAllNumbers.last, '99');
    });
  });

  group('cấu trúc dãy số', () {
    test('khớp bản web', () {
      final structure = calculateStructure(draws);
      _expectText(
        'structureDigitCounts',
        structure.digitCounts.map((item) => item.count).join(','),
      );
      _expectText(
        'structureHeads',
        structure.heads.map((item) => item.count).join(','),
      );
      _expectText(
        'structureTails',
        structure.tails.map((item) => item.count).join(','),
      );
      _expectText(
        'structureSums',
        structure.sums.map((item) => item.count).join(','),
      );
      _expectText(
        'structureParity',
        '${structure.evenCount}|${structure.oddCount}',
      );
      _expectText(
        'structureRanges',
        structure.ranges.map((item) => item.count).join(','),
      );
      _expectText(
        'structureSequences',
        structure.sequences
            .map((item) => '${item.sequence}:${item.count}')
            .join(';'),
      );
    });
  });

  group('cặp số, ngày trong tuần và xu hướng', () {
    test('khớp bản web', () {
      final pairs = calculatePairStats(draws);
      _expectNumber('pairsLength', pairs.length);
      _expectText(
        'pairsTop10',
        pairs.take(10).map((item) => '${item.pair}:${item.count}').join(';'),
      );

      _expectText(
        'dayOfWeek',
        calculateDayOfWeekStats(draws)
            .map(
              (item) =>
                  '${item.day}|${item.dayIndex}|${item.count}|${item.drawHits}',
            )
            .join(';'),
      );

      final tracked = (_v['trendTracked']! as String).split(',');
      final trend = buildTrend(draws, tracked);
      _expectNumber('trendLength', trend.length);
      _expectText('trendTracked', tracked.join(','));
      _expectText(
        'trendLast30',
        trend.map((item) => '${item.date}|${item.hits}').join(';'),
      );
    });
  });

  group('công thức xác suất', () {
    test('khớp bản web', () {
      _expectNumber('probabilitySet5', calculateSetProbability(5, slots: 27));
      _expectNumber('probabilitySet7Default', calculateSetProbability(7));
      _expectNumber('probabilitySet0', calculateSetProbability(0));
      _expectNumber(
        'probabilitySet200',
        calculateSetProbability(200, slots: 27),
      );
      _expectText(
        'digitProbability',
        [
          1,
          2,
          4,
          6,
          12,
        ].map((digits) => _fixed(exactDigitProbability(digits))).join(';'),
      );
      _expectText(
        'digitProbability13',
        exactDigitProbability(13) == null ? 'null' : 'unexpected',
      );
      _expectText(
        'combos',
        [
          combinations(24, 4),
          combinations(6, 3),
          combinations(0, 0),
          combinations(5, 9),
        ].join(';'),
      );
      _expectNumber('expectedValue', expectedValue(10, 100, 0.02));
      _expectText(
        'wilson25of100',
        wilsonInterval(25, 100).map((value) => _fixed(value, 12)).join(';'),
      );
      _expectText(
        'wilson0of0',
        wilsonInterval(0, 0).map((value) => _fixed(value, 12)).join(';'),
      );
      _expectText(
        'wilson3of7',
        wilsonInterval(3, 7).map((value) => _fixed(value, 12)).join(';'),
      );
      _expectNumber(
        'monteCarlo100k',
        monteCarloAtLeastOne(5, 27, simulations: 100000, seed: 2409),
      );
      _expectNumber(
        'monteCarlo10k',
        monteCarloAtLeastOne(2, 27, simulations: 10000, seed: 2409),
      );
      _expectText(
        'lastTwoDigits',
        ['007', '07', '7', '12345', '00'].map(lastTwoDigits).join('|'),
      );
    });
  });

  group('nhập bộ số', () {
    test('parseNumberSet khớp bản web', () {
      final parsed = parseNumberSet(_v['numberSetInput']! as String);
      _expectText('numberSetNumbers', parsed.numbers.join(','));
      _expectText('numberSetInvalid', parsed.invalid.join(','));
    });

    test('secureRandomNumbers trả bộ số hợp lệ', () {
      final picked = secureRandomNumbers(6);
      expect(picked, hasLength(6));
      expect(picked.toSet(), hasLength(6));
      expect(picked, everyElement(matches(RegExp(r'^\d{2}$'))));
      expect(
        picked.map(int.parse).every((value) => value >= 0 && value <= 99),
        isTrue,
      );
      expect(picked, equals([...picked]..sort()));
      expect(secureRandomNumbers(0), hasLength(1));
      expect(secureRandomNumbers(99), hasLength(20));
    });
  });

  group('nhập CSV', () {
    test('validateCsv khớp bản web', () {
      final csv = _v['csvInput']! as String;
      final validation = validateCsv(csv);
      _expectNumber('csvValidRows', validation.validRows);
      _expectNumber('csvDuplicateRows', validation.duplicateRows);
      _expectText(
        'csvIssues',
        validation.issues
            .map((issue) => '${issue.row}|${issue.level.code}|${issue.message}')
            .join(';'),
      );
      expect(validation.hasError, isTrue);
    });

    test('parseCsvDraws khớp bản web', () {
      final csvDraws = parseCsvDraws(_v['csvInput']! as String);
      _expectNumber('csvDrawsLength', csvDraws.length);
      _expectDraws('csvDraws', csvDraws);
    });
  });

  group('nhập JSON', () {
    test('parseJsonDraws khớp bản web', () {
      final jsonDraws = parseJsonDraws(
        _v['jsonInput']! as String,
        Region.mienBac,
      );
      _expectNumber('jsonDrawsLength', jsonDraws.length);
      _expectDraws('jsonDraws', jsonDraws);
    });

    test('thông báo lỗi khớp bản web', () {
      String messageOf(List<LotteryDraw> Function() run) {
        try {
          run();
          return '(no error)';
        } on FormatException catch (error) {
          return error.message;
        }
      }

      _expectText(
        'jsonErrorEmpty',
        messageOf(() => parseJsonDraws('{}', Region.mienBac)),
      );
      _expectText(
        'jsonErrorBadDate',
        messageOf(
          () => parseJsonDraws(
            '[{"date":"2026-13-01","results":[{"value":"12"}]}]',
            Region.mienBac,
          ),
        ),
      );
      _expectText(
        'jsonErrorDuplicate',
        messageOf(
          () => parseJsonDraws(
            '[{"date":"2026-09-01","drawCode":"X","results":[{"value":"12"}]},'
            '{"date":"2026-09-02","drawCode":"X","results":[{"value":"13"}]}]',
            Region.mienBac,
          ),
        ),
      );
      _expectText(
        'jsonErrorOutOfRange',
        messageOf(
          () => parseJsonDraws(
            '[{"date":"2026-09-01","results":[{"value":"1"}]}]',
            Region.mienBac,
          ),
        ),
      );
      _expectText(
        'jsonErrorNoResults',
        messageOf(
          () => parseJsonDraws(
            '[{"date":"2026-09-01","results":[]}]',
            Region.mienBac,
          ),
        ),
      );
      _expectText(
        'jsonErrorNotObject',
        messageOf(() => parseJsonDraws('[1]', Region.mienBac)),
      );
    });
  });
}
