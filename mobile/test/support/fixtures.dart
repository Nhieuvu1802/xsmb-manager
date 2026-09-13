/// Fixture dùng chung cho test: kỳ quay hợp lệ theo đúng cơ cấu giải.
library;

import 'dart:math' as math;

import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

/// Cơ cấu giải XSMB: (tên giải, số lượng, số chữ số) — tổng 27 số.
const List<(String, int, int)> kMbPrizeLayout = <(String, int, int)>[
  ('Đặc biệt', 1, 5),
  ('Giải nhất', 1, 5),
  ('Giải nhì', 2, 5),
  ('Giải ba', 6, 5),
  ('Giải tư', 4, 4),
  ('Giải năm', 6, 4),
  ('Giải sáu', 3, 3),
  ('Giải bảy', 4, 2),
];

/// Cơ cấu giải XSMN cho một đài — tổng 18 số.
const List<(String, int, int)> kMnPrizeLayout = <(String, int, int)>[
  ('Giải tám', 1, 2),
  ('Giải bảy', 1, 3),
  ('Giải sáu', 3, 4),
  ('Giải năm', 1, 4),
  ('Giải tư', 7, 5),
  ('Giải ba', 2, 5),
  ('Giải nhì', 1, 5),
  ('Giải nhất', 1, 5),
  ('Đặc biệt', 1, 6),
];

/// Sinh `count` số 2 chữ số xác định theo `seed`.
List<String> seededLastTwos(int seed, int count) {
  final random = math.Random(seed);
  return <String>[
    for (var index = 0; index < count; index += 1)
      (random.nextInt(100)).toString().padLeft(2, '0'),
  ];
}

/// Ghép số 2 chữ số thành số đầy đủ đúng độ dài của giải.
String fullNumber(String lastTwo, int digits) =>
    lastTwo.padLeft(digits, '0').substring(0, digits);

/// Tạo danh sách giải hợp lệ theo layout.
List<PrizeRecord> buildPrizes(
  List<(String, int, int)> layout,
  List<String> lastTwos,
) {
  final records = <PrizeRecord>[];
  var cursor = 0;
  for (final (prize, count, digits) in layout) {
    for (var position = 1; position <= count; position += 1) {
      records.add(
        PrizeRecord(
          prize: prize,
          position: position,
          value: fullNumber(lastTwos[cursor % lastTwos.length], digits),
        ),
      );
      cursor += 1;
    }
  }
  return records;
}

/// Kỳ quay XSMB hợp lệ.
DrawRecord buildMbRecord(
  String date, {
  int seed = 1,
  String provider = 'test',
  List<String>? lastTwos,
}) => DrawRecord(
  region: Region.mienBac,
  date: date,
  station: DrawRecord.defaultStation(Region.mienBac),
  results: buildPrizes(kMbPrizeLayout, lastTwos ?? seededLastTwos(seed, 27)),
  provider: provider,
  collectedAt: '${date}T19:00:00+07:00',
  verification: Verification.verified,
);

/// Kỳ quay XSMN hợp lệ cho một đài.
DrawRecord buildMnRecord(
  String date,
  String station, {
  int seed = 1,
  String provider = 'test',
  List<String>? lastTwos,
}) => DrawRecord(
  region: Region.mienNam,
  date: date,
  station: station,
  results: buildPrizes(kMnPrizeLayout, lastTwos ?? seededLastTwos(seed, 18)),
  provider: provider,
  collectedAt: '${date}T17:00:00+07:00',
  verification: Verification.verified,
);

/// Kỳ quay domain (cho engine thống kê/backtest).
LotteryDraw buildMbDomainDraw(
  String date, {
  int seed = 1,
  List<String>? lastTwos,
}) => buildMbRecord(date, seed: seed, lastTwos: lastTwos).toDomain();

/// Chuỗi kỳ quay mô phỏng, mới nhất ở cuối danh sách (thứ tự thời gian).
List<LotteryDraw> buildMbHistory({
  int days = 120,
  DateTime? end,
  int seed = 7,
}) {
  final last = end ?? DateTime.utc(2026, 9, 12);
  return <LotteryDraw>[
    for (var offset = days - 1; offset >= 0; offset -= 1)
      buildMbDomainDraw(
        _iso(last.subtract(Duration(days: offset))),
        seed: seed + offset * 7919,
      ),
  ];
}

/// Danh sách chỉ chứa các số 2 chữ số cho một kỳ (dùng để kiểm tra hit).
Set<String> numberSetOf(List<String> lastTwos) => lastTwos.toSet();

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Ngày ISO công khai cho test.
String isoOf(DateTime date) => _iso(date);
