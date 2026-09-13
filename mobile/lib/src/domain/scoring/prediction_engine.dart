/// Engine xếp hạng 00–99 (Phase 7) — trả về **Điểm thống kê** 0–100.
///
/// Điểm này là thứ hạng tương đối giữa các số dựa trên feature đã chuẩn hoá,
/// KHÔNG phải xác suất trúng. Muốn nói tới xác suất thì phải qua backtest
/// calibration (xem `domain/backtest/backtest_engine.dart`).
library;

import 'dart:math' as math;

import '../statistics/number_statistics.dart';

/// Trọng số feature; tổng được chuẩn hoá về 1 trước khi tính điểm.
class FeatureWeights {
  const FeatureWeights({
    this.frequencyShort = 0.18,
    this.frequencyMedium = 0.14,
    this.frequencyLong = 0.10,
    this.recency = 0.12,
    this.gapScore = 0.14,
    this.trendScore = 0.10,
    this.momentumScore = 0.10,
    this.stabilityScore = 0.06,
    this.ewmaScore = 0.06,
  });

  final double frequencyShort;
  final double frequencyMedium;
  final double frequencyLong;
  final double recency;
  final double gapScore;
  final double trendScore;
  final double momentumScore;
  final double stabilityScore;
  final double ewmaScore;

  /// Bộ trọng số mặc định dùng cho mọi lần xếp hạng.
  static const FeatureWeights balanced = FeatureWeights();

  double get total =>
      frequencyShort +
      frequencyMedium +
      frequencyLong +
      recency +
      gapScore +
      trendScore +
      momentumScore +
      stabilityScore +
      ewmaScore;

  Map<String, double> toMap() => <String, double>{
    'frequencyShort': frequencyShort,
    'frequencyMedium': frequencyMedium,
    'frequencyLong': frequencyLong,
    'recency': recency,
    'gapScore': gapScore,
    'trendScore': trendScore,
    'momentumScore': momentumScore,
    'stabilityScore': stabilityScore,
    'ewmaScore': ewmaScore,
  };

  FeatureWeights normalized() {
    final sum = total;
    if (sum <= 0) return balanced;
    return FeatureWeights(
      frequencyShort: frequencyShort / sum,
      frequencyMedium: frequencyMedium / sum,
      frequencyLong: frequencyLong / sum,
      recency: recency / sum,
      gapScore: gapScore / sum,
      trendScore: trendScore / sum,
      momentumScore: momentumScore / sum,
      stabilityScore: stabilityScore / sum,
      ewmaScore: ewmaScore / sum,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    for (final entry in toMap().entries) {
      if (entry.value < 0) errors.add('${entry.key} không được âm.');
    }
    if (total <= 0) errors.add('Tổng trọng số phải lớn hơn 0.');
    return errors;
  }
}

/// Một số đã được chấm điểm.
class ScoredNumber {
  const ScoredNumber({
    required this.number,
    required this.score,
    required this.rank,
    required this.features,
    required this.metrics,
  });

  final String number;

  /// Điểm thống kê 0–100 (thứ hạng tương đối, không phải xác suất).
  final double score;
  final int rank;

  /// Feature đã chuẩn hoá về [0, 1].
  final Map<String, double> features;
  final NumberMetrics metrics;

  /// Ba feature đóng góp nhiều nhất, dùng để giải thích trên UI.
  List<String> get topDrivers {
    final entries = features.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return <String>[
      for (final entry in entries.take(3))
        '${entry.key} ${entry.value.toStringAsFixed(2)}',
    ];
  }
}

class PredictionResult {
  const PredictionResult({
    required this.ranked,
    required this.weights,
    required this.model,
    required this.windowDays,
    required this.createdAt,
    this.regionLabel = 'Miền Bắc',
    this.targetDate = '',
  });

  /// Cả 100 số, điểm giảm dần.
  final List<ScoredNumber> ranked;
  final FeatureWeights weights;
  final String model;
  final int windowDays;
  final DateTime createdAt;
  final String regionLabel;
  final String targetDate;

  List<ScoredNumber> top(int count) =>
      ranked.take(count).toList(growable: false);

  List<ScoredNumber> get top4 => top(4);

  List<ScoredNumber> get top10 => top(10);

  ScoredNumber? byNumber(String number) {
    for (final item in ranked) {
      if (item.number == number) return item;
    }
    return null;
  }

  /// Cảnh báo bắt buộc hiển thị kèm bảng xếp hạng.
  static const String disclaimer =
      'Điểm thống kê là thứ hạng tương đối từ dữ liệu quá khứ, không phải xác '
      'suất trúng và không bảo đảm kết quả kỳ tới.';
}

class PredictionEngine {
  const PredictionEngine._();

  static const String modelName = 'statistical-score-v1';

  /// Xếp hạng 00–99 theo [weights] (đã chuẩn hoá nội bộ).
  static PredictionResult rank({
    required StatisticsSnapshot snapshot,
    FeatureWeights weights = FeatureWeights.balanced,
    String regionLabel = 'Miền Bắc',
    String targetDate = '',
    DateTime? createdAt,
  }) {
    final effective = weights.normalized();
    final metrics = snapshot.metrics;

    final gapMin = metrics
        .map((item) => item.effectiveGap.toDouble())
        .reduce(math.min);
    final gapMax = metrics
        .map((item) => item.effectiveGap.toDouble())
        .reduce(math.max);
    final trendValues = <double>[
      for (final item in metrics) item.trendMedium + item.trendShort,
    ];
    final trendMin = trendValues.reduce(math.min);
    final trendMax = trendValues.reduce(math.max);
    final momentumValues = <double>[for (final item in metrics) item.momentum];
    final momentumMin = momentumValues.reduce(math.min);
    final momentumMax = momentumValues.reduce(math.max);
    final ewmaValues = <double>[for (final item in metrics) item.ewma];
    final ewmaMin = ewmaValues.reduce(math.min);
    final ewmaMax = ewmaValues.reduce(math.max);

    final scored = <ScoredNumber>[
      for (final item in metrics)
        _score(
          metrics: item,
          weights: effective,
          features: <String, double>{
            'frequencyShort': item.windowRates[10] ?? 0,
            'frequencyMedium': item.windowRates[30] ?? 0,
            'frequencyLong': item.windowRates[90] ?? 0,
            'recency': item.recency,
            'gapScore': _normalize(
              item.effectiveGap.toDouble(),
              gapMin,
              gapMax,
            ),
            'trendScore': _normalize(
              item.trendMedium + item.trendShort,
              trendMin,
              trendMax,
            ),
            'momentumScore': _normalize(
              item.momentum,
              momentumMin,
              momentumMax,
            ),
            'stabilityScore': item.stability,
            'ewmaScore': _normalize(item.ewma, ewmaMin, ewmaMax),
          },
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return PredictionResult(
      ranked: <ScoredNumber>[
        for (var index = 0; index < scored.length; index += 1)
          ScoredNumber(
            number: scored[index].number,
            score: scored[index].score,
            rank: index + 1,
            features: scored[index].features,
            metrics: scored[index].metrics,
          ),
      ],
      weights: effective,
      model: modelName,
      windowDays: snapshot.drawCount,
      createdAt: createdAt ?? DateTime.now(),
      regionLabel: regionLabel,
      targetDate: targetDate,
    );
  }

  static ScoredNumber _score({
    required NumberMetrics metrics,
    required FeatureWeights weights,
    required Map<String, double> features,
  }) {
    final weightMap = weights.toMap();
    var total = 0.0;
    for (final entry in features.entries) {
      total += (weightMap[entry.key] ?? 0) * entry.value.clamp(0.0, 1.0);
    }
    return ScoredNumber(
      number: metrics.number,
      score: double.parse((total * 100).toStringAsFixed(2)),
      rank: 0,
      features: features,
      metrics: metrics,
    );
  }

  static double _normalize(double value, double min, double max) {
    if (max <= min) return 0.5;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}
