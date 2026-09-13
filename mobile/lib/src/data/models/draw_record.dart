/// Model dữ liệu kết quả quay số dùng cho tầng data.
///
/// Tách khỏi `domain/lottery_domain.dart` (model cho UI) để tầng mạng/lưu trữ
/// có thể thay đổi mà không ảnh hưởng giao diện. `DrawRecord.toDomain()` là
/// cầu nối duy nhất giữa hai tầng.
library;

import '../../domain/lottery_domain.dart';
import '../../logic/statistics.dart';

/// Quy ước số lượng và độ dài số của từng giải (nguồn: luật XSKT).
const Map<String, (int, int)> mbPrizeRules = <String, (int, int)>{
  'Đặc biệt': (1, 5),
  'Giải nhất': (1, 5),
  'Giải nhì': (2, 5),
  'Giải ba': (6, 5),
  'Giải tư': (4, 4),
  'Giải năm': (6, 4),
  'Giải sáu': (3, 3),
  'Giải bảy': (4, 2),
};

const Map<String, (int, int)> mnPrizeRules = <String, (int, int)>{
  'Giải tám': (1, 2),
  'Giải bảy': (1, 3),
  'Giải sáu': (3, 4),
  'Giải năm': (1, 4),
  'Giải tư': (7, 5),
  'Giải ba': (2, 5),
  'Giải nhì': (1, 5),
  'Giải nhất': (1, 5),
  'Đặc biệt': (1, 6),
};

Map<String, (int, int)> prizeRulesFor(Region region) =>
    region == Region.mienBac ? mbPrizeRules : mnPrizeRules;

/// Mã vùng trong API → [Region].
Region regionFromCode(String? code) {
  switch ((code ?? '').toLowerCase()) {
    case 'mb':
    case 'mien_bac':
    case 'north':
      return Region.mienBac;
    case 'mt':
    case 'mien_trung':
    case 'central':
      return Region.mienTrung;
    default:
      return Region.mienNam;
  }
}

/// Mã trạng thái xác minh → [Verification].
Verification verificationFromCode(String? code) {
  final upper = (code ?? '').toUpperCase();
  for (final item in Verification.values) {
    if (item.code == upper) return item;
  }
  return Verification.pending;
}

/// Mã vùng dùng trong API (`mb`, `mt`, `mn`).
extension RegionCode on Region {
  String get code => switch (this) {
    Region.mienBac => 'mb',
    Region.mienTrung => 'mt',
    Region.mienNam => 'mn',
  };

  bool get usesProvinces => this != Region.mienBac;
}

/// Một giải trong kỳ quay.
class PrizeRecord {
  const PrizeRecord({
    required this.prize,
    required this.position,
    required this.value,
  });

  final String prize;
  final int position;
  final String value;

  String get lastTwo => lastTwoDigits(value);

  factory PrizeRecord.fromJson(Map<String, dynamic> json) => PrizeRecord(
    prize: (json['prize'] ?? '').toString(),
    position: (json['position'] as num?)?.toInt() ?? 0,
    value: (json['value'] ?? json['full_number'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'prize': prize,
    'position': position,
    'value': value,
  };

  PrizeResult toDomain() =>
      PrizeResult(prize: prize, position: position, value: value);
}

/// Một kỳ quay hoàn chỉnh của một đài (miền Bắc: một đài duy nhất).
class DrawRecord {
  const DrawRecord({
    required this.region,
    required this.date,
    required this.station,
    required this.results,
    required this.provider,
    required this.collectedAt,
    this.verification = Verification.pending,
    this.drawCode,
  });

  final Region region;
  final String date;
  final String station;
  final List<PrizeRecord> results;
  final String provider;
  final String collectedAt;
  final Verification verification;
  final String? drawCode;

  /// Khoá duy nhất trong database: vùng + ngày + đài.
  String get key => '${region.code}|$date|$station';

  String get resolvedDrawCode =>
      drawCode ??
      '${region.code.toUpperCase()}-${date.replaceAll('-', '')}-$station';

  int get totalSlots => results.length;

  List<String> get loto2 => [for (final r in results) r.lastTwo];

  /// Tần suất 2 số cuối trong kỳ (một số có thể xuất hiện nhiều lần).
  Map<String, int> get frequency {
    final counts = <String, int>{};
    for (final number in loto2) {
      counts.update(number, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  factory DrawRecord.fromJson(Map<String, dynamic> json, {String? provider}) {
    final region = regionFromCode(json['region']?.toString());
    final rawResults = (json['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PrizeRecord.fromJson)
        .toList(growable: false);
    return DrawRecord(
      region: region,
      date: (json['date'] ?? json['draw_date'] ?? '').toString(),
      station: (json['station'] ?? json['province'] ?? defaultStation(region))
          .toString(),
      results: rawResults,
      provider: provider ?? (json['source'] ?? 'không rõ').toString(),
      collectedAt: (json['collected_at'] ?? json['collectedAt'] ?? '')
          .toString(),
      verification: verificationFromCode(json['verification']?.toString()),
      drawCode: json['draw_code']?.toString(),
    );
  }

  /// Chuyển từ domain model (UI) sang model lưu trữ.
  factory DrawRecord.fromDomain(LotteryDraw draw) => DrawRecord(
    region: draw.region,
    date: draw.date,
    station: draw.station,
    results: <PrizeRecord>[
      for (final result in draw.results)
        PrizeRecord(
          prize: result.prize,
          position: result.position,
          value: result.value,
        ),
    ],
    provider: draw.source,
    collectedAt: draw.collectedAt,
    verification: draw.verification,
    drawCode: draw.drawCode,
  );

  /// Ghép các dòng phẳng của API cũ (`/api/v1/draws/mb`) thành kỳ quay.
  static List<DrawRecord> fromLegacyRows(
    List<dynamic> rows, {
    required Region region,
    required String provider,
  }) {
    final grouped = <String, List<PrizeRecord>>{};
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final date = (row['draw_date'] ?? '').toString();
      if (date.isEmpty) continue;
      final key = '$date|${(row['province'] ?? '').toString()}';
      grouped
          .putIfAbsent(key, () => <PrizeRecord>[])
          .add(
            PrizeRecord(
              prize: (row['prize'] ?? '').toString(),
              position: (row['position'] as num?)?.toInt() ?? 0,
              value: (row['full_number'] ?? row['value'] ?? '').toString(),
            ),
          );
    }
    final now = DateTime.now().toIso8601String();
    return <DrawRecord>[
      for (final entry in grouped.entries)
        DrawRecord(
          region: region,
          date: entry.key.split('|').first,
          station: entry.key.split('|').last.isEmpty
              ? defaultStation(region)
              : entry.key.split('|').last,
          results: entry.value
            ..sort(
              (a, b) => a.prize == b.prize
                  ? a.position.compareTo(b.position)
                  : a.prize.compareTo(b.prize),
            ),
          provider: provider,
          collectedAt: now,
          verification: Verification.verified,
        ),
    ];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'region': region.code,
    'date': date,
    'station': station,
    'source': provider,
    'collected_at': collectedAt,
    'verification': verification.code,
    'draw_code': resolvedDrawCode,
    'results': [for (final result in results) result.toJson()],
  };

  LotteryDraw toDomain() => LotteryDraw(
    id: resolvedDrawCode,
    drawCode: resolvedDrawCode,
    lotteryType: LotteryType.traditional,
    date: date,
    drawnAt: '${date}T18:15:00+07:00',
    region: region,
    station: station,
    source: provider,
    collectedAt: collectedAt,
    verification: verification,
    results: [for (final result in results) result.toDomain()],
  );

  static String defaultStation(Region region) =>
      region == Region.mienBac ? 'Hội đồng XSKT miền Bắc' : 'Nhiều đài';
}
