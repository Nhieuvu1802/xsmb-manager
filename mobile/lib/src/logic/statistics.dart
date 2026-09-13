/// Công thức và kiểm định thống kê thuần, port từ `frontend/lib/statistics.ts`.
///
/// Các hàm ở đây không phụ thuộc Flutter nên kiểm thử được độc lập. Toàn bộ
/// chỉ là thống kê mô tả quá khứ, không phải dự đoán kết quả tương lai.
library;

import 'dart:convert';
import 'dart:math' as math;

import '../domain/lottery_domain.dart';
import 'seeded_random.dart';

/// Danh sách đủ 100 số từ "00" tới "99".
final List<String> kAllNumbers = List<String>.generate(
  100,
  (index) => index.toString().padLeft(2, '0'),
  growable: false,
);

/// Hai chữ số cuối của một giá trị kết quả.
String lastTwoDigits(String value) {
  final tail = value.length <= 2 ? value : value.substring(value.length - 2);
  return tail.padLeft(2, '0');
}

/// Thống kê lịch sử cho cả 100 số 00–99.
List<NumberStat> calculateNumberStats(List<LotteryDraw> draws) {
  final drawCount = draws.length;
  var totalSlots = 0;
  for (final draw in draws) {
    totalSlots += draw.results.length;
  }

  return kAllNumbers
      .map((number) {
        final hitIndexes = <int>[];
        var count = 0;

        for (var drawIndex = 0; drawIndex < draws.length; drawIndex += 1) {
          var hitInDraw = false;
          for (final result in draws[drawIndex].results) {
            if (lastTwoDigits(result.value) == number) {
              count += 1;
              hitInDraw = true;
            }
          }
          if (hitInDraw) hitIndexes.add(drawIndex);
        }

        final expected = totalSlots * 0.01;
        final deviation = math.sqrt(totalSlots * 0.01 * 0.99);
        final gaps = <int>[
          for (var index = 1; index < hitIndexes.length; index += 1)
            hitIndexes[index] - hitIndexes[index - 1],
        ];

        return NumberStat(
          number: number,
          count: count,
          drawHits: hitIndexes.length,
          rate: totalSlots != 0 ? count / totalSlots : 0,
          drawRate: drawCount != 0 ? hitIndexes.length / drawCount : 0,
          gap: hitIndexes.isNotEmpty ? hitIndexes.first : null,
          averageGap: gaps.isNotEmpty
              ? gaps.reduce((a, b) => a + b) / gaps.length
              : null,
          zScore: deviation != 0 ? (count - expected) / deviation : 0,
        );
      })
      .toList(growable: false);
}

/// Xu hướng số lượt xuất hiện của nhóm số theo dõi trong 30 kỳ gần nhất.
List<TrendPoint> buildTrend(
  List<LotteryDraw> draws,
  List<String> trackedNumbers,
) {
  final chronological = draws.reversed.toList(growable: false);
  final window = chronological.length > 30
      ? chronological.sublist(chronological.length - 30)
      : chronological;

  return window
      .map((draw) {
        final hits = draw.results
            .map((result) => lastTwoDigits(result.value))
            .where(trackedNumbers.contains)
            .length;
        return TrendPoint(date: _formatDayMonth(draw.date), hits: hits);
      })
      .toList(growable: false);
}

/// Xác suất ít nhất một lần trúng khi chọn `size` số trong `slots` vị trí.
double calculateSetProbability(int size, {int slots = 27}) {
  if (size <= 0) return 0;
  final safeSize = math.min(size, 100);
  return 1 - math.pow((100 - safeSize) / 100, slots).toDouble();
}

/// Xác suất trúng chính xác `digits` chữ số; `null` nếu ngoài khoảng 1–12.
double? exactDigitProbability(int digits) {
  if (digits < 1 || digits > 12) return null;
  return 1 / math.pow(10, digits);
}

/// Tổ hợp C(n, k); trả 0 khi tham số không hợp lệ.
int combinations(int n, int k) {
  if (n < 0 || k < 0 || k > n) return 0;
  final smaller = math.min(k, n - k);
  var result = 1.0;
  for (var index = 1; index <= smaller; index += 1) {
    result = (result * (n - smaller + index)) / index;
  }
  return result.round();
}

/// Giá trị kỳ vọng của một vé: `P(trúng) × giải thưởng − giá vé`.
double expectedValue(num ticketPrice, num prize, double winProbability) {
  return winProbability * prize - ticketPrice;
}

/// Khoảng tin cậy Wilson 95% (ổn định hơn xấp xỉ Wald ở mẫu nhỏ).
List<double> wilsonInterval(int successes, int trials, {double z = 1.96}) {
  if (trials == 0) return const [0, 0];
  final observed = successes / trials;
  final denominator = 1 + (z * z) / trials;
  final center = (observed + (z * z) / (2 * trials)) / denominator;
  final margin =
      (z / denominator) *
      math.sqrt(
        (observed * (1 - observed)) / trials + (z * z) / (4 * trials * trials),
      );
  return [math.max(0, center - margin), math.min(1, center + margin)];
}

/// Thống kê chi bình phương cho giả thuyết phân phối đều 100 số.
double chiSquareUniform(List<NumberStat> stats) {
  var total = 0;
  for (final item in stats) {
    total += item.count;
  }
  final expected = total / 100;
  if (expected == 0) return 0;
  return stats.fold<double>(
    0,
    (sum, item) => sum + math.pow(item.count - expected, 2) / expected,
  );
}

/// Cặp số xuất hiện cùng kỳ, nhiều nhất trước, tối đa 30 cặp.
List<PairStat> calculatePairStats(List<LotteryDraw> draws) {
  final pairCounts = <String, int>{};
  for (final draw in draws) {
    final values = <String>{
      for (final result in draw.results) lastTwoDigits(result.value),
    }.toList(growable: false);
    for (var i = 0; i < values.length; i += 1) {
      for (var j = i + 1; j < values.length; j += 1) {
        final pair = values[i].compareTo(values[j]) < 0
            ? '${values[i]}-${values[j]}'
            : '${values[j]}-${values[i]}';
        pairCounts[pair] = (pairCounts[pair] ?? 0) + 1;
      }
    }
  }

  final sorted = _stableSortBy(
    pairCounts.entries.toList(growable: false),
    (a, b) => b.value.compareTo(a.value),
  );
  return sorted
      .take(30)
      .map((entry) => PairStat(pair: entry.key, count: entry.value))
      .toList(growable: false);
}

/// Phân bố số kỳ và số kết quả theo 7 ngày trong tuần (CN → T7).
List<DayOfWeekStat> calculateDayOfWeekStats(List<LotteryDraw> draws) {
  const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  final counts = List<int>.filled(7, 0);
  final drawHits = List<int>.filled(7, 0);

  for (final draw in draws) {
    final dayIndex = _dayIndexFor(draw.date);
    counts[dayIndex] += draw.results.length;
    drawHits[dayIndex] += 1;
  }

  return List<DayOfWeekStat>.generate(
    7,
    (index) => DayOfWeekStat(
      day: dayNames[index],
      dayIndex: index,
      count: counts[index],
      drawHits: drawHits[index],
    ),
    growable: false,
  );
}

/// Mô phỏng Monte Carlo có seed cố định cho xác suất "ít nhất một lần".
double monteCarloAtLeastOne(
  int selectionSize,
  int slots, {
  int simulations = 10000,
  int seed = 2409,
}) {
  final random = LinearCongruential(seed);
  var wins = 0;
  for (var simulation = 0; simulation < simulations; simulation += 1) {
    var hit = false;
    for (var slot = 0; slot < slots && !hit; slot += 1) {
      hit = (random.next() * 100).floor() < selectionSize;
    }
    if (hit) wins += 1;
  }
  return wins / simulations;
}

/// Cấu trúc dãy số: đầu, đuôi, tổng, chẵn lẻ, khoảng và chuỗi liên tiếp.
StructureStats calculateStructure(List<LotteryDraw> draws) {
  final values = <String>[
    for (final draw in draws)
      for (final result in draw.results) lastTwoDigits(result.value),
  ];

  final digitCounts = List<int>.filled(10, 0);
  final heads = List<int>.filled(10, 0);
  final tails = List<int>.filled(10, 0);
  final sums = List<int>.filled(19, 0);
  final ranges = List<int>.filled(5, 0);
  var even = 0;
  var odd = 0;

  for (final value in values) {
    final head = int.parse(value[0]);
    final tail = int.parse(value[1]);
    final numeric = int.parse(value);
    heads[head] += 1;
    tails[tail] += 1;
    digitCounts[head] += 1;
    digitCounts[tail] += 1;
    sums[head + tail] += 1;
    if (numeric.isEven) {
      even += 1;
    } else {
      odd += 1;
    }
    ranges[numeric < 80 ? numeric ~/ 20 : 4] += 1;
  }

  final sequenceCounts = <String, int>{};
  for (final draw in draws) {
    final drawValues = draw.results
        .map((result) => lastTwoDigits(result.value))
        .toList(growable: false);
    for (var index = 0; index < drawValues.length - 1; index += 1) {
      final pair = '${drawValues[index]}–${drawValues[index + 1]}';
      sequenceCounts[pair] = (sequenceCounts[pair] ?? 0) + 1;
      if (index < drawValues.length - 2) {
        final triple = '$pair–${drawValues[index + 2]}';
        sequenceCounts[triple] = (sequenceCounts[triple] ?? 0) + 1;
      }
    }
  }

  final topSequences =
      _stableSortBy(
            sequenceCounts.entries.toList(growable: false),
            (a, b) => b.value.compareTo(a.value),
          )
          .take(8)
          .map((entry) => SequenceStat(sequence: entry.key, count: entry.value))
          .toList(growable: false);

  return StructureStats(
    digitCounts: _toLabeledCounts(digitCounts),
    heads: _toLabeledCounts(heads),
    tails: _toLabeledCounts(tails),
    sums: _toLabeledCounts(sums),
    evenCount: even,
    oddCount: odd,
    ranges: [
      for (var index = 0; index < ranges.length; index += 1)
        LabeledCount(
          label: '${index * 20}-${index * 20 + 19}',
          count: ranges[index],
        ),
    ],
    sequences: topSequences,
  );
}

/// Tách chuỗi người dùng nhập thành bộ số 00–99 hợp lệ và phần sai.
NumberSetParse parseNumberSet(String raw) {
  final invalid = <String>[];
  final valid = <String>[];
  final pattern = RegExp(r'^\d{1,2}$');

  for (final value in raw.split(RegExp(r'[\s,;.\-]+'))) {
    if (value.isEmpty) continue;
    if (!pattern.hasMatch(value) || int.parse(value) > 99) {
      invalid.add(value);
      continue;
    }
    valid.add(value.padLeft(2, '0'));
  }

  final unique = <String>{...valid};
  return NumberSetParse(
    numbers: unique.toList(growable: false),
    invalid: invalid,
  );
}

/// Sinh bộ số ngẫu nhiên bằng nguồn ngẫu nhiên bảo mật của hệ điều hành.
///
/// Dùng rejection sampling để tránh sai lệch modulo giống bản web.
List<String> secureRandomNumbers(int amount, {math.Random? generator}) {
  final target = amount.clamp(1, 20);
  final random = generator ?? math.Random.secure();
  final selected = <int>{};

  while (selected.length < target) {
    // Lấy đủ 32 bit từ hai lần 16 bit để chạy giống nhau trên web và mobile.
    final sample =
        random.nextInt(1 << 16) * (1 << 16) + random.nextInt(1 << 16);
    if (sample < 4294967200) selected.add(sample % 100);
  }

  final sorted = selected.toList(growable: false)..sort();
  return [for (final value in sorted) value.toString().padLeft(2, '0')];
}

/// Kiểm định tệp CSV trước khi nhập: trùng ngày, sai định dạng, thiếu kỳ.
CsvValidation validateCsv(String text) {
  final lines = _contentLines(text);
  if (lines.isEmpty) {
    return const CsvValidation(
      validRows: 0,
      duplicateRows: 0,
      issues: [
        DataIssue(row: 1, level: DataIssueLevel.error, message: 'Tệp rỗng.'),
      ],
    );
  }

  final headers = lines.first
      .split(',')
      .map((value) => value.trim().toLowerCase())
      .toList(growable: false);
  final dateIndex = headers.indexWhere(_dateHeaderNames.contains);
  final issues = <DataIssue>[];
  final dates = <String>{};
  var validRows = 0;
  var duplicateRows = 0;

  if (dateIndex < 0) {
    issues.add(
      const DataIssue(
        row: 1,
        level: DataIssueLevel.error,
        message: 'Thiếu cột ngày (date/ngay/draw_date).',
      ),
    );
    return CsvValidation(
      validRows: validRows,
      duplicateRows: duplicateRows,
      issues: issues,
    );
  }
  if (headers.length < 2) {
    issues.add(
      const DataIssue(
        row: 1,
        level: DataIssueLevel.error,
        message: 'Cần ít nhất một cột kết quả.',
      ),
    );
  }

  for (var lineIndex = 1; lineIndex < lines.length; lineIndex += 1) {
    final row = lineIndex + 1;
    final cells = _splitCells(lines[lineIndex]);
    final date = dateIndex < cells.length ? cells[dateIndex] : '';

    if (!_isValidIsoDate(date)) {
      issues.add(
        DataIssue(
          row: row,
          level: DataIssueLevel.error,
          message: 'Ngày không đúng định dạng YYYY-MM-DD.',
        ),
      );
      continue;
    }
    if (dates.contains(date)) {
      duplicateRows += 1;
      issues.add(
        DataIssue(
          row: row,
          level: DataIssueLevel.warning,
          message: 'Kỳ quay $date bị trùng.',
        ),
      );
      continue;
    }

    var hasNumber = false;
    for (var index = 0; index < cells.length; index += 1) {
      if (index != dateIndex && _numberCellPattern.hasMatch(cells[index])) {
        hasNumber = true;
        break;
      }
    }
    if (!hasNumber) {
      issues.add(
        DataIssue(
          row: row,
          level: DataIssueLevel.error,
          message: 'Không tìm thấy kết quả số.',
        ),
      );
      continue;
    }

    dates.add(date);
    validRows += 1;
  }

  final sortedDates = dates.toList(growable: false)..sort();
  for (var index = 1; index < sortedDates.length; index += 1) {
    final missing =
        _daysBetween(sortedDates[index - 1], sortedDates[index]) - 1;
    if (missing > 0) {
      issues.add(
        DataIssue(
          row: 0,
          level: DataIssueLevel.warning,
          message:
              'Có thể thiếu $missing kỳ giữa ${sortedDates[index - 1]} và ${sortedDates[index]}.',
        ),
      );
    }
  }

  return CsvValidation(
    validRows: validRows,
    duplicateRows: duplicateRows,
    issues: issues,
  );
}

/// Chuyển nội dung CSV thành danh sách kỳ quay đã chuẩn hóa.
List<LotteryDraw> parseCsvDraws(String text, {Region region = Region.mienBac}) {
  final lines = _contentLines(text);
  if (lines.length < 2) return const [];
  final headers = lines.first
      .split(',')
      .map((value) => value.trim())
      .toList(growable: false);
  final dateIndex = headers.indexWhere(
    (value) => _dateHeaderNames.contains(value.toLowerCase()),
  );
  if (dateIndex < 0) return const [];

  final seen = <String>{};
  final draws = <LotteryDraw>[];
  final collectedAt = DateTime.now().toUtc().toIso8601String();

  for (var lineIndex = 1; lineIndex < lines.length; lineIndex += 1) {
    final cells = _splitCells(lines[lineIndex]);
    final date = dateIndex < cells.length ? cells[dateIndex] : '';
    if (!_isoDatePattern.hasMatch(date) || seen.contains(date)) continue;

    final results = <PrizeResult>[];
    for (var columnIndex = 0; columnIndex < cells.length; columnIndex += 1) {
      if (columnIndex == dateIndex) continue;
      final numbers = _integerCellPattern
          .allMatches(cells[columnIndex])
          .map((match) => match.group(0)!)
          .toList(growable: false);
      for (var position = 0; position < numbers.length; position += 1) {
        final header = columnIndex < headers.length ? headers[columnIndex] : '';
        results.add(
          PrizeResult(
            prize: header.isNotEmpty ? header : 'Giải $columnIndex',
            position: position + 1,
            value: numbers[position],
          ),
        );
      }
    }
    if (results.isEmpty) continue;

    seen.add(date);
    draws.add(
      LotteryDraw(
        id: 'csv-${region.label}-$date',
        drawCode: 'CSV-${region.label}-$date',
        lotteryType: LotteryType.traditional,
        date: date,
        drawnAt: '${date}T18:00:00+07:00',
        region: region,
        station: region.label,
        source: 'CSV do người dùng nhập',
        collectedAt: collectedAt,
        verification: Verification.pending,
        results: results,
      ),
    );
  }

  return draws;
}

/// Chuyển nội dung JSON thành kỳ quay; ném [FormatException] khi dữ liệu sai.
List<LotteryDraw> parseJsonDraws(String text, Region fallbackRegion) {
  final Object? payload;
  try {
    payload = jsonDecode(text);
  } on FormatException catch (error) {
    throw FormatException('JSON không hợp lệ: ${error.message}');
  }

  final List<Object?> records;
  if (payload is List) {
    records = payload;
  } else if (payload is Map && payload['records'] is List) {
    records = payload['records'] as List;
  } else {
    records = const [];
  }
  if (records.isEmpty) {
    throw const FormatException(
      'JSON cần là một mảng hoặc có thuộc tính records.',
    );
  }

  final seen = <String>{};
  final draws = <LotteryDraw>[];
  final collectedAt = DateTime.now().toUtc().toIso8601String();

  for (var index = 0; index < records.length; index += 1) {
    final raw = records[index];
    if (raw is! Map) {
      throw FormatException('Bản ghi ${index + 1} không hợp lệ.');
    }
    final record = raw;

    final dateSource =
        (record['date'] ?? record['draw_date'] ?? record['drawnAt'] ?? '')
            .toString();
    final date = dateSource.length > 10
        ? dateSource.substring(0, 10)
        : dateSource;
    if (!_isValidIsoDate(date)) {
      throw FormatException('Bản ghi ${index + 1}: ngày không hợp lệ.');
    }

    final drawCode =
        (record['drawCode'] ??
                record['draw_code'] ??
                'JSON-${fallbackRegion.label}-$date')
            .toString();
    if (seen.contains(drawCode)) {
      throw FormatException('Mã kỳ $drawCode bị trùng.');
    }
    seen.add(drawCode);

    final List<Object?> rawResults;
    if (record['results'] is List) {
      rawResults = record['results'] as List;
    } else if (record['prizes'] is List) {
      rawResults = record['prizes'] as List;
    } else {
      rawResults = const [];
    }

    final results = <PrizeResult>[];
    for (
      var resultIndex = 0;
      resultIndex < rawResults.length;
      resultIndex += 1
    ) {
      final item = rawResults[resultIndex];
      final result = item is Map ? item : const <String, Object?>{};
      final prizeValue = (result['value'] ?? result['number'] ?? '').toString();
      if (!_prizeValuePattern.hasMatch(prizeValue)) {
        throw FormatException(
          'Bản ghi ${index + 1}, kết quả ${resultIndex + 1}: số ngoài phạm vi.',
        );
      }
      results.add(
        PrizeResult(
          prize: (result['prize'] ?? 'Kết quả').toString(),
          position: _asInt(result['position']) ?? resultIndex + 1,
          value: prizeValue,
        ),
      );
    }
    if (results.isEmpty) {
      throw FormatException('Bản ghi ${index + 1}: thiếu danh sách kết quả.');
    }

    final regionLabel = record['region']?.toString();
    final region = Region.values.firstWhere(
      (item) => item.label == regionLabel,
      orElse: () => fallbackRegion,
    );

    draws.add(
      LotteryDraw(
        id: 'json-$drawCode',
        drawCode: drawCode,
        lotteryType: record['lotteryType'] == 'COMBINATION'
            ? LotteryType.combination
            : LotteryType.traditional,
        date: date,
        drawnAt: (record['drawnAt'] ?? '${date}T18:00:00+07:00').toString(),
        region: region,
        station: (record['station'] ?? region.label).toString(),
        source: (record['source'] ?? 'JSON do người dùng nhập').toString(),
        collectedAt: collectedAt,
        verification: Verification.pending,
        results: results,
      ),
    );
  }

  return draws;
}

const List<String> _dateHeaderNames = ['date', 'ngay', 'ngày', 'draw_date'];

final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _numberCellPattern = RegExp(r'\d{2,}');
final RegExp _integerCellPattern = RegExp(r'\d+');
final RegExp _prizeValuePattern = RegExp(r'^\d{2,6}$');

/// Kiểm tra ngày ISO hợp lệ thật sự (loại cả 2026-02-30).
bool _isValidIsoDate(String value) {
  if (!_isoDatePattern.hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  return _formatIsoDate(parsed) == value;
}

List<LabeledCount> _toLabeledCounts(List<int> counts) {
  return [
    for (var index = 0; index < counts.length; index += 1)
      LabeledCount(label: '$index', count: counts[index]),
  ];
}

/// Chỉ số ngày trong tuần theo quy ước JavaScript (`getDay`): 0 = chủ nhật.
int _dayIndexFor(String date) {
  final parts = date.split('-');
  if (parts.length != 3) return 0;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return 0;
  return DateTime.utc(year, month, day).weekday % 7;
}

String _formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Nhãn ngày dạng `dd-MM` tương đương `Intl.DateTimeFormat("vi-VN")`.
String _formatDayMonth(String date) {
  final parts = date.split('-');
  if (parts.length != 3) return date;
  return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
}

int _daysBetween(String from, String to) {
  final start = _asUtcDay(from);
  final end = _asUtcDay(to);
  if (start == null || end == null) return 1;
  return end.difference(start).inDays;
}

DateTime? _asUtcDay(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime.utc(year, month, day);
}

List<String> _contentLines(String text) {
  final withoutBom = text.startsWith('\uFEFF') ? text.substring(1) : text;
  return withoutBom
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
}

/// Tách ô CSV: cắt khoảng trắng và bỏ cặp nháy kép bao ngoài.
List<String> _splitCells(String line) {
  final cells = <String>[];
  for (final raw in line.split(',')) {
    var value = raw.trim();
    if (value.startsWith('"')) value = value.substring(1);
    if (value.endsWith('"')) value = value.substring(0, value.length - 1);
    cells.add(value);
  }
  return cells;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Sắp xếp ổn định giống `Array.prototype.sort` của JavaScript.
List<T> _stableSortBy<T>(List<T> items, int Function(T a, T b) compare) {
  final order = List<int>.generate(
    items.length,
    (index) => index,
    growable: false,
  );
  order.sort((a, b) {
    final result = compare(items[a], items[b]);
    return result != 0 ? result : a.compareTo(b);
  });
  return [for (final index in order) items[index]];
}
