/// Engine backtest walk-forward (Phase 8) — phần quan trọng nhất.
///
/// Với mỗi ngày D trong tập kiểm tra: chỉ dùng dữ liệu TRƯỚC ngày D để xếp
/// hạng, sau đó so với kết quả thật của ngày D. Không có dữ liệu tương lai lọt
/// vào feature của quá khứ. Kết quả được đối chiếu với hai baseline:
/// tần suất đơn giản và chọn ngẫu nhiên có seed (tái lập được).
library;

import 'dart:math' as math;

import '../../logic/statistics.dart';
import '../../data/models/backtest.dart';
import '../lottery_domain.dart';
import '../scoring/prediction_engine.dart';
import '../statistics/number_statistics.dart';

/// Tên các mô hình được đối chiếu trong backtest.
const String kScoreModel = PredictionEngine.modelName;
const String kFrequencyBaseline = 'baseline-frequency';
const String kRandomBaseline = 'baseline-random';

class BacktestConfig {
  const BacktestConfig({
    this.evaluationWindows = const <int>[30, 90, 180, 365, 0],
    this.minTrain = 30,
    this.trainWindow = 400,
    this.topK = const <int>[1, 4, 10],
    this.randomSeed = 20260913,
  });

  /// Các cửa sổ đánh giá tính theo số kỳ gần nhất; `0` = toàn bộ dữ liệu.
  final List<int> evaluationWindows;

  /// Số kỳ tối thiểu phải có trước ngày kiểm tra đầu tiên.
  final int minTrain;

  /// Số kỳ quá khứ tối đa dùng để tính feature (giới hạn thời gian chạy).
  final int trainWindow;

  final List<int> topK;
  final int randomSeed;

  List<String> validate() {
    final errors = <String>[];
    if (minTrain < 4) {
      errors.add('minTrain phải ≥ 4.');
    }
    if (trainWindow < minTrain) {
      errors.add('trainWindow phải ≥ minTrain.');
    }
    if (evaluationWindows.isEmpty) {
      errors.add('Cần ít nhất một cửa sổ đánh giá.');
    }
    if (topK.isEmpty) {
      errors.add('Cần ít nhất một giá trị K.');
    }
    return errors;
  }
}

class DailyEvaluation {
  const DailyEvaluation({
    required this.date,
    required this.scoreHitsAt1,
    required this.scoreHitsAt4,
    required this.scoreHitsAt10,
    required this.frequencyHitsAt4,
    required this.frequencyHitsAt10,
    required this.randomHitsAt4,
    required this.randomHitsAt10,
  });

  final String date;
  final int scoreHitsAt1;
  final int scoreHitsAt4;
  final int scoreHitsAt10;
  final int frequencyHitsAt4;
  final int frequencyHitsAt10;
  final int randomHitsAt4;
  final int randomHitsAt10;
}

class BacktestOutcome {
  const BacktestOutcome({
    required this.results,
    required this.daily,
    required this.model,
    required this.trainWindow,
    this.notes = const <String>[],
  });

  /// Mỗi dòng là một cặp (mô hình, cửa sổ đánh giá).
  final List<BacktestWindowResult> results;
  final List<DailyEvaluation> daily;
  final String model;
  final int trainWindow;
  final List<String> notes;

  bool get isEmpty => results.isEmpty;

  /// Mô hình có chênh lệch dương so với baseline tần suất ở MỌI cửa sổ hay không.
  bool get beatsBaselineEverywhere {
    final rows = results.where((item) => item.model == kScoreModel).toList();
    if (rows.isEmpty) {
      return false;
    }
    return rows.every((item) => item.edgeOverBaseline > 0);
  }

  /// Cảnh báo trung thực khi mô hình không vượt baseline.
  String get verdict {
    final rows = results.where((item) => item.model == kScoreModel).toList();
    if (rows.isEmpty) return 'Chưa đủ dữ liệu để kết luận.';
    if (rows.every((item) => item.edgeOverBaseline > 0)) {
      return 'Mô hình vượt baseline tần suất ở mọi cửa sổ đã kiểm tra.';
    }
    if (rows.any((item) => item.edgeOverBaseline > 0)) {
      return 'Mô hình chỉ vượt baseline ở một số cửa sổ; kết quả chưa ổn định.';
    }
    return 'Mô hình KHÔNG vượt baseline tần suất. Không nên dùng để tham khảo.';
  }
}

class BacktestEngine {
  const BacktestEngine._();

  /// Chạy walk-forward một lượt rồi cắt theo từng cửa sổ đánh giá.
  static BacktestOutcome run({
    required List<LotteryDraw> draws,
    BacktestConfig config = const BacktestConfig(),
    FeatureWeights weights = FeatureWeights.balanced,
  }) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      return BacktestOutcome(
        results: const <BacktestWindowResult>[],
        daily: const <DailyEvaluation>[],
        model: kScoreModel,
        trainWindow: config.trainWindow,
        notes: errors,
      );
    }

    final ordered = [...draws]..sort((a, b) => a.date.compareTo(b.date));
    if (ordered.length <= config.minTrain) {
      return BacktestOutcome(
        results: const <BacktestWindowResult>[],
        daily: const <DailyEvaluation>[],
        model: kScoreModel,
        trainWindow: config.trainWindow,
        notes: <String>[
          'Cần hơn ${config.minTrain} kỳ để backtest; hiện có ${ordered.length}.',
        ],
      );
    }

    final daily = <DailyEvaluation>[];
    for (var index = config.minTrain; index < ordered.length; index += 1) {
      final historyStart = math.max(0, index - config.trainWindow);
      final history = ordered.sublist(historyStart, index);
      final actual = ordered[index];
      final actualNumbers = <String>{
        for (final result in actual.results) lastTwoDigits(result.value),
      };

      final prediction = PredictionEngine.rank(
        snapshot: analyseNumbers(history),
        weights: weights,
      );
      final frequency = _frequencyRanking(history);
      final random = _randomRanking(actual.date, config.randomSeed);

      daily.add(
        DailyEvaluation(
          date: actual.date,
          scoreHitsAt1: _hitsIn(actualNumbers, prediction.ranked, 1),
          scoreHitsAt4: _hitsIn(actualNumbers, prediction.ranked, 4),
          scoreHitsAt10: _hitsIn(actualNumbers, prediction.ranked, 10),
          frequencyHitsAt4: _hitsIn(actualNumbers, frequency, 4),
          frequencyHitsAt10: _hitsIn(actualNumbers, frequency, 10),
          randomHitsAt4: _hitsIn(actualNumbers, random, 4),
          randomHitsAt10: _hitsIn(actualNumbers, random, 10),
        ),
      );
    }

    final results = <BacktestWindowResult>[];
    for (final window in config.evaluationWindows) {
      final sample = window <= 0
          ? daily
          : daily.sublist(math.max(0, daily.length - window));
      if (sample.isEmpty) continue;
      results.addAll(_aggregate(sample, window));
    }

    return BacktestOutcome(
      results: results,
      daily: daily,
      model: kScoreModel,
      trainWindow: config.trainWindow,
      notes: <String>[
        'Kiểm tra ${daily.length} kỳ; mỗi kỳ chỉ dùng tối đa ${config.trainWindow} kỳ trước đó.',
        'Baseline tần suất dùng toàn bộ lịch sử có trước ngày kiểm tra.',
      ],
    );
  }

  static List<BacktestWindowResult> _aggregate(
    List<DailyEvaluation> sample,
    int window,
  ) {
    var scoreTop1 = 0;
    var scoreTop4 = 0;
    var scoreTop10 = 0;
    var frequencyTop4 = 0;
    var frequencyTop10 = 0;
    var randomTop4 = 0;
    var randomTop10 = 0;
    var scoreHits4 = 0.0;
    var scoreHits10 = 0.0;

    for (final day in sample) {
      if (day.scoreHitsAt1 > 0) scoreTop1 += 1;
      if (day.scoreHitsAt4 > 0) scoreTop4 += 1;
      if (day.scoreHitsAt10 > 0) scoreTop10 += 1;
      if (day.frequencyHitsAt4 > 0) frequencyTop4 += 1;
      if (day.frequencyHitsAt10 > 0) frequencyTop10 += 1;
      if (day.randomHitsAt4 > 0) randomTop4 += 1;
      if (day.randomHitsAt10 > 0) randomTop10 += 1;
      scoreHits4 += day.scoreHitsAt4;
      scoreHits10 += day.scoreHitsAt10;
    }

    return <BacktestWindowResult>[
      BacktestWindowResult(
        model: kScoreModel,
        windowDays: window,
        samples: sample.length,
        top1Hits: scoreTop1,
        top4Hits: scoreTop4,
        top10Hits: scoreTop10,
        top4BaselineHits: frequencyTop4,
        top4RandomHits: randomTop4,
        averageHitsAt4: scoreHits4 / sample.length,
        averageHitsAt10: scoreHits10 / sample.length,
      ),
      BacktestWindowResult(
        model: kFrequencyBaseline,
        windowDays: window,
        samples: sample.length,
        top1Hits: frequencyTop4,
        top4Hits: frequencyTop4,
        top10Hits: frequencyTop10,
        top4BaselineHits: frequencyTop4,
        top4RandomHits: randomTop4,
        averageHitsAt4: frequencyTop4 / sample.length,
        averageHitsAt10: frequencyTop10 / sample.length,
      ),
      BacktestWindowResult(
        model: kRandomBaseline,
        windowDays: window,
        samples: sample.length,
        top1Hits: randomTop4,
        top4Hits: randomTop4,
        top10Hits: randomTop10,
        top4BaselineHits: frequencyTop4,
        top4RandomHits: randomTop4,
        averageHitsAt4: randomTop4 / sample.length,
        averageHitsAt10: randomTop10 / sample.length,
      ),
    ];
  }

  static int _hitsIn(Set<String> actual, List<ScoredNumber> ranked, int k) {
    var hits = 0;
    for (final item in ranked.take(k)) {
      if (actual.contains(item.number)) hits += 1;
    }
    return hits;
  }

  /// Baseline tần suất đơn giản: xếp hạng theo số lần xuất hiện trong lịch sử.
  static List<ScoredNumber> _frequencyRanking(List<LotteryDraw> history) {
    final snapshot = analyseNumbers(history);
    final sorted = [...snapshot.metrics]
      ..sort((a, b) {
        final byCount = b.occurrences.compareTo(a.occurrences);
        return byCount != 0 ? byCount : a.number.compareTo(b.number);
      });
    return <ScoredNumber>[
      for (var index = 0; index < sorted.length; index += 1)
        ScoredNumber(
          number: sorted[index].number,
          score: sorted[index].occurrenceRate * 100,
          rank: index + 1,
          features: const <String, double>{},
          metrics: sorted[index],
        ),
    ];
  }

  /// Baseline ngẫu nhiên có seed theo ngày → chạy lại cho kết quả giống nhau.
  static List<ScoredNumber> _randomRanking(String date, int seed) {
    final random = math.Random(seed + _hashDate(date));
    final pool = <String>[...kAllNumbers]..shuffle(random);
    return <ScoredNumber>[
      for (var index = 0; index < pool.length; index += 1)
        ScoredNumber(
          number: pool[index],
          score: 0,
          rank: index + 1,
          features: const <String, double>{},
          metrics: _placeholderMetrics(pool[index]),
        ),
    ];
  }

  static NumberMetrics _placeholderMetrics(String number) => NumberMetrics(
    number: number,
    occurrences: 0,
    drawHits: 0,
    drawCount: 0,
    totalSlots: 0,
    windowHits: const <int, int>{},
    windowRates: const <int, double>{},
    gap: null,
    averageGap: null,
    gapStdDev: 0,
    momentum: 0,
    recency: 0,
    stability: 0,
    ewma: 0,
    trendShort: 0,
    trendMedium: 0,
    trendLong: 0,
    zScore: 0,
  );

  static int _hashDate(String date) {
    var hash = 0;
    for (final code in date.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }
}
