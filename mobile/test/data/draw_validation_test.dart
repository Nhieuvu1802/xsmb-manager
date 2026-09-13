import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/draw_validation.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

void main() {
  group('kiểm định kỳ quay', () {
    test('kỳ XSMB đủ 27 số là hợp lệ', () {
      final outcome = validateDrawRecord(buildMbRecord('2026-09-10'));
      expect(outcome.isValid, isTrue, reason: outcome.errors.join(', '));
    });

    test('kỳ XSMN đủ 18 số là hợp lệ', () {
      final outcome = validateDrawRecord(
        buildMnRecord('2026-09-10', 'An Giang'),
      );
      expect(outcome.isValid, isTrue, reason: outcome.errors.join(', '));
    });

    test('thiếu giải bị loại', () {
      final draw = buildMbRecord('2026-09-10');
      final shortened = DrawRecord(
        region: draw.region,
        date: draw.date,
        station: draw.station,
        results: draw.results.take(20).toList(),
        provider: draw.provider,
        collectedAt: draw.collectedAt,
      );
      final outcome = validateDrawRecord(shortened);
      expect(outcome.isValid, isFalse);
      expect(outcome.errors.any((item) => item.contains('Giải sáu')), isTrue);
    });

    test('sai độ dài số bị loại', () {
      final base = buildMbRecord('2026-09-10');
      final broken = DrawRecord(
        region: base.region,
        date: base.date,
        station: base.station,
        results: <PrizeRecord>[
          const PrizeRecord(prize: 'Đặc biệt', position: 1, value: '12'),
          ...base.results.skip(1),
        ],
        provider: base.provider,
        collectedAt: base.collectedAt,
      );
      final outcome = validateDrawRecord(broken);
      expect(outcome.isValid, isFalse);
      expect(outcome.errors.any((item) => item.contains('Đặc biệt')), isTrue);
    });

    test('ngày không hợp lệ bị loại', () {
      final outcome = validateDrawRecord(buildMbRecord('2026-02-30'));
      expect(outcome.isValid, isFalse);
      expect(outcome.errors.any((item) => item.contains('Ngày')), isTrue);
    });

    test('trùng giải cùng vị trí bị loại', () {
      final base = buildMbRecord('2026-09-10');
      final duplicated = DrawRecord(
        region: base.region,
        date: base.date,
        station: base.station,
        results: <PrizeRecord>[...base.results, base.results.first],
        provider: base.provider,
        collectedAt: base.collectedAt,
      );
      final outcome = validateDrawRecord(duplicated);
      expect(outcome.isValid, isFalse);
      expect(outcome.errors.any((item) => item.contains('Trùng')), isTrue);
    });

    test('validateDraws trả về đúng các kỳ lỗi', () {
      final invalid = validateDraws(<DrawRecord>[
        buildMbRecord('2026-09-10'),
        buildMbRecord('bad-date'),
      ]);
      expect(invalid.length, 1);
      expect(invalid.keys.first, contains('bad-date'));
    });

    test('kỳ XSMB không nhận giải của XSMN', () {
      final mn = buildMnRecord('2026-09-10', 'An Giang');
      // Kỳ XSMN hợp lệ theo cơ cấu của miền Nam.
      expect(validateDrawRecord(mn).isValid, isTrue);
      final crossed = DrawRecord(
        region: Region.mienBac,
        date: mn.date,
        station: 'Hội đồng XSKT miền Bắc',
        results: mn.results,
        provider: mn.provider,
        collectedAt: mn.collectedAt,
      );
      expect(validateDrawRecord(crossed).isValid, isFalse);
    });
  });
}
