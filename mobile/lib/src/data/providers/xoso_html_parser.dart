/// Parser HTML cho nguồn công khai (port từ `backend/xsmb_manager/scraper.py`).
///
/// Hàm thuần, không phụ thuộc Flutter nên kiểm thử được bằng HTML tĩnh.
library;

import '../../domain/lottery_domain.dart';
import '../models/draw_record.dart';

/// Số chữ số và số lượng của từng giải (dùng khi tách số từ HTML).
const Map<String, List<int>> _mbLengths = <String, List<int>>{
  'Đặc biệt': [5, 1],
  'Giải nhất': [5, 1],
  'Giải nhì': [5, 2],
  'Giải ba': [5, 6],
  'Giải tư': [4, 4],
  'Giải năm': [4, 6],
  'Giải sáu': [3, 3],
  'Giải bảy': [2, 4],
};

/// Mã giải trong HTML → tên giải XSMB.
const Map<String, String> _mbCodes = <String, String>{
  'DB': 'Đặc biệt',
  'ĐB': 'Đặc biệt',
  '1': 'Giải nhất',
  '2': 'Giải nhì',
  '3': 'Giải ba',
  '4': 'Giải tư',
  '5': 'Giải năm',
  '6': 'Giải sáu',
  '7': 'Giải bảy',
};

/// Mã giải trong HTML → tên giải XSMN.
const Map<String, String> _mnCodes = <String, String>{
  '8': 'Giải tám',
  '7': 'Giải bảy',
  '6': 'Giải sáu',
  '5': 'Giải năm',
  '4': 'Giải tư',
  '3': 'Giải ba',
  '2': 'Giải nhì',
  '1': 'Giải nhất',
  'ĐB': 'Đặc biệt',
  'DB': 'Đặc biệt',
};

/// Bảng kết quả XSMB (một đài) từ HTML.
///
/// Ưu tiên id `mb_prizeXX_itemN`, sau đó tới bảng `<tr>` để tương thích nhiều
/// mẫu trang khác nhau.
List<PrizeRecord> parseXsmbHtml(String html) {
  final found = <String, List<String>>{};

  final idPattern = RegExp(
    r'id="mb_prize(DB|[1-7])_item(\d+)"[^>]*>(.*?)</(?:span|div|td)>',
    caseSensitive: false,
    dotAll: true,
  );
  final indexed = <String, List<(int, String)>>{};
  for (final match in idPattern.allMatches(html)) {
    final prize = _mbCodes[match.group(1)!.toUpperCase()];
    if (prize == null) continue;
    final digits = _mbLengths[prize]![0];
    final number = RegExp(
      '\\d{$digits}',
    ).firstMatch(_stripTags(match.group(3)!));
    if (number != null) {
      indexed.putIfAbsent(prize, () => <(int, String)>[]).add((
        int.parse(match.group(2)!),
        number.group(0)!,
      ));
    }
  }
  for (final entry in indexed.entries) {
    final sorted = [...entry.value]..sort((a, b) => a.$1.compareTo(b.$1));
    found[entry.key] = [for (final item in sorted) item.$2];
  }

  final rowPattern = RegExp(
    r'<tr[^>]*>\s*<(?:th|td)[^>]*>\s*(?:G(?:iải)?\.?\s*)?(ĐB|DB|[1-7])\s*((?:(?!<tr).)*)',
    caseSensitive: false,
    dotAll: true,
  );
  for (final match in rowPattern.allMatches(html)) {
    final prize = _mbCodes[match.group(1)!.toUpperCase()];
    if (prize == null) continue;
    final expected = _mbLengths[prize]![1];
    if ((found[prize]?.length ?? 0) == expected) continue;
    final digits = _mbLengths[prize]![0];
    final numbers = RegExp(
      '>\\s*(\\d{$digits})\\s*<',
    ).allMatches(match.group(2)!).map((item) => item.group(1)!).toList();
    if (numbers.length >= expected) {
      found[prize] = numbers.take(expected).toList();
    }
  }

  return _toPrizeRecords(found, prizeRulesFor(Region.mienBac));
}

/// Bảng kết quả XSMN nhiều đài từ HTML: `station → danh sách giải`.
Map<String, List<PrizeRecord>> parseXsmnHtml(String html) {
  final tables = RegExp(
    r'<table[^>]*>(.*?)</table>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html);
  for (final table in tables) {
    final body = table.group(1)!;
    if (!RegExp(r'(?:G\.?\s*)?(?:8|ĐB)', caseSensitive: false).hasMatch(body)) {
      continue;
    }
    var stations = RegExp(
      r"""title=["']Xổ số\s+([^"']+)""",
      caseSensitive: false,
    ).allMatches(body).map((item) => item.group(1)!.trim()).toList();
    if (stations.isEmpty) {
      stations =
          RegExp(
                r'<h3[^>]*>\s*<a[^>]*>(.*?)</a>',
                caseSensitive: false,
                dotAll: true,
              )
              .allMatches(body)
              .map((item) => _stripTags(item.group(1)!).trim())
              .toList();
    }
    final deduped = <String>{
      for (final station in stations)
        if (station.isNotEmpty && station.length < 40) station,
    }.toList();
    if (deduped.length < 2 || deduped.length > 4) continue;

    final perStation = <String, Map<String, List<String>>>{
      for (final station in deduped) station: <String, List<String>>{},
    };
    final rowPattern = RegExp(
      r'<tr[^>]*>\s*<(?:th|td)[^>]*>\s*(?:G\.?\s*)?(ĐB|DB|[1-8])\s*((?:(?!<tr).)*)',
      caseSensitive: false,
      dotAll: true,
    );
    for (final row in rowPattern.allMatches(body)) {
      final prize = _mnCodes[row.group(1)!.toUpperCase()];
      if (prize == null) continue;
      final (expected, digits) = mnPrizeRules[prize]!;
      final cells = row
          .group(2)!
          .split(RegExp(r'<td[^>]*>', caseSensitive: false));
      for (
        var index = 1;
        index < cells.length && index <= deduped.length;
        index += 1
      ) {
        final cell = cells[index];
        var numbers = RegExp(
          r"""data-loto=["']?(\d{2,6})""",
          caseSensitive: false,
        ).allMatches(cell).map((item) => item.group(1)!).toList();
        if (numbers.isEmpty) {
          numbers = RegExp(
            '>\\s*(\\d{$digits})\\s*<',
          ).allMatches(cell).map((item) => item.group(1)!).toList();
        }
        perStation[deduped[index - 1]]![prize] = numbers
            .take(expected)
            .toList();
      }
    }

    final hasData = perStation.values.any(
      (prizes) => prizes.values.any((values) => values.isNotEmpty),
    );
    if (!hasData) continue;

    return <String, List<PrizeRecord>>{
      for (final entry in perStation.entries)
        entry.key: _toPrizeRecords(entry.value, mnPrizeRules),
    };
  }
  return <String, List<PrizeRecord>>{};
}

List<PrizeRecord> _toPrizeRecords(
  Map<String, List<String>> prizes,
  Map<String, (int, int)> rules,
) {
  final records = <PrizeRecord>[];
  for (final entry in rules.entries) {
    final values = prizes[entry.key] ?? const <String>[];
    for (var index = 0; index < values.length; index += 1) {
      records.add(
        PrizeRecord(
          prize: entry.key,
          position: index + 1,
          value: values[index],
        ),
      );
    }
  }
  return records;
}

String _stripTags(String value) =>
    value.replaceAll(RegExp('<[^>]+>'), ' ').trim();
