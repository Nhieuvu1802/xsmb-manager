/// Dữ liệu mô phỏng có seed cố định — port từ `frontend/lib/sample-data.ts`.
///
/// Cùng seed sinh ra cùng kết quả như bản web, nên hai ứng dụng hiển thị
/// thống kê giống nhau. Đây là dữ liệu giả lập, không phải kết quả thật.
library;

import 'dart:math' as math;

import '../domain/lottery_domain.dart';
import '../logic/seeded_random.dart';

/// Cấu trúc giải thưởng XSMB: tên giải, số lượng, số chữ số.
const List<(String, int, int)> _prizes = [
  ('Đặc biệt', 1, 5),
  ('Giải nhất', 1, 5),
  ('Giải nhì', 2, 5),
  ('Giải ba', 6, 5),
  ('Giải tư', 4, 4),
  ('Giải năm', 6, 4),
  ('Giải sáu', 3, 3),
  ('Giải bảy', 4, 2),
];

/// Ngày kết thúc của chuỗi dữ liệu mẫu (UTC).
final DateTime _sampleEnd = DateTime.utc(2026, 9, 12);

String _formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

List<PrizeResult> _makeResults(int seed) {
  final random = Mulberry32(seed);
  final results = <PrizeResult>[];
  for (final (prize, count, digits) in _prizes) {
    final scale = math.pow(10, digits).toInt();
    for (var index = 0; index < count; index += 1) {
      final value = (random.next() * scale).floor().toString().padLeft(
        digits,
        '0',
      );
      results.add(PrizeResult(prize: prize, position: index + 1, value: value));
    }
  }
  return results;
}

/// Sinh `days` kỳ quay mô phỏng, mới nhất ở đầu danh sách.
List<LotteryDraw> createSampleDraws({int days = 365}) {
  return List<LotteryDraw>.generate(days, (index) {
    final date = _sampleEnd.subtract(Duration(days: index));
    final dateString = _formatIsoDate(date);
    return LotteryDraw(
      id: 'mb-$dateString',
      drawCode: 'MB-${dateString.replaceAll('-', '')}',
      lotteryType: LotteryType.traditional,
      date: dateString,
      drawnAt: '${dateString}T18:15:00+07:00',
      region: Region.mienBac,
      station: 'Hội đồng XSKT miền Bắc',
      source: 'Dữ liệu mô phỏng có seed cố định',
      collectedAt: '${dateString}T20:10:00+07:00',
      verification: Verification.sample,
      results: _makeResults(20260912 - index * 7919),
    );
  });
}

/// Bộ dữ liệu mẫu dùng chung cho toàn ứng dụng (365 kỳ gần nhất).
final List<LotteryDraw> kSampleDraws = createSampleDraws();
