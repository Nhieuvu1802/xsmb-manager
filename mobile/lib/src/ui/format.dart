/// Định dạng số và ngày theo `Intl` locale `vi-VN` mà bản web đang dùng.
///
/// Ví dụ: `formatPercent(0.2377, 2)` → `23,77%`, `formatNumber(10626)` → `10.626`,
/// `formatDateLong('2026-09-12')` → `Thứ Bảy, 12/09/2026`.
library;

const List<String> _weekdayNames = <String>[
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

String _group(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

/// Tương đương `value.toLocaleString('vi-VN')` (tối đa 3 chữ số thập phân).
String formatNumber(num value) {
  if (value.isNaN || value.isInfinite) return '0';
  final negative = value < 0;
  final absolute = value.abs();
  final fractionDigits = absolute is int || absolute == absolute.roundToDouble()
      ? 0
      : 3;
  final parts = absolute.toStringAsFixed(fractionDigits).split('.');
  var text = _group(parts.first);
  if (parts.length > 1 && parts[1].isNotEmpty) {
    final trimmed = parts[1].replaceAll(RegExp(r'0+$'), '');
    if (trimmed.isNotEmpty) text = '$text,$trimmed';
  }
  return negative ? '-$text' : text;
}

/// Tương đương `Intl.NumberFormat('vi-VN', { style: 'percent', ... })`.
String formatPercent(double value, [int digits = 1]) {
  final scaled = value * 100;
  final negative = scaled < 0;
  final text = scaled.abs().toStringAsFixed(digits).replaceAll('.', ',');
  return '${negative ? '-' : ''}$text%';
}

/// Số thập phân kiểu `toFixed` (dấu chấm), dùng cho z-score và χ².
String formatFixed(double value, [int digits = 2]) =>
    value.toStringAsFixed(digits);

String formatSigned(double value, [int digits = 2]) =>
    '${value >= 0 ? '+' : ''}${formatFixed(value, digits)}';

/// `Intl.DateTimeFormat('vi-VN', { weekday: 'long', day, month, year })`.
String formatDateLong(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  final weekday = _weekdayNames[(parsed.weekday - 1) % 7];
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$weekday, $day/$month/${parsed.year}';
}

/// `Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit' })` → `dd-MM`.
String formatDateShort(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day-$month';
}
