/// Đối chiếu bộ số vừa sinh với lịch sử kỳ quay (cross-check).
///
/// Mục đích không phải để "chứng minh bộ số tốt" mà để người dùng thấy ngay bộ
/// số nằm ở đâu so với kỳ vọng lý thuyết: bao nhiêu kỳ trong cửa sổ gần đây
/// thực sự có ít nhất một số của bộ, và khoảng tin cậy Wilson của tỷ lệ đó có
/// chứa xác suất lý thuyết hay không.
library;

import '../../logic/statistics.dart';
import '../archive/lotto_archive.dart';
import '../lottery_domain.dart';
import 'number_generator.dart';

/// Kết quả đối chiếu **một bộ số** với cửa sổ lịch sử gần nhất.
class SetBackcheck {
  const SetBackcheck({
    required this.setIndex,
    required this.numbers,
    required this.windowDraws,
    required this.hitDraws,
    required this.occurrences,
    required this.lastSeenDates,
    required this.expectedRate,
  });

  /// Số thứ tự bộ trong lần sinh (1-based).
  final int setIndex;

  final List<String> numbers;

  /// Số kỳ gần nhất dùng để đối chiếu.
  final int windowDraws;

  /// Số kỳ trong cửa sổ có ít nhất một số của bộ xuất hiện.
  final int hitDraws;

  /// Số lượt xuất hiện của từng số trong cửa sổ (0 nếu không về).
  final Map<String, int> occurrences;

  /// Ngày gần nhất từng số xuất hiện trong toàn kho; `null` nếu chưa từng về.
  final Map<String, String?> lastSeenDates;

  /// Xác suất lý thuyết "≥ 1 số của bộ xuất hiện trong một kỳ" (27 kết quả).
  final double expectedRate;

  /// Tỷ lệ kỳ thực tế có ít nhất một số của bộ.
  double get hitRate => windowDraws == 0 ? 0 : hitDraws / windowDraws;

  /// Tổng lượt xuất hiện của mọi số trong bộ (một kỳ có thể về nhiều số).
  int get totalOccurrences =>
      occurrences.values.fold(0, (total, value) => total + value);

  /// Khoảng tin cậy 95% (Wilson) của tỷ lệ quan sát.
  List<double> get hitRateInterval => wilsonInterval(hitDraws, windowDraws);

  /// `true` khi xác suất lý thuyết nằm trong khoảng tin cậy quan sát được.
  ///
  /// Nếu đúng, khác biệt quan sát được **không** có ý nghĩa thống kê — bộ số
  /// không "tốt hơn" hay "xấu hơn" lý thuyết, chỉ là dao động của mẫu.
  bool get matchesExpectation {
    if (windowDraws == 0) return false;
    final interval = hitRateInterval;
    return expectedRate >= interval[0] && expectedRate <= interval[1];
  }

  /// Câu kết luận ngắn để UI hiển thị (không hứa hẹn kết quả tương lai).
  String get verdict {
    if (windowDraws == 0) return 'Chưa có kỳ nào để đối chiếu.';
    final interval = hitRateInterval;
    final band = '${formatRate(interval[0])}–${formatRate(interval[1])}';
    if (matchesExpectation) {
      return 'Khớp kỳ vọng lý thuyết (${formatRate(expectedRate)} '
          'nằm trong khoảng $band).';
    }
    return hitRate > expectedRate
        ? 'Cao hơn kỳ vọng trong cửa sổ này (khoảng tin cậy $band).'
        : 'Thấp hơn kỳ vọng trong cửa sổ này (khoảng tin cậy $band).';
  }

  /// Các số của bộ chưa từng xuất hiện trong kho số hiện có.
  List<String> get neverSeenNumbers => <String>[
    for (final number in numbers)
      if (lastSeenDates[number] == null) number,
  ];

  /// Số "nguội" nhất trong bộ — số lâu chưa về nhất theo ngày gần nhất.
  String? get coldestNumber {
    String? coldest;
    String? coldestDate;
    for (final number in numbers) {
      final date = lastSeenDates[number];
      if (date == null) return number;
      if (coldestDate == null || date.compareTo(coldestDate) < 0) {
        coldest = number;
        coldestDate = date;
      }
    }
    return coldest;
  }

  static String formatRate(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';
}

/// Bảng đối chiếu của cả một lần sinh số.
class HistoryMatch {
  const HistoryMatch({
    required this.windowDraws,
    required this.archiveDrawCount,
    required this.rows,
  });

  final int windowDraws;
  final int archiveDrawCount;
  final List<SetBackcheck> rows;

  bool get isEmpty => rows.isEmpty;

  double get averageHitRate => rows.isEmpty
      ? 0
      : rows.fold<double>(0, (total, row) => total + row.hitRate) / rows.length;

  double get expectedRate => rows.isEmpty ? 0 : rows.first.expectedRate;

  /// Số bộ có tỷ lệ quan sát tương thích với xác suất lý thuyết.
  int get matchingSets => rows.where((row) => row.matchesExpectation).length;

  String get verdict {
    if (rows.isEmpty) return 'Chưa có bộ số nào để đối chiếu.';
    return '$matchingSets/${rows.length} bộ nằm trong khoảng tin cậy 95% '
        'của kỳ vọng lý thuyết.';
  }

  /// Chạy đối chiếu cho từng bộ với `window` kỳ gần nhất của [history].
  static HistoryMatch backcheck({
    required List<GeneratedSet> sets,
    required List<LotteryDraw> history,
    LottoArchive? archive,
    int window = 30,
  }) {
    final table = archive != null && !archive.isEmpty
        ? archive
        : LottoArchive.fromDraws(history);
    final ordered = <LotteryDraw>[...history]
      ..sort((a, b) => a.date.compareTo(b.date));
    final safeWindow = window < 1 ? ordered.length : window;
    final recent = safeWindow >= ordered.length
        ? ordered
        : ordered.sublist(ordered.length - safeWindow);

    // Đếm số lượt về của từng số trong cửa sổ bằng một lượt duyệt duy nhất.
    final occurrenceTable = <String, int>{
      for (final number in kAllNumbers) number: 0,
    };
    for (final draw in recent) {
      for (final result in draw.results) {
        final number = lastTwoDigits(result.value);
        occurrenceTable[number] = (occurrenceTable[number] ?? 0) + 1;
      }
    }

    // Ngày gần nhất từng số về, tính trên **toàn bộ** kho số (không chỉ cửa sổ).
    final seenDates = <String, String>{};
    for (final entry in table.entries) {
      final current = seenDates[entry.value];
      if (current == null || entry.date.compareTo(current) > 0) {
        seenDates[entry.value] = entry.date;
      }
    }

    return HistoryMatch(
      windowDraws: recent.length,
      archiveDrawCount: table.drawCount,
      rows: <SetBackcheck>[
        for (final set in sets)
          SetBackcheck(
            setIndex: set.index,
            numbers: set.numbers,
            windowDraws: recent.length,
            hitDraws: _hitDraws(set.numbers, recent),
            occurrences: <String, int>{
              for (final number in set.numbers)
                number: occurrenceTable[number] ?? 0,
            },
            lastSeenDates: <String, String?>{
              for (final number in set.numbers) number: seenDates[number],
            },
            expectedRate: calculateSetProbability(set.numbers.length),
          ),
      ],
    );
  }

  /// Số kỳ trong cửa sổ có ít nhất một số của bộ xuất hiện.
  static int _hitDraws(List<String> numbers, List<LotteryDraw> window) {
    var hits = 0;
    for (final draw in window) {
      final values = draw.results
          .map((result) => lastTwoDigits(result.value))
          .toSet();
      if (numbers.any(values.contains)) hits += 1;
    }
    return hits;
  }
}
