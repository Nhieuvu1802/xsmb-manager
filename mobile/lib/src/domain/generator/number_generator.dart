/// Bộ tính số 00–99: sinh bộ số **có kiểm soát** rồi đối chiếu lịch sử.
///
/// Mô hình lấy từ repo tham chiếu `Random-Number-Generator` (Android):
/// `getNumbers(min, max, quantity, noDupes, excluded)`, `RNGSettings`
/// (min/max/số lượng/loại trừ/sắp xếp/tổng), nhiều "vé" mỗi lần bấm và một
/// bóng *special* chọn riêng; mọi bộ sinh ra đều được lưu vào lịch sử.
///
/// Khác biệt có chủ đích: nguồn ngẫu nhiên ở đây là **seed tái lập được**
/// ([Mulberry32]) nên cùng seed + cùng lịch sử ⇒ cùng bộ số (kiểm thử được, và
/// người dùng có thể chia sẻ seed). Trọng số không phải hằng số mà lấy từ kho
/// số/lịch sử ([LottoArchive], [NumberWeights]) — phần "kết hợp lịch sử".
///
/// Toàn bộ chỉ là thống kê mô tả quá khứ: **không** phải xác suất trúng.
library;

import 'dart:math' as math;

import '../../logic/seeded_random.dart';
import '../../logic/statistics.dart';
import '../archive/lotto_archive.dart';
import '../lottery_domain.dart';
import '../statistics/number_statistics.dart';

/// Chiến lược chọn số — quyết định trọng số của từng số 00–99.
enum GeneratorStrategy {
  uniform(
    'Ngẫu nhiên đều',
    'Mọi số trong khoảng có trọng số bằng nhau (rút thăm thuần tuý).',
  ),
  hot(
    'Theo tần suất',
    'Ưu tiên số xuất hiện nhiều trong kho số (nhóm "nóng").',
  ),
  cold('Theo gan', 'Ưu tiên số lâu chưa xuất hiện (nhóm "lạnh"/gan dài).'),
  balanced(
    'Cân bằng',
    'Kết hợp tần suất 30 kỳ, độ mới và xu hướng của engine 00–99.',
  ),
  weekday('Theo thứ', 'Ưu tiên số hay về đúng thứ của ngày mục tiêu.');

  const GeneratorStrategy(this.label, this.description);

  final String label;
  final String description;

  /// Đọc lại chiến lược từ tên lưu trong database; mặc định `balanced`.
  static GeneratorStrategy fromName(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final strategy in GeneratorStrategy.values) {
      if (strategy.name == normalized) return strategy;
    }
    return GeneratorStrategy.balanced;
  }
}

/// Cách sắp xếp số trong một bộ — tương đương `SortType` của app RNG.
enum GeneratorSortOrder {
  none('Không sắp xếp'),
  ascending('Tăng dần'),
  descending('Giảm dần');

  const GeneratorSortOrder(this.label);

  final String label;

  /// Đọc lại cách sắp xếp từ tên lưu trong database; mặc định `ascending`.
  static GeneratorSortOrder fromName(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final order in GeneratorSortOrder.values) {
      if (order.name == normalized) return order;
    }
    return GeneratorSortOrder.ascending;
  }
}

/// Cấu hình một lần sinh số (tương đương `RNGSettings` của app RNG).
class GeneratorSettings {
  const GeneratorSettings({
    this.min = 0,
    this.max = 99,
    this.numbersPerSet = 6,
    this.setCount = 3,
    this.excluded = const <int>[],
    this.sortOrder = GeneratorSortOrder.ascending,
    this.uniqueWithinSet = true,
    this.uniqueAcrossSets = true,
    this.specialMax,
    this.seed,
  });

  /// Khoảng số được rút (mặc định 00–99 — đúng dải 2 chữ số của XSMB/XSMN).
  final int min;
  final int max;

  /// Số con số trong mỗi bộ.
  final int numbersPerSet;

  /// Số bộ sinh ra trong một lần bấm (app RNG in nhiều "vé" mỗi lần sinh).
  final int setCount;

  /// Số bị loại trừ (khoá "excluded numbers" của app RNG).
  final List<int> excluded;

  final GeneratorSortOrder sortOrder;

  /// Không cho trùng số trong cùng một bộ (`noDupes` của app RNG).
  final bool uniqueWithinSet;

  /// Không cho hai bộ trùng nhau trong cùng một lần sinh.
  final bool uniqueAcrossSets;

  /// Nếu khác `null`: chọn thêm 1 "số đặc biệt" trong `1..specialMax`
  /// (giống bóng special của Powerball/Mega Millions).
  final int? specialMax;

  /// Seed cố định để tái lập kết quả; `null` ⇒ mỗi lần sinh một seed mới.
  final int? seed;

  /// Số trong khoảng còn dùng được sau khi loại trừ.
  int get availableCount {
    var count = 0;
    for (var value = min; value <= max; value += 1) {
      if (!excluded.contains(value)) count += 1;
    }
    return count;
  }

  GeneratorSettings copyWith({
    int? min,
    int? max,
    int? numbersPerSet,
    int? setCount,
    List<int>? excluded,
    GeneratorSortOrder? sortOrder,
    bool? uniqueWithinSet,
    bool? uniqueAcrossSets,
    int? specialMax,
    bool clearSpecialMax = false,
    int? seed,
    bool clearSeed = false,
  }) => GeneratorSettings(
    min: min ?? this.min,
    max: max ?? this.max,
    numbersPerSet: numbersPerSet ?? this.numbersPerSet,
    setCount: setCount ?? this.setCount,
    excluded: excluded ?? this.excluded,
    sortOrder: sortOrder ?? this.sortOrder,
    uniqueWithinSet: uniqueWithinSet ?? this.uniqueWithinSet,
    uniqueAcrossSets: uniqueAcrossSets ?? this.uniqueAcrossSets,
    specialMax: clearSpecialMax ? null : (specialMax ?? this.specialMax),
    seed: clearSeed ? null : (seed ?? this.seed),
  );

  /// Danh sách lỗi cấu hình (rỗng nghĩa là sinh được).
  List<String> validate() {
    final errors = <String>[];
    if (min < 0 || max > 99 || min > max) {
      errors.add('Khoảng số phải nằm trong 00–99 và min ≤ max.');
      return errors;
    }
    if (excluded.any((value) => value < min || value > max)) {
      errors.add('Số loại trừ phải nằm trong khoảng đang chọn.');
    }
    final available = availableCount;
    if (numbersPerSet < 1) {
      errors.add('Mỗi bộ cần ít nhất 1 số.');
    } else if (numbersPerSet > available) {
      errors.add('Khoảng đang chọn chỉ còn $available số.');
    }
    if (setCount < 1 || setCount > 50) {
      errors.add('Số bộ mỗi lần sinh phải từ 1 đến 50.');
    }
    final special = specialMax;
    if (special != null && (special < 1 || special > 99)) {
      errors.add('Số đặc biệt phải nằm trong 01–99.');
    }
    if (uniqueWithinSet &&
        uniqueAcrossSets &&
        combinations(available, numbersPerSet) < setCount) {
      errors.add('Không đủ tổ hợp để tạo $setCount bộ khác nhau.');
    }
    return errors;
  }
}

/// Trọng số rút thăm cho từng số 00–99 theo một chiến lược.
///
/// Đây là chỗ "kết hợp lịch sử": `hot`/`cold` lấy từ kho số
/// ([LottoArchive]) — tương đương `count(value)` trong ví dụ R của
/// `LottoNumberArchive`; `weekday` đếm theo thứ của ngày mục tiêu; `balanced`
/// dùng chỉ số rolling của engine 00–99 ([analyseNumbers]).
class NumberWeights {
  const NumberWeights({
    required this.strategy,
    required this.weights,
    required this.source,
    this.targetWeekday,
  });

  final GeneratorStrategy strategy;

  /// Trọng số (không âm) của từng số 2 chữ số.
  final Map<String, double> weights;

  /// Mô tả ngắn nguồn trọng số, hiển thị trên UI để minh bạch cách tính.
  final String source;

  /// Thứ của ngày mục tiêu khi dùng chiến lược `weekday`.
  final String? targetWeekday;

  double weightOf(String number) => weights[number] ?? 0;

  double get totalWeight =>
      weights.values.fold(0.0, (total, value) => total + value);

  /// Các số có trọng số cao nhất — hữu ích cho phần giải thích trên UI.
  List<String> topNumbers([int count = 5]) {
    final entries = weights.entries.toList()
      ..sort((a, b) {
        final byWeight = b.value.compareTo(a.value);
        return byWeight != 0 ? byWeight : a.key.compareTo(b.key);
      });
    return <String>[for (final entry in entries.take(count)) entry.key];
  }

  /// Dựng trọng số từ lịch sử; tự tạo kho số khi không được truyền vào.
  static NumberWeights fromHistory({
    required List<LotteryDraw> history,
    required GeneratorStrategy strategy,
    LottoArchive? archive,
    StatisticsSnapshot? snapshot,
    String? targetDate,
  }) {
    final table = archive != null && !archive.isEmpty
        ? archive
        : LottoArchive.fromDraws(history);
    final draws = math.max(table.drawCount, 1);

    switch (strategy) {
      case GeneratorStrategy.uniform:
        return NumberWeights(
          strategy: strategy,
          weights: <String, double>{for (final n in kAllNumbers) n: 1},
          source: 'Rút đều 00–99',
        );
      case GeneratorStrategy.hot:
        final frequency = table.frequencyTable();
        return NumberWeights(
          strategy: strategy,
          weights: <String, double>{
            for (final n in kAllNumbers) n: 0.2 + (frequency[n] ?? 0) / draws,
          },
          source:
              'Tần suất trong ${table.drawCount} kỳ '
              '(${table.entries.length} lượt về)',
        );
      case GeneratorStrategy.cold:
        return NumberWeights(
          strategy: strategy,
          weights: <String, double>{
            for (final n in kAllNumbers)
              n: 0.2 + table.drawsSinceLastSeen(n) / draws,
          },
          source: 'Gan (số kỳ chưa về) trong ${table.drawCount} kỳ',
        );
      case GeneratorStrategy.balanced:
        final metrics = snapshot ?? analyseNumbers(history);
        final drawCount = math.max(metrics.drawCount, 1);
        return NumberWeights(
          strategy: strategy,
          weights: <String, double>{
            for (final NumberMetrics metric in metrics.metrics)
              metric.number:
                  0.05 +
                  0.45 * (metric.windowRates[30] ?? 0) +
                  0.25 * metric.recency +
                  0.30 * (metric.effectiveGap / drawCount).clamp(0.0, 1.0),
          },
          source: 'Cân bằng: 30 kỳ (0,45) + độ mới (0,25) + gan (0,30)',
        );
      case GeneratorStrategy.weekday:
        final weekday = _weekdayOf(targetDate, history);
        final day = weekday ?? '';
        final hasWeekday =
            weekday != null &&
            table.byWeekday().any(
              (row) => row.label == weekday && row.count > 0,
            );
        if (!hasWeekday) {
          final frequency = table.frequencyTable();
          return NumberWeights(
            strategy: strategy,
            weights: <String, double>{
              for (final n in kAllNumbers) n: 0.2 + (frequency[n] ?? 0),
            },
            source: 'Không có kỳ đúng thứ — dùng tần suất toàn kho',
            targetWeekday: weekday,
          );
        }
        return NumberWeights(
          strategy: strategy,
          weights: <String, double>{
            for (final n in kAllNumbers)
              n: 0.2 + (table.numberByWeekday(n)[day] ?? 0),
          },
          source: 'Số hay về vào $day',
          targetWeekday: day,
        );
    }
  }

  static String? _weekdayOf(String? targetDate, List<LotteryDraw> history) {
    final fromTarget = weekdayLabelOf(targetDate ?? '');
    if (fromTarget != null) return fromTarget;
    if (history.isEmpty) return null;
    final latest = history
        .map((draw) => draw.date)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    return weekdayLabelOf(latest);
  }
}

/// Một bộ số đã sinh (một "vé" trong app RNG).
class GeneratedSet {
  const GeneratedSet({
    required this.index,
    required this.numbers,
    required this.sum,
    required this.seed,
    this.special,
  });

  final int index;
  final List<String> numbers;

  /// "Số đặc biệt" chọn riêng trong `1..specialMax`; `null` nếu tắt.
  final String? special;

  final int sum;
  final int seed;

  String get display => numbers.join(' · ');

  String get csv => numbers.join(',');

  String get text => special == null ? display : '$display | $special';
}

/// Kết quả một lần sinh số, kèm cách tính để UI giải thích minh bạch.
class GeneratorOutcome {
  const GeneratorOutcome({
    required this.strategy,
    required this.settings,
    required this.seed,
    required this.sets,
    required this.weights,
    required this.generatedAt,
    this.targetDate,
  });

  final GeneratorStrategy strategy;
  final GeneratorSettings settings;
  final int seed;
  final List<GeneratedSet> sets;
  final NumberWeights weights;
  final DateTime generatedAt;

  /// Ngày mục tiêu đã dùng (chỉ có nghĩa với chiến lược `weekday`).
  final String? targetDate;

  /// Câu cảnh báo bắt buộc hiển thị: đây không phải dự đoán chắc thắng.
  static const String disclaimer =
      'Bộ số sinh ra chỉ dựa trên thống kê quá khứ nên không phải xác suất '
      'trúng và không bảo đảm kết quả tương lai.';

  String get summary =>
      '${sets.length} bộ · ${settings.numbersPerSet} số/bộ · '
      '${strategy.label} · seed $seed';

  /// Toàn bộ số của các bộ (đã gộp, giữ thứ tự) — dùng khi lưu lịch sử.
  List<String> get flatNumbers => <String>[
    for (final set in sets) ...set.numbers,
  ];
}

/// Bộ sinh số dựa trên lịch sử, tất định theo seed.
class GeneratorEngine {
  const GeneratorEngine._();

  /// Tên model lưu kèm mỗi bộ số để truy vết cách tính.
  static const String modelName = 'history-number-generator-v1';

  /// Số lần thử lại tối đa khi cần các bộ khác nhau.
  static const int maxDedupeAttempts = 64;

  /// Seed ngẫu nhiên mới (ưu tiên nguồn ngẫu nhiên bảo mật của hệ điều hành).
  static int randomSeed([math.Random? random]) {
    final source = random ?? _secureOrFallback();
    return source.nextInt(1 << 30);
  }

  static math.Random _secureOrFallback() {
    try {
      return math.Random.secure();
    } catch (_) {
      return math.Random();
    }
  }

  /// Sinh bộ số theo [strategy] và [settings].
  ///
  /// Ném [ArgumentError] khi cấu hình sai — UI nên gọi `settings.validate()`
  /// trước để hiện thông báo thay vì bắt lỗi.
  static GeneratorOutcome generate({
    required List<LotteryDraw> history,
    GeneratorStrategy strategy = GeneratorStrategy.balanced,
    GeneratorSettings settings = const GeneratorSettings(),
    String? targetDate,
    LottoArchive? archive,
    StatisticsSnapshot? snapshot,
    int? seed,
    math.Random? randomSource,
  }) {
    final errors = settings.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join(' '));
    }

    final effectiveSeed = seed ?? settings.seed ?? randomSeed(randomSource);
    final weights = NumberWeights.fromHistory(
      history: history,
      strategy: strategy,
      archive: archive,
      snapshot: snapshot,
      targetDate: targetDate,
    );
    final pool = <String>[
      for (var value = settings.min; value <= settings.max; value += 1)
        if (!settings.excluded.contains(value))
          value.toString().padLeft(2, '0'),
    ];

    final random = Mulberry32(effectiveSeed);
    final seen = <String>{};
    final sets = <GeneratedSet>[];
    for (var index = 0; index < settings.setCount; index += 1) {
      var numbers = <String>[];
      for (var attempt = 0; attempt < maxDedupeAttempts; attempt += 1) {
        numbers = settings.uniqueWithinSet
            ? _pickWithoutReplacement(
                pool,
                weights,
                settings.numbersPerSet,
                random,
              )
            : _pickWithReplacement(
                pool,
                weights,
                settings.numbersPerSet,
                random,
              );
        numbers = _applySort(numbers, settings.sortOrder);
        if (!settings.uniqueAcrossSets) break;
        if (seen.add(numbers.join('-'))) break;
      }
      final sum = numbers.fold<int>(0, (total, n) => total + int.parse(n));
      final specialMax = settings.specialMax;
      final special = specialMax == null
          ? null
          : (1 + (random.next() * specialMax).floor()).toString().padLeft(
              2,
              '0',
            );
      sets.add(
        GeneratedSet(
          index: index + 1,
          numbers: List<String>.unmodifiable(numbers),
          special: special,
          sum: sum,
          seed: effectiveSeed,
        ),
      );
    }

    return GeneratorOutcome(
      strategy: strategy,
      settings: settings,
      seed: effectiveSeed,
      sets: List<GeneratedSet>.unmodifiable(sets),
      weights: weights,
      generatedAt: DateTime.now(),
      targetDate: targetDate,
    );
  }

  /// Rút `count` số **không hoàn lại** theo trọng số.
  ///
  /// Dùng khoá `(1/w)·(-ln u)` (Efraimidis–Spirakis, dạng log của `u^(1/w)`):
  /// khoá **càng nhỏ** thì càng dễ được chọn, nên trọng số càng lớn càng dễ
  /// trúng. Khi mọi trọng số bằng nhau, kết quả là một hoán vị ngẫu nhiên đều
  /// nên chiến lược `uniform` vẫn đúng nghĩa rút thăm đều.
  static List<String> _pickWithoutReplacement(
    List<String> pool,
    NumberWeights weights,
    int count,
    Mulberry32 random,
  ) {
    final keys = <String, double>{};
    for (final number in pool) {
      final weight = weights.weightOf(number);
      final sample = _unit(random);
      keys[number] = -math.log(sample) / math.max(weight, 1e-9);
    }
    final ordered = <String>[...pool]
      ..sort((a, b) {
        final byKey = keys[a]!.compareTo(keys[b]!);
        return byKey != 0 ? byKey : a.compareTo(b);
      });
    return ordered.take(math.min(count, ordered.length)).toList();
  }

  /// Rút `count` số **có hoàn lại** (cho phép trùng trong cùng một bộ).
  static List<String> _pickWithReplacement(
    List<String> pool,
    NumberWeights weights,
    int count,
    Mulberry32 random,
  ) {
    final cumulative = <double>[];
    var running = 0.0;
    for (final number in pool) {
      running += math.max(weights.weightOf(number), 0) + 1e-9;
      cumulative.add(running);
    }
    final picks = <String>[];
    for (var index = 0; index < count; index += 1) {
      final target = random.next() * running;
      var position = cumulative.indexWhere((value) => value > target);
      if (position < 0) position = pool.length - 1;
      picks.add(pool[position]);
    }
    return picks;
  }

  static List<String> _applySort(
    List<String> numbers,
    GeneratorSortOrder order,
  ) {
    if (order == GeneratorSortOrder.none) return numbers;
    final sorted = <String>[...numbers]
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    if (order == GeneratorSortOrder.descending) {
      return sorted.reversed.toList(growable: false);
    }
    return sorted;
  }

  /// Số thực trong khoảng (0, 1] — tránh `log(0)` khi `Mulberry32` trả 0.
  static double _unit(Mulberry32 random) {
    final value = random.next();
    if (value <= 0) return 1e-12;
    return value > 1 ? 1 : value;
  }
}
