/// Engine thống kê 00–99 (Phase 6) — tách hoàn toàn khỏi UI.
///
/// Mọi chỉ số ở đây là thống kê mô tả quá khứ: tần suất, độ trễ, độ ổn định và
/// xu hướng. Không chỉ số nào là "xác suất chắc thắng".
library;

import 'dart:math' as math;

import '../../logic/statistics.dart';
import '../lottery_domain.dart';

/// Cửa sổ số kỳ dùng cho các chỉ số rolling.
const List<int> kRollingWindows = <int>[10, 30, 60, 90];

/// Chỉ số của một số 00–99.
class NumberMetrics {
  const NumberMetrics({
    required this.number,
    required this.occurrences,
    required this.drawHits,
    required this.drawCount,
    required this.totalSlots,
    required this.windowHits,
    required this.windowRates,
    required this.gap,
    required this.averageGap,
    required this.gapStdDev,
    required this.momentum,
    required this.recency,
    required this.stability,
    required this.ewma,
    required this.trendShort,
    required this.trendMedium,
    required this.trendLong,
    required this.zScore,
  });

  /// Số 2 chữ số, ví dụ `07`.
  final String number;

  /// Tổng lượt xuất hiện (một kỳ có thể xuất hiện nhiều lần).
  final int occurrences;

  /// Số kỳ có xuất hiện ít nhất một lần.
  final int drawHits;

  final int drawCount;
  final int totalSlots;

  /// Số kỳ có xuất hiện trong từng cửa sổ `[10, 30, 60, 90]`.
  final Map<int, int> windowHits;

  /// Tỷ lệ kỳ có xuất hiện trong từng cửa sổ.
  final Map<int, double> windowRates;

  /// Số kỳ chưa xuất hiện tính tới kỳ gần nhất; `null` nếu chưa từng xuất hiện.
  final int? gap;

  /// Khoảng cách trung bình giữa hai lần xuất hiện liên tiếp.
  final double? averageGap;

  /// Độ lệch chuẩn của khoảng cách.
  final double gapStdDev;

  /// Xu hướng ngắn hạn: tỷ lệ 10 kỳ gần nhất trừ 10 kỳ trước đó (∈ [-1, 1]).
  final double momentum;

  /// Độ mới: `1 / (1 + gap)`, xuất hiện càng gần đây càng cao.
  final double recency;

  /// Độ ổn định: `1 / (1 + hệ số biến thiên khoảng cách)`.
  final double stability;

  /// Trung bình có trọng số hàm mũ (halflife 30 kỳ) của chỉ báo "có xuất hiện".
  final double ewma;

  /// Xu hướng 30 kỳ gần nhất: nửa sau trừ nửa đầu.
  final double trendShort;

  /// Xu hướng 90 kỳ gần nhất: nửa sau trừ nửa đầu.
  final double trendMedium;

  /// Xu hướng toàn bộ dữ liệu: nửa sau trừ nửa đầu.
  final double trendLong;

  /// Z-score so với kỳ vọng nhị thức `p = 0.01`.
  final double zScore;

  double get occurrenceRate => totalSlots == 0 ? 0 : occurrences / totalSlots;

  double get drawRate => drawCount == 0 ? 0 : drawHits / drawCount;

  /// Số kỳ chưa xuất hiện; dùng `drawCount + 1` cho số chưa từng xuất hiện.
  int get effectiveGap => gap ?? drawCount + 1;

  Map<String, double> toFeatures() => <String, double>{
    'window10': windowRates[10] ?? 0,
    'window30': windowRates[30] ?? 0,
    'window60': windowRates[60] ?? 0,
    'window90': windowRates[90] ?? 0,
    'gap': effectiveGap.toDouble(),
    'recency': recency,
    'momentum': momentum,
    'stability': stability,
    'ewma': ewma,
    'trendShort': trendShort,
    'trendMedium': trendMedium,
    'trendLong': trendLong,
    'zScore': zScore,
  };
}

/// Ảnh chụp thống kê của một tập kỳ quay.
class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.drawCount,
    required this.totalSlots,
    required this.metrics,
    this.label = 'Miền Bắc',
  });

  final int drawCount;
  final int totalSlots;
  final List<NumberMetrics> metrics;
  final String label;

  Map<String, NumberMetrics> get byNumber => <String, NumberMetrics>{
    for (final item in metrics) item.number: item,
  };

  NumberMetrics? lookup(String number) => byNumber[number];
}

/// Tính chỉ số cho cả 100 số 00–99.
///
/// `draws` có thể ở thứ tự bất kỳ; hàm tự sắp xếp theo ngày tăng dần.
StatisticsSnapshot analyseNumbers(
  List<LotteryDraw> draws, {
  String label = 'Miền Bắc',
}) {
  final ordered = [...draws]..sort((a, b) => a.date.compareTo(b.date));
  final drawCount = ordered.length;

  final hitsByNumber = <String, List<int>>{
    for (final number in kAllNumbers) number: <int>[],
  };
  final countsByNumber = <String, int>{
    for (final number in kAllNumbers) number: 0,
  };
  var totalSlots = 0;

  for (var index = 0; index < ordered.length; index += 1) {
    final seen = <String>{};
    for (final result in ordered[index].results) {
      final number = lastTwoDigits(result.value);
      totalSlots += 1;
      countsByNumber[number] = (countsByNumber[number] ?? 0) + 1;
      seen.add(number);
    }
    for (final number in seen) {
      hitsByNumber[number]!.add(index);
    }
  }

  final expected = totalSlots * 0.01;
  final deviation = math.sqrt(totalSlots * 0.01 * 0.99);

  return StatisticsSnapshot(
    drawCount: drawCount,
    totalSlots: totalSlots,
    label: label,
    metrics: <NumberMetrics>[
      for (final number in kAllNumbers)
        _metricsFor(
          number: number,
          hits: hitsByNumber[number]!,
          occurrences: countsByNumber[number] ?? 0,
          drawCount: drawCount,
          totalSlots: totalSlots,
          expected: expected,
          deviation: deviation,
        ),
    ],
  );
}

/// Lọc kỳ quay theo đài (dữ liệu XSMN có nhiều đài trong cùng một ngày).
List<LotteryDraw> filterByStation(List<LotteryDraw> draws, String station) =>
    draws.where((draw) => draw.station == station).toList(growable: false);

/// Danh sách đài có trong dữ liệu, sắp xếp theo tên.
List<String> stationsOf(List<LotteryDraw> draws) {
  final stations = <String>{for (final draw in draws) draw.station};
  return stations.toList()..sort();
}

NumberMetrics _metricsFor({
  required String number,
  required List<int> hits,
  required int occurrences,
  required int drawCount,
  required int totalSlots,
  required double expected,
  required double deviation,
}) {
  final lastIndex = hits.isEmpty ? null : hits.last;
  final gap = lastIndex == null ? null : drawCount - 1 - lastIndex;

  final gaps = <int>[
    for (var index = 1; index < hits.length; index += 1)
      hits[index] - hits[index - 1],
  ];
  final averageGap = gaps.isEmpty
      ? null
      : gaps.reduce((a, b) => a + b) / gaps.length;
  final gapStdDev = gaps.length < 2
      ? 0.0
      : math.sqrt(
          gaps
                  .map((item) => math.pow(item - averageGap!, 2).toDouble())
                  .reduce((a, b) => a + b) /
              gaps.length,
        );

  final windowHits = <int, int>{};
  final windowRates = <int, double>{};
  for (final window in kRollingWindows) {
    final from = math.max(0, drawCount - window);
    final span = drawCount - from;
    final count = hits.where((index) => index >= from).length;
    windowHits[window] = count;
    windowRates[window] = span == 0 ? 0 : count / span;
  }

  final momentum =
      (windowRates[10] ?? 0) -
      _rateBetween(hits, drawCount - 20, drawCount - 10);

  return NumberMetrics(
    number: number,
    occurrences: occurrences,
    drawHits: hits.length,
    drawCount: drawCount,
    totalSlots: totalSlots,
    windowHits: windowHits,
    windowRates: windowRates,
    gap: gap,
    averageGap: averageGap,
    gapStdDev: gapStdDev,
    momentum: momentum,
    recency: gap == null ? 0 : 1 / (1 + gap),
    stability: averageGap == null || averageGap == 0
        ? 0.5
        : 1 / (1 + gapStdDev / averageGap),
    ewma: _ewma(hits, drawCount, halflife: 30),
    trendShort: _trend(hits, drawCount, 30),
    trendMedium: _trend(hits, drawCount, 90),
    trendLong: _trend(hits, drawCount, drawCount),
    zScore: deviation == 0 ? 0 : (occurrences - expected) / deviation,
  );
}

double _rateBetween(List<int> hits, int from, int to) {
  final span = to - from;
  if (span <= 0) return 0;
  return hits.where((index) => index >= from && index < to).length / span;
}

/// Trung bình có trọng số hàm mũ của chỉ báo "có xuất hiện".
double _ewma(List<int> hits, int drawCount, {required int halflife}) {
  if (drawCount == 0) return 0;
  final lambda = 1 - math.pow(0.5, 1 / halflife).toDouble();
  final hitSet = hits.toSet();
  var value = 0.0;
  for (var index = 0; index < drawCount; index += 1) {
    final indicator = hitSet.contains(index) ? 1.0 : 0.0;
    value = lambda * indicator + (1 - lambda) * value;
  }
  return value;
}

/// Xu hướng "nửa sau trừ nửa đầu" trong `window` kỳ gần nhất.
double _trend(List<int> hits, int drawCount, int window) {
  if (drawCount < 4 || window < 4) return 0;
  final from = math.max(0, drawCount - window);
  final span = drawCount - from;
  final half = span ~/ 2;
  if (half == 0) return 0;
  final first =
      hits.where((index) => index >= from && index < from + half).length / half;
  final second =
      hits.where((index) => index >= from + half && index < drawCount).length /
      (span - half);
  return second - first;
}
