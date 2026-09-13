/// Model lưu kết quả xếp hạng (bảng `prediction_runs`, `prediction_results`).
library;

import '../../domain/lottery_domain.dart';
import 'draw_record.dart';

class PredictionEntryRecord {
  const PredictionEntryRecord({
    required this.number,
    required this.score,
    required this.rank,
    this.features = const <String, double>{},
  });

  final String number;
  final double score;
  final int rank;
  final Map<String, double> features;

  Map<String, Object?> toRow(int runId) => <String, Object?>{
    'run_id': runId,
    'number': number,
    'rank': rank,
    'score': score,
    'features_json': features.entries
        .map((entry) => '"${entry.key}":${entry.value}')
        .join(','),
  };

  factory PredictionEntryRecord.fromRow(Map<String, Object?> row) =>
      PredictionEntryRecord(
        number: (row['number'] ?? '').toString(),
        score: (row['score'] as num?)?.toDouble() ?? 0,
        rank: (row['rank'] as num?)?.toInt() ?? 0,
      );
}

class PredictionRunRecord {
  const PredictionRunRecord({
    required this.region,
    required this.createdAt,
    required this.model,
    required this.windowDays,
    required this.targetDate,
    required this.entries,
    this.id,
    this.note,
  });

  final Region region;
  final String createdAt;
  final String model;
  final int windowDays;
  final String targetDate;
  final List<PredictionEntryRecord> entries;
  final int? id;
  final String? note;

  Map<String, Object?> toRow() => <String, Object?>{
    'region': region.code,
    'created_at': createdAt,
    'model': model,
    'window_days': windowDays,
    'target_date': targetDate,
    'note': note,
  };
}
