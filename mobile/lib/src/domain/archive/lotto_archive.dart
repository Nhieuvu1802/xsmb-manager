/// Kho số dạng **tidy (long)** cho lịch sử XSMB/XSMN.
///
/// Ý tưởng lấy từ repo tham chiếu `LottoNumberArchive` (lotto Đức 1955–2026):
/// mỗi dòng là một con số của một kỳ quay với 4 trường
/// `id | date | variable | value` — trong đó `variable` là loại số
/// (`Lottozahl`/`Superzahl` của bản gốc, ở đây là tên giải) và `value` là số
/// 2 chữ số. Nhờ dạng long, việc đếm tần suất chỉ là `group by value` giống
/// ví dụ R/Python của repo gốc, và có thể đếm thêm theo thứ trong tuần, theo
/// năm, theo giải.
///
/// Lớp này là dữ liệu thuần (không phụ thuộc Flutter) nên dùng được cho
/// engine tính số, cho UI "Kho số" và cho việc xuất file archive.
library;

import 'dart:convert';

import '../../logic/statistics.dart';
import '../lottery_domain.dart';

/// Nhãn thứ trong tuần, khớp `formatDateLong` của `ui/format.dart`.
const List<String> kWeekdayLabels = <String>[
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

/// Nhãn thứ của một ngày ISO; trả về `null` khi ngày không hợp lệ.
String? weekdayLabelOf(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return null;
  return kWeekdayLabels[(parsed.weekday - 1) % 7];
}

/// Một dòng dữ liệu lưu trữ: một con số của một kỳ quay.
class ArchiveEntry {
  const ArchiveEntry({
    required this.drawIndex,
    required this.date,
    required this.variable,
    required this.value,
  });

  /// Số thứ tự kỳ quay (1-based, theo thời gian tăng dần) — tương đương `id`.
  final int drawIndex;
  final String date;
  final String variable;
  final String value;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': drawIndex,
    'date': date,
    'variable': variable,
    'value': value,
  };

  factory ArchiveEntry.fromJson(Map<String, Object?> json) => ArchiveEntry(
    drawIndex: (json['id'] as num?)?.toInt() ?? 0,
    date: (json['date'] ?? '').toString(),
    variable: (json['variable'] ?? '').toString(),
    value: (json['value'] ?? '').toString().padLeft(2, '0'),
  );
}

/// Kho số của một vùng: danh sách dòng tidy + các phép đếm dùng cho tính số.
class LottoArchive {
  const LottoArchive({
    required this.region,
    required this.drawCount,
    required this.entries,
  });

  final String region;

  /// Số kỳ quay mà kho số đang giữ (kể cả kỳ không có số nào hợp lệ).
  final int drawCount;

  final List<ArchiveEntry> entries;

  static const LottoArchive empty = LottoArchive(
    region: '',
    drawCount: 0,
    entries: <ArchiveEntry>[],
  );

  bool get isEmpty => entries.isEmpty;

  /// Dựng kho số từ lịch sử kỳ quay (thứ tự đầu vào không quan trọng).
  factory LottoArchive.fromDraws(List<LotteryDraw> draws, {String? region}) {
    final ordered = <LotteryDraw>[...draws]
      ..sort((a, b) => a.date.compareTo(b.date));
    final entries = <ArchiveEntry>[];
    for (var index = 0; index < ordered.length; index += 1) {
      for (final result in ordered[index].results) {
        final value = lastTwoDigits(result.value);
        entries.add(
          ArchiveEntry(
            drawIndex: index + 1,
            date: ordered[index].date,
            variable: result.prize,
            value: value,
          ),
        );
      }
    }
    final label = (region ?? '').isNotEmpty
        ? region!
        : (ordered.isEmpty ? '' : ordered.first.region.label);
    return LottoArchive(
      region: label,
      drawCount: ordered.length,
      entries: List<ArchiveEntry>.unmodifiable(entries),
    );
  }

  /// Danh sách loại số (`variable`) có trong kho, sắp xếp theo bảng chữ cái.
  List<String> get variables {
    final set = <String>{for (final entry in entries) entry.variable};
    return set.toList()..sort();
  }

  /// Bảng tần suất `value → số lượt xuất hiện` (giống `count(value)` repo gốc).
  Map<String, int> frequencyTable({String? variable}) {
    final table = <String, int>{};
    for (final entry in entries) {
      if (variable != null && entry.variable != variable) continue;
      table[entry.value] = (table[entry.value] ?? 0) + 1;
    }
    return table;
  }

  /// Số lượt xuất hiện của một số.
  int frequency(String number, {String? variable}) =>
      frequencyTable(variable: variable)[number] ?? 0;

  /// Số thứ tự kỳ quay gần nhất mà mỗi số xuất hiện (0 = chưa từng xuất hiện).
  Map<String, int> lastSeenDrawIndex({String? variable}) {
    final table = <String, int>{};
    for (final entry in entries) {
      if (variable != null && entry.variable != variable) continue;
      final current = table[entry.value] ?? 0;
      if (entry.drawIndex > current) table[entry.value] = entry.drawIndex;
    }
    return table;
  }

  /// Số kỳ đã trôi qua kể từ lần xuất hiện gần nhất của một số.
  ///
  /// Bằng `drawCount` khi số chưa từng xuất hiện (gan tối đa trong kho số).
  int drawsSinceLastSeen(String number, {String? variable}) {
    final last = lastSeenDrawIndex(variable: variable)[number] ?? 0;
    if (last == 0) return drawCount;
    return drawCount - last;
  }

  /// Xếp hạng số theo tần suất: `ascending = true` để lấy nhóm **lạnh** (ít về).
  List<LabeledCount> ranking({
    int count = 10,
    bool ascending = false,
    String? variable,
  }) {
    final table = frequencyTable(variable: variable);
    final rows =
        <LabeledCount>[
          for (final entry in table.entries)
            LabeledCount(label: entry.key, count: entry.value),
        ]..sort((a, b) {
          final byCount = ascending
              ? a.count.compareTo(b.count)
              : b.count.compareTo(a.count);
          return byCount != 0 ? byCount : a.label.compareTo(b.label);
        });
    if (count <= 0 || count >= rows.length) {
      return List<LabeledCount>.unmodifiable(rows);
    }
    return List<LabeledCount>.unmodifiable(rows.take(count));
  }

  /// Tần suất theo thứ trong tuần (thứ không có kỳ nào vẫn trả 0).
  List<LabeledCount> byWeekday({String? variable}) {
    final counts = <String, int>{for (final day in kWeekdayLabels) day: 0};
    for (final entry in entries) {
      if (variable != null && entry.variable != variable) continue;
      final label = weekdayLabelOf(entry.date);
      if (label == null) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return List<LabeledCount>.unmodifiable(<LabeledCount>[
      for (final day in kWeekdayLabels)
        LabeledCount(label: day, count: counts[day] ?? 0),
    ]);
  }

  /// Tần suất theo năm (dùng `date` ISO `YYYY-MM-DD`).
  List<LabeledCount> byYear({String? variable}) {
    final counts = <String, int>{};
    for (final entry in entries) {
      if (variable != null && entry.variable != variable) continue;
      final year = entry.date.length >= 4 ? entry.date.substring(0, 4) : '—';
      counts[year] = (counts[year] ?? 0) + 1;
    }
    final years = counts.keys.toList()..sort();
    return List<LabeledCount>.unmodifiable(<LabeledCount>[
      for (final year in years) LabeledCount(label: year, count: counts[year]!),
    ]);
  }

  /// Tần suất của **một số** theo từng thứ trong tuần (`0` nếu chưa từng về).
  Map<String, int> numberByWeekday(String number, {String? variable}) {
    final counts = <String, int>{for (final day in kWeekdayLabels) day: 0};
    for (final entry in entries) {
      if (entry.value != number) continue;
      if (variable != null && entry.variable != variable) continue;
      final label = weekdayLabelOf(entry.date);
      if (label == null) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  /// Xuất kho số ra JSON dạng tidy giống file của `LottoNumberArchive`.
  String toTidyJson() =>
      jsonEncode(<Object?>[for (final entry in entries) entry.toJson()]);

  /// Đọc lại kho số từ JSON tidy; trả về danh sách rỗng khi JSON không hợp lệ.
  static List<ArchiveEntry> decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const <ArchiveEntry>[];
    }
    if (decoded is! List) return const <ArchiveEntry>[];
    return <ArchiveEntry>[
      for (final item in decoded)
        if (item is Map) ArchiveEntry.fromJson(item.cast<String, Object?>()),
    ];
  }
}
