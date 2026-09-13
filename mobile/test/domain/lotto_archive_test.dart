import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/domain/archive/lotto_archive.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';

void main() {
  group('kho số tidy', () {
    test('mỗi kết quả thành một dòng id | date | variable | value', () {
      final archive = LottoArchive.fromDraws(
        buildMbHistory(days: 3, seed: 11),
        region: 'MB',
      );

      expect(archive.region, 'MB');
      expect(archive.drawCount, 3);
      expect(archive.entries.length, 3 * 27);
      expect(archive.entries.first.drawIndex, 1);
      expect(archive.entries.first.date, '2026-09-10');
      expect(archive.entries.first.variable, 'Đặc biệt');
      expect(archive.entries.first.value.length, 2);
      expect(archive.entries.last.drawIndex, 3);
    });

    test('bảng tần suất cộng đúng tổng số lượt và có đủ 100 số', () {
      final archive = LottoArchive.fromDraws(buildMbHistory(days: 12, seed: 5));
      final table = archive.frequencyTable();
      final total = table.values.fold(0, (sum, value) => sum + value);

      // Bảng chỉ chứa số đã từng về (giống `count(value)` của repo gốc).
      expect(table.length, lessThanOrEqualTo(100));
      expect(table.length, greaterThan(50));
      expect(total, archive.entries.length);
      final hottest = archive.ranking(count: 1).single;
      expect(table[hottest.label], hottest.count);
      expect(
        archive.frequency(hottest.label),
        greaterThanOrEqualTo(archive.frequency('07')),
      );
    });

    test('số chưa từng về có gan bằng số kỳ trong kho', () {
      final history = <LotteryDraw>[
        for (var index = 0; index < 5; index += 1)
          buildMbDomainDraw(
            '2026-09-0${index + 1}',
            lastTwos: List<String>.filled(27, '42'),
          ),
      ];
      final archive = LottoArchive.fromDraws(history);

      expect(archive.drawsSinceLastSeen('42'), 0);
      expect(archive.drawsSinceLastSeen('07'), 5);
      expect(archive.frequency('42'), 5 * 27);
      expect(archive.frequency('07'), 0);
      expect(archive.ranking(count: 1).single.label, '42');
      expect(archive.ranking(count: 1, ascending: true).single.label, '42');
    });

    test('đếm theo thứ và theo số trong từng thứ', () {
      final archive = LottoArchive.fromDraws(buildMbHistory(days: 14, seed: 3));
      final byWeekday = archive.byWeekday();
      final total = byWeekday.fold(0, (sum, row) => sum + row.count);

      expect(byWeekday.length, kWeekdayLabels.length);
      expect(total, archive.entries.length);
      expect(archive.byYear().first.label, '2026');

      final weekday = weekdayLabelOf(archive.entries.first.date)!;
      final counts = archive.numberByWeekday(archive.entries.first.value);
      expect(counts[weekday], greaterThanOrEqualTo(1));
      expect(counts.keys.toSet(), kWeekdayLabels.toSet());
    });

    test('nhãn thứ đúng với DateTime và an toàn với ngày sai', () {
      expect(weekdayLabelOf(''), isNull);
      expect(weekdayLabelOf('không-phải-ngày'), isNull);
      final iso = '2026-01-01';
      expect(
        weekdayLabelOf(iso),
        kWeekdayLabels[DateTime.tryParse(iso)!.weekday - 1],
      );
      expect(weekdayLabelOf(iso), 'Thứ Năm');
    });

    test('xuất và đọc lại JSON tidy không mất dữ liệu', () {
      final archive = LottoArchive.fromDraws(buildMbHistory(days: 4, seed: 9));
      final decoded = LottoArchive.decode(archive.toTidyJson());

      expect(decoded.length, archive.entries.length);
      expect(decoded.first.value, archive.entries.first.value);
      expect(decoded.last.date, archive.entries.last.date);
      expect(LottoArchive.decode('không phải json'), isEmpty);
      expect(LottoArchive.decode('{"a":1}'), isEmpty);
    });
  });
}
