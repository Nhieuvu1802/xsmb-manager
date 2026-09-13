/// Ngày tháng dùng chung, không phụ thuộc package `intl`.
library;

/// Ngày ISO `YYYY-MM-DD`.
String isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

/// Parse `YYYY-MM-DD` (UTC) — trả `null` nếu không hợp lệ.
DateTime? parseIsoDate(String value) {
  if (value.length < 10) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final parsed = DateTime.utc(year, month, day);
  if (parsed.month != month || parsed.day != day) return null;
  return parsed;
}

/// Ngày hôm nay theo giờ Việt Nam (UTC+7), không phụ thuộc timezone thiết bị.
///
/// Truyền [now] để có kết quả tất định trong test.
DateTime todayInVietnam({DateTime? now}) {
  final current = (now ?? DateTime.now()).toUtc();
  final vn = current.add(const Duration(hours: 7));
  return DateTime.utc(vn.year, vn.month, vn.day);
}

/// `dd/MM/yyyy` để hiển thị.
String displayDate(String isoValue) {
  final parts = isoValue.split('-');
  if (parts.length != 3) return isoValue;
  return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
}

/// `dd-MM` cho nhãn biểu đồ.
String shortDate(String isoValue) {
  final parts = isoValue.split('-');
  if (parts.length != 3) return isoValue;
  return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
}

/// Danh sách ngày từ `start` tới `end` (bao gồm hai đầu).
List<DateTime> isoDateRange(DateTime start, DateTime end) {
  final days = <DateTime>[];
  var cursor = DateTime.utc(start.year, start.month, start.day);
  final last = DateTime.utc(end.year, end.month, end.day);
  while (!cursor.isAfter(last)) {
    days.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
  return days;
}

/// Thứ trong tuần theo quy ước 2 = thứ Hai … 8 = Chủ Nhật (ISO-8601).
int isoWeekday(DateTime day) => day.weekday;

/// Các đài XSMN quay theo tuần (khớp `MN_WEEKLY_SCHEDULE` của backend).
const Map<int, List<String>> mnWeeklySchedule = <int, List<String>>{
  DateTime.monday: ['TPHCM', 'Đồng Tháp', 'Cà Mau'],
  DateTime.tuesday: ['Bến Tre', 'Vũng Tàu', 'Bạc Liêu'],
  DateTime.wednesday: ['Đồng Nai', 'Cần Thơ', 'Sóc Trăng'],
  DateTime.thursday: ['Tây Ninh', 'An Giang', 'Bình Thuận'],
  DateTime.friday: ['Vĩnh Long', 'Bình Dương', 'Trà Vinh'],
  DateTime.saturday: ['TPHCM', 'Long An', 'Bình Phước', 'Hậu Giang'],
  DateTime.sunday: ['Tiền Giang', 'Kiên Giang', 'Đà Lạt'],
};

/// Đài quay trong một ngày (miền Nam), rỗng nếu ngày không hợp lệ.
List<String> stationsForDay(DateTime day) =>
    mnWeeklySchedule[day.weekday] ?? const <String>[];
