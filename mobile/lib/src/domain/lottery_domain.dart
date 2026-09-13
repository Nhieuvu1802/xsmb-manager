/// Kiểu miền nghiệp vụ, port từ `frontend/lib/lottery-domain.ts`.
///
/// Toàn bộ ứng dụng chỉ dùng dữ liệu mô phỏng / do người dùng nhập; không có
/// chức năng cá cược, nạp rút hay dự đoán chắc chắn.
library;

/// Khu vực quay số.
enum Region {
  mienBac('Miền Bắc'),
  mienTrung('Miền Trung'),
  mienNam('Miền Nam');

  const Region(this.label);

  final String label;

  static Region fromLabel(String? value) {
    return Region.values.firstWhere(
      (region) => region.label == value,
      orElse: () => Region.mienBac,
    );
  }
}

/// Loại hình xổ số.
enum LotteryType {
  traditional('TRADITIONAL', 'Xổ số truyền thống'),
  combination('COMBINATION', 'Xổ số tự chọn');

  const LotteryType(this.code, this.label);

  final String code;
  final String label;
}

/// Trạng thái xác minh của một kỳ quay.
enum Verification {
  sample('SAMPLE', 'Dữ liệu mẫu'),
  pending('PENDING', 'Chờ xác minh'),
  verified('VERIFIED', 'Đã xác minh'),
  rejected('REJECTED', 'Bị loại');

  const Verification(this.code, this.label);

  final String code;
  final String label;
}

/// Một giải trong kỳ quay. `value` giữ nguyên số như nguồn cung cấp.
class PrizeResult {
  const PrizeResult({
    required this.prize,
    required this.position,
    required this.value,
  });

  final String prize;
  final int position;
  final String value;
}

/// Một kỳ quay hoàn chỉnh.
class LotteryDraw {
  const LotteryDraw({
    required this.id,
    required this.drawCode,
    required this.lotteryType,
    required this.date,
    required this.drawnAt,
    required this.region,
    required this.station,
    required this.source,
    required this.collectedAt,
    required this.verification,
    required this.results,
  });

  final String id;
  final String drawCode;
  final LotteryType lotteryType;
  final String date;
  final String drawnAt;
  final Region region;
  final String station;
  final String source;
  final String collectedAt;
  final Verification verification;
  final List<PrizeResult> results;
}

/// Thống kê lịch sử của một số 00–99.
class NumberStat {
  const NumberStat({
    required this.number,
    required this.count,
    required this.drawHits,
    required this.rate,
    required this.drawRate,
    required this.gap,
    required this.averageGap,
    required this.zScore,
  });

  final String number;

  /// Tổng số lượt xuất hiện (một kỳ có thể xuất hiện nhiều lần).
  final int count;

  /// Số kỳ có xuất hiện ít nhất một lần.
  final int drawHits;

  /// Tần suất theo tổng số kết quả.
  final double rate;

  /// Tỷ lệ theo số kỳ.
  final double drawRate;

  /// Số kỳ kể từ lần xuất hiện gần nhất; `null` nếu chưa từng xuất hiện.
  final int? gap;

  /// Khoảng cách trung bình giữa hai lần xuất hiện liên tiếp.
  final double? averageGap;

  final double zScore;
}

/// Mức độ của một cảnh báo dữ liệu.
enum DataIssueLevel {
  error('error'),
  warning('warning');

  const DataIssueLevel(this.code);

  final String code;
}

/// Một dòng cảnh báo khi kiểm định CSV.
class DataIssue {
  const DataIssue({
    required this.row,
    required this.level,
    required this.message,
  });

  final int row;
  final DataIssueLevel level;
  final String message;
}

/// Báo cáo kiểm định CSV.
class CsvValidation {
  const CsvValidation({
    required this.validRows,
    required this.duplicateRows,
    required this.issues,
  });

  final int validRows;
  final int duplicateRows;
  final List<DataIssue> issues;

  bool get hasError =>
      issues.any((issue) => issue.level == DataIssueLevel.error);
}

/// Cặp số xuất hiện cùng kỳ.
class PairStat {
  const PairStat({required this.pair, required this.count});

  final String pair;
  final int count;
}

/// Phân bố theo ngày trong tuần.
class DayOfWeekStat {
  const DayOfWeekStat({
    required this.day,
    required this.dayIndex,
    required this.count,
    required this.drawHits,
  });

  final String day;
  final int dayIndex;
  final int count;
  final int drawHits;
}

/// Một điểm trên biểu đồ xu hướng.
class TrendPoint {
  const TrendPoint({required this.date, required this.hits});

  final String date;
  final int hits;
}

/// Cặp giá trị nhãn/số lượng dùng cho biểu đồ thanh.
class LabeledCount {
  const LabeledCount({required this.label, required this.count});

  final String label;
  final int count;
}

/// Chuỗi số liên tiếp trong cùng một kỳ quay.
class SequenceStat {
  const SequenceStat({required this.sequence, required this.count});

  final String sequence;
  final int count;
}

/// Kết quả phân tích cấu trúc dãy số.
class StructureStats {
  const StructureStats({
    required this.digitCounts,
    required this.heads,
    required this.tails,
    required this.sums,
    required this.evenCount,
    required this.oddCount,
    required this.ranges,
    required this.sequences,
  });

  final List<LabeledCount> digitCounts;
  final List<LabeledCount> heads;
  final List<LabeledCount> tails;
  final List<LabeledCount> sums;
  final int evenCount;
  final int oddCount;
  final List<LabeledCount> ranges;
  final List<SequenceStat> sequences;
}

/// Kết quả tách bộ số người dùng nhập.
class NumberSetParse {
  const NumberSetParse({required this.numbers, required this.invalid});

  final List<String> numbers;
  final List<String> invalid;
}
