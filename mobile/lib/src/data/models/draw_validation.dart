/// Kiểm định dữ liệu trước khi ghi database.
///
/// Dữ liệu sai schema hoặc thiếu giải bị loại để provider kế tiếp được thử.
library;

import '../../core/utils/lottery_dates.dart';
import 'draw_record.dart';

class ValidationOutcome {
  const ValidationOutcome(this.key, this.errors);

  final String key;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

/// Kiểm định một kỳ quay theo quy ước của từng miền.
ValidationOutcome validateDrawRecord(DrawRecord draw) {
  final errors = <String>[];

  if (parseIsoDate(draw.date) == null) {
    errors.add('Ngày không hợp lệ: "${draw.date}"');
  }
  if (draw.station.trim().isEmpty) {
    errors.add('Thiếu tên đài');
  }
  if (draw.results.isEmpty) {
    errors.add('Không có kết quả giải nào');
    return ValidationOutcome(draw.key, errors);
  }

  final rules = prizeRulesFor(draw.region);
  final seen = <String>{};

  for (final result in draw.results) {
    if (!seen.add('${result.prize}#${result.position}')) {
      errors.add('Trùng giải ${result.prize} vị trí ${result.position}');
    }
    if (!rules.containsKey(result.prize)) {
      errors.add(
        'Giải không thuộc cơ cấu ${draw.region.label}: ${result.prize}',
      );
      continue;
    }
    final (_, digits) = rules[result.prize]!;
    if (result.value.length != digits || int.tryParse(result.value) == null) {
      errors.add(
        '${result.prize} vị trí ${result.position} phải là $digits chữ số, nhận "${result.value}"',
      );
    }
  }

  for (final entry in rules.entries) {
    final actual = draw.results.where((r) => r.prize == entry.key).length;
    if (actual != entry.value.$1) {
      errors.add('${entry.key}: cần ${entry.value.$1} số, nhận $actual');
    }
  }

  final expectedTotal = rules.values.fold<int>(0, (sum, rule) => sum + rule.$1);
  if (errors.isEmpty && draw.results.length != expectedTotal) {
    errors.add('Cần $expectedTotal số, nhận ${draw.results.length}');
  }

  return ValidationOutcome(draw.key, errors);
}

/// Kiểm định cả lô dữ liệu, trả về bản đồ key → lỗi cho các kỳ không hợp lệ.
Map<String, List<String>> validateDraws(Iterable<DrawRecord> draws) {
  final invalid = <String, List<String>>{};
  for (final draw in draws) {
    final outcome = validateDrawRecord(draw);
    if (!outcome.isValid) invalid[draw.key] = outcome.errors;
  }
  return invalid;
}
