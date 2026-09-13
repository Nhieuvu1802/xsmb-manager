/// Model lưu kết quả backtest (bảng `backtest_runs`).
library;

import '../../domain/lottery_domain.dart';

/// Kết quả walk-forward của một mô hình trong một cửa sổ đánh giá.
class BacktestWindowResult {
  const BacktestWindowResult({
    required this.model,
    required this.windowDays,
    required this.samples,
    required this.top1Hits,
    required this.top4Hits,
    required this.top10Hits,
    required this.top4BaselineHits,
    required this.top4RandomHits,
    required this.averageHitsAt4,
    required this.averageHitsAt10,
  });

  final String model;

  /// 0 nghĩa là "toàn bộ dữ liệu khả dụng".
  final int windowDays;
  final int samples;
  final int top1Hits;
  final int top4Hits;
  final int top10Hits;
  final int top4BaselineHits;
  final int top4RandomHits;
  final double averageHitsAt4;
  final double averageHitsAt10;

  double _rate(int hits) => samples == 0 ? 0 : hits / samples;

  double get top1HitRate => _rate(top1Hits);
  double get top4HitRate => _rate(top4Hits);
  double get top10HitRate => _rate(top10Hits);
  double get baselineTop4HitRate => _rate(top4BaselineHits);
  double get randomTop4HitRate => _rate(top4RandomHits);

  /// Chênh lệch Top 4 so với baseline tần suất đơn giản.
  double get edgeOverBaseline => top4HitRate - baselineTop4HitRate;

  /// Chênh lệch Top 4 so với chọn ngẫu nhiên.
  double get edgeOverRandom => top4HitRate - randomTop4HitRate;

  Map<String, Object?> toRow(String createdAt) => <String, Object?>{
    'created_at': createdAt,
    'model': model,
    'window_days': windowDays,
    'samples': samples,
    'top1_hits': top1Hits,
    'top4_hits': top4Hits,
    'top10_hits': top10Hits,
    'baseline_top4_hits': top4BaselineHits,
    'random_top4_hits': top4RandomHits,
    'avg_hits_at4': averageHitsAt4,
    'avg_hits_at10': averageHitsAt10,
  };

  factory BacktestWindowResult.fromRow(Map<String, Object?> row) =>
      BacktestWindowResult(
        model: (row['model'] ?? '').toString(),
        windowDays: (row['window_days'] as num?)?.toInt() ?? 0,
        samples: (row['samples'] as num?)?.toInt() ?? 0,
        top1Hits: (row['top1_hits'] as num?)?.toInt() ?? 0,
        top4Hits: (row['top4_hits'] as num?)?.toInt() ?? 0,
        top10Hits: (row['top10_hits'] as num?)?.toInt() ?? 0,
        top4BaselineHits: (row['baseline_top4_hits'] as num?)?.toInt() ?? 0,
        top4RandomHits: (row['random_top4_hits'] as num?)?.toInt() ?? 0,
        averageHitsAt4: (row['avg_hits_at4'] as num?)?.toDouble() ?? 0,
        averageHitsAt10: (row['avg_hits_at10'] as num?)?.toDouble() ?? 0,
      );
}

class BacktestRunRecord {
  const BacktestRunRecord({
    required this.region,
    required this.createdAt,
    required this.results,
    this.id,
    this.note,
  });

  final Region region;
  final String createdAt;
  final List<BacktestWindowResult> results;
  final int? id;
  final String? note;

  /// Mô hình có chênh lệch dương ổn định nhất (nếu có).
  BacktestWindowResult? get bestModel {
    if (results.isEmpty) return null;
    final sorted = [...results]
      ..sort((a, b) => b.edgeOverBaseline.compareTo(a.edgeOverBaseline));
    return sorted.first;
  }

  bool get beatsBaseline =>
      results.isNotEmpty && results.every((item) => item.edgeOverBaseline > 0);
}
