/// Model lưu bộ số đã sinh (bảng `generated_runs`, `generated_sets`).
///
/// Seed được lưu lại nên mọi bộ số trong lịch sử đều **tái lập được**: chạy
/// lại engine với cùng seed + cùng cấu hình là ra đúng bộ số cũ.
library;

import 'dart:convert';

import '../../domain/generator/number_generator.dart';
import '../../domain/lottery_domain.dart';
import 'draw_record.dart';

/// Một bộ số trong một lần sinh đã lưu.
class GeneratedSetRecord {
  const GeneratedSetRecord({
    required this.index,
    required this.numbers,
    required this.sum,
    this.special,
  });

  final int index;
  final List<String> numbers;
  final int? special;
  final int sum;

  int get size => numbers.length;

  Map<String, Object?> toRow(int runId) => <String, Object?>{
    'run_id': runId,
    'set_index': index,
    'numbers': numbers.join(','),
    'special': special,
    'sum': sum,
  };

  factory GeneratedSetRecord.fromRow(Map<String, Object?> row) =>
      GeneratedSetRecord(
        index: (row['set_index'] as num?)?.toInt() ?? 0,
        numbers: splitNumbers(row['numbers']),
        special: int.tryParse((row['special'] ?? '').toString()),
        sum: (row['sum'] as num?)?.toInt() ?? 0,
      );

  factory GeneratedSetRecord.fromDomain(GeneratedSet set) => GeneratedSetRecord(
    index: set.index,
    numbers: set.numbers,
    special: set.special == null ? null : int.tryParse(set.special!),
    sum: set.sum,
  );

  /// Dựng lại kiểu domain; `seed` để giữ nguyên truy vết nguồn sinh.
  GeneratedSet toDomain(int seed) => GeneratedSet(
    index: index,
    numbers: numbers,
    special: special?.toString().padLeft(2, '0'),
    sum: sum,
    seed: seed,
  );

  /// Tách cột `numbers` (CSV) thành danh sách 2 chữ số.
  static List<String> splitNumbers(Object? raw) => <String>[
    for (final part in (raw ?? '').toString().split(','))
      if (part.trim().isNotEmpty) part.trim().padLeft(2, '0'),
  ];
}

/// Một lần sinh số đã lưu.
class GeneratedRunRecord {
  const GeneratedRunRecord({
    required this.region,
    required this.createdAt,
    required this.model,
    required this.strategy,
    required this.settings,
    required this.seed,
    required this.sets,
    this.targetDate,
    this.note,
    this.id,
  });

  final Region region;
  final String createdAt;
  final String model;
  final GeneratorStrategy strategy;
  final GeneratorSettings settings;
  final int seed;
  final List<GeneratedSetRecord> sets;

  /// Ngày mục tiêu dùng cho chiến lược `weekday`.
  final String? targetDate;

  final String? note;
  final int? id;

  int get setCount => sets.length;

  DateTime? get generatedAt => DateTime.tryParse(createdAt);

  Map<String, Object?> toRow() => <String, Object?>{
    'region': region.code,
    'created_at': createdAt,
    'model': model,
    'strategy': strategy.name,
    'min_value': settings.min,
    'max_value': settings.max,
    'numbers_per_set': settings.numbersPerSet,
    'set_count': settings.setCount,
    'excluded_json': jsonEncode(settings.excluded),
    'sort_order': settings.sortOrder.name,
    'unique_within_set': settings.uniqueWithinSet ? 1 : 0,
    'unique_across_sets': settings.uniqueAcrossSets ? 1 : 0,
    'special_max': settings.specialMax,
    'seed': seed,
    'target_date': targetDate,
    'note': note,
  };

  /// Dựng lại bản ghi từ một dòng database (+ danh sách bộ số kèm theo).
  factory GeneratedRunRecord.fromRow(
    Map<String, Object?> row, {
    List<GeneratedSetRecord> sets = const <GeneratedSetRecord>[],
  }) => GeneratedRunRecord(
    id: (row['id'] as num?)?.toInt(),
    region: regionFromCode(row['region']?.toString()),
    createdAt: (row['created_at'] ?? '').toString(),
    model: (row['model'] ?? '').toString(),
    strategy: GeneratorStrategy.fromName(row['strategy']?.toString()),
    settings: GeneratorSettings(
      min: (row['min_value'] as num?)?.toInt() ?? 0,
      max: (row['max_value'] as num?)?.toInt() ?? 99,
      numbersPerSet: (row['numbers_per_set'] as num?)?.toInt() ?? 6,
      setCount: (row['set_count'] as num?)?.toInt() ?? 1,
      excluded: decodeExcluded(row['excluded_json']),
      sortOrder: GeneratorSortOrder.fromName(row['sort_order']?.toString()),
      uniqueWithinSet: ((row['unique_within_set'] as num?)?.toInt() ?? 1) != 0,
      uniqueAcrossSets:
          ((row['unique_across_sets'] as num?)?.toInt() ?? 1) != 0,
      specialMax: (row['special_max'] as num?)?.toInt(),
      seed: (row['seed'] as num?)?.toInt(),
    ),
    seed: (row['seed'] as num?)?.toInt() ?? 0,
    sets: sets,
    targetDate: row['target_date']?.toString(),
    note: row['note']?.toString(),
  );

  /// Dựng lại kết quả đầy đủ để đưa trở lại bảng tính số.
  ///
  /// Trọng số chỉ mang tính giải thích nên được tính lại từ [history] đang có
  /// trong máy (không truyền thì dùng lịch sử rỗng).
  GeneratorOutcome toOutcome({
    List<LotteryDraw> history = const <LotteryDraw>[],
  }) => GeneratorOutcome(
    strategy: strategy,
    settings: settings,
    seed: seed,
    sets: <GeneratedSet>[for (final set in sets) set.toDomain(seed)],
    weights: NumberWeights.fromHistory(
      history: history,
      strategy: strategy,
      targetDate: targetDate,
    ),
    generatedAt: generatedAt ?? DateTime.now(),
  );

  factory GeneratedRunRecord.fromOutcome({
    required Region region,
    required GeneratorOutcome outcome,
    String? targetDate,
    String? note,
  }) => GeneratedRunRecord(
    region: region,
    createdAt: outcome.generatedAt.toIso8601String(),
    model: GeneratorEngine.modelName,
    strategy: outcome.strategy,
    settings: outcome.settings,
    seed: outcome.seed,
    sets: <GeneratedSetRecord>[
      for (final set in outcome.sets) GeneratedSetRecord.fromDomain(set),
    ],
    targetDate: targetDate ?? outcome.targetDate,
    note: note,
  );

  /// Đọc cột `excluded_json`; dữ liệu hỏng thì coi như không loại trừ số nào.
  static List<int> decodeExcluded(Object? raw) {
    final text = (raw ?? '').toString();
    if (text.isEmpty) return const <int>[];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const <int>[];
      return <int>[
        for (final item in decoded)
          if (item is num) item.toInt(),
      ];
    } on FormatException {
      return const <int>[];
    }
  }
}
