/// Hiện thực LocalStore cho Flutter Web (localStorage qua shared_preferences).
///
/// Trình duyệt không có SQLite, nên bản web giữ một cửa sổ dữ liệu gần nhất
/// theo từng vùng. Lịch sử dài nằm ở backend (PostgreSQL) và được tải theo
/// khoảng ngày cần dùng.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lottery_domain.dart';
import '../models/backtest.dart';
import '../models/draw_record.dart';
import '../models/generated_run.dart';
import '../models/lottery_models.dart';
import '../models/prediction.dart';
import '../models/sync_report.dart';
import 'local_store.dart';

class WebLocalStore implements LocalStore {
  WebLocalStore({this.maxDrawsPerRegion = 400});

  final int maxDrawsPerRegion;
  SharedPreferences? _preferences;

  static const String _drawsKey = 'xsmb:web:draws';
  static const String _syncKey = 'xsmb:web:sync-history';
  static const String _providerKey = 'xsmb:web:provider-status';
  static const String _predictionKey = 'xsmb:web:prediction-runs';
  static const String _backtestKey = 'xsmb:web:backtest-runs';
  static const String _metaKey = 'xsmb:web:dataset-meta';
  static const String _generatedKey = 'xsmb:web:generated-runs';

  /// Số lần sinh bộ số giữ lại trên web (localStorage có hạn mức nhỏ).
  static const int maxGeneratedRuns = 20;

  @override
  String get backendName => 'localStorage (shared_preferences)';

  @override
  String get location => 'localStorage của trình duyệt';

  @override
  bool get isOpen => _preferences != null;

  SharedPreferences get _store {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('LocalStore chưa được mở. Gọi open() trước.');
    }
    return preferences;
  }

  @override
  Future<void> open() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> close() async {
    _preferences = null;
  }

  List<Map<String, Object?>> _readRows(String key) {
    final raw = _store.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, Object?>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, Object?>>[];
      return <Map<String, Object?>>[
        for (final item in decoded)
          if (item is Map) item.cast<String, Object?>(),
      ];
    } on FormatException {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> _writeRows(String key, List<Map<String, Object?>> rows) =>
      _store.setString(key, jsonEncode(rows));

  String _regionKey(Region region) => '$_drawsKey:${region.code}';

  static String _rowKey(Map<String, Object?> row) =>
      '${row['region']}|${row['date']}|${row['station']}';

  @override
  Future<String?> latestDrawDate(Region region) async {
    final rows = _readRows(_regionKey(region));
    if (rows.isEmpty) return null;
    final dates = <String>[
      for (final row in rows)
        if ((row['date'] ?? '').toString().isNotEmpty)
          (row['date'] ?? '').toString(),
    ]..sort();
    return dates.isEmpty ? null : dates.last;
  }

  @override
  Future<int> countDraws(Region region) async =>
      _readRows(_regionKey(region)).length;

  @override
  Future<List<DrawRecord>> loadDraws({
    required Region region,
    String? start,
    String? end,
    int? limit,
    bool ascending = false,
  }) async {
    if (limit != null && limit <= 0) return const <DrawRecord>[];
    final rows =
        _readRows(_regionKey(region)).where((row) {
          final date = (row['date'] ?? '').toString();
          if (start != null && date.compareTo(start) < 0) return false;
          if (end != null && date.compareTo(end) > 0) return false;
          return true;
        }).toList()..sort((a, b) {
          final left = (a['date'] ?? '').toString();
          final right = (b['date'] ?? '').toString();
          return ascending ? left.compareTo(right) : right.compareTo(left);
        });
    final selected = limit == null ? rows : rows.take(limit).toList();
    return selected
        .map(
          (row) =>
              DrawRecord.fromJson(row, provider: row['source']?.toString()),
        )
        .toList(growable: false);
  }

  @override
  Future<UpsertOutcome> upsertDraws(Iterable<DrawRecord> draws) async {
    final byRegion = <Region, Map<String, Map<String, Object?>>>{};
    var inserted = 0;
    var updated = 0;
    for (final draw in draws) {
      final rows = byRegion.putIfAbsent(draw.region, () {
        final existing = _readRows(_regionKey(draw.region));
        return <String, Map<String, Object?>>{
          for (final row in existing) _rowKey(row): row,
        };
      });
      final key = '${draw.region.code}|${draw.date}|${draw.station}';
      if (rows.containsKey(key)) {
        updated += 1;
      } else {
        inserted += 1;
      }
      rows[key] = <String, Object?>{...draw.toJson(), 'key': key};
    }
    for (final entry in byRegion.entries) {
      final sorted = entry.value.values.toList()
        ..sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
      await _writeRows(
        _regionKey(entry.key),
        sorted.take(maxDrawsPerRegion).toList(growable: false),
      );
    }
    return UpsertOutcome(inserted: inserted, updated: updated);
  }

  @override
  Future<void> addSyncHistory(SyncHistoryRecord record) async {
    final rows = _readRows(_syncKey)..insert(0, record.toRow());
    await _writeRows(_syncKey, rows.take(50).toList(growable: false));
  }

  @override
  Future<List<SyncHistoryRecord>> recentSyncHistory({int limit = 20}) async =>
      _readRows(
        _syncKey,
      ).take(limit).map(SyncHistoryRecord.fromRow).toList(growable: false);

  @override
  Future<void> upsertProviderStatus(ProviderStatusRecord status) async {
    final rows = _readRows(_providerKey)
      ..removeWhere(
        (row) =>
            row['provider'] == status.provider &&
            row['region'] == status.region.code,
      );
    rows.insert(0, status.toRow());
    await _writeRows(_providerKey, rows.take(40).toList(growable: false));
  }

  @override
  Future<List<ProviderStatusRecord>> providerStatuses({Region? region}) async =>
      _readRows(_providerKey)
          .where((row) => region == null || row['region'] == region.code)
          .map(ProviderStatusRecord.fromRow)
          .toList(growable: false);

  @override
  Future<int> savePredictionRun(PredictionRunRecord run) async {
    final rows = _readRows(_predictionKey);
    final id = rows.length + 1;
    rows.insert(0, <String, Object?>{
      'id': id,
      ...run.toRow(),
      'entries': <Map<String, Object?>>[
        for (final entry in run.entries)
          <String, Object?>{
            'number': entry.number,
            'rank': entry.rank,
            'score': entry.score,
          },
      ],
    });
    await _writeRows(_predictionKey, rows.take(20).toList(growable: false));
    return id;
  }

  @override
  Future<List<PredictionRunRecord>> recentPredictionRuns({
    Region? region,
    int limit = 10,
  }) async {
    return _readRows(_predictionKey)
        .where((row) => region == null || row['region'] == region.code)
        .take(limit)
        .map((row) {
          final entries = (row['entries'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>();
          return PredictionRunRecord(
            id: (row['id'] as num?)?.toInt(),
            region: regionFromCode(row['region']?.toString()),
            createdAt: (row['created_at'] ?? '').toString(),
            model: (row['model'] ?? '').toString(),
            windowDays: (row['window_days'] as num?)?.toInt() ?? 0,
            targetDate: (row['target_date'] ?? '').toString(),
            entries: <PredictionEntryRecord>[
              for (final entry in entries)
                PredictionEntryRecord(
                  number: (entry['number'] ?? '').toString(),
                  rank: (entry['rank'] as num?)?.toInt() ?? 0,
                  score: (entry['score'] as num?)?.toDouble() ?? 0,
                ),
            ],
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> saveBacktestResults(
    Region region,
    String createdAt,
    List<BacktestWindowResult> results, {
    String? note,
  }) async {
    final rows = _readRows(_backtestKey);
    for (final result in results) {
      rows.insert(0, <String, Object?>{
        'region': region.code,
        ...result.toRow(createdAt),
      });
    }
    await _writeRows(_backtestKey, rows.take(200).toList(growable: false));
  }

  @override
  Future<List<BacktestWindowResult>> recentBacktestResults({
    int limit = 40,
  }) async => _readRows(
    _backtestKey,
  ).take(limit).map(BacktestWindowResult.fromRow).toList(growable: false);

  @override
  Future<int> saveGeneratedRun(GeneratedRunRecord run) async {
    final rows = _readRows(_generatedKey);
    final id = rows.length + 1;
    rows.insert(0, <String, Object?>{
      'id': id,
      ...run.toRow(),
      'sets': <Map<String, Object?>>[for (final set in run.sets) set.toRow(id)],
    });
    await _writeRows(
      _generatedKey,
      rows.take(maxGeneratedRuns).toList(growable: false),
    );
    return id;
  }

  @override
  Future<List<GeneratedRunRecord>> recentGeneratedRuns({
    Region? region,
    int limit = 10,
  }) async {
    return _readRows(_generatedKey)
        .where((row) => region == null || row['region'] == region.code)
        .take(limit)
        .map((row) {
          final sets = (row['sets'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<dynamic, dynamic>>();
          return GeneratedRunRecord.fromRow(
            row,
            sets: <GeneratedSetRecord>[
              for (final set in sets)
                GeneratedSetRecord.fromRow(set.cast<String, Object?>()),
            ],
          );
        })
        .toList(growable: false);
  }

  @override
  Future<LocalStoreStats> stats() async {
    var draws = 0;
    var results = 0;
    final perRegion = <String, int>{};
    String? oldest;
    String? newest;
    for (final region in Region.values) {
      final rows = _readRows(_regionKey(region));
      if (rows.isEmpty) continue;
      draws += rows.length;
      perRegion[region.code] = rows.length;
      for (final row in rows) {
        final date = (row['date'] ?? '').toString();
        if (oldest == null || date.compareTo(oldest) < 0) oldest = date;
        if (newest == null || date.compareTo(newest) > 0) newest = date;
        final prizes = row['results'];
        if (prizes is List) results += prizes.length;
      }
    }
    return LocalStoreStats(
      draws: draws,
      results: results,
      oldestDate: oldest,
      newestDate: newest,
      perRegion: perRegion,
    );
  }

  @override
  Future<void> saveDatasetMeta(DatasetMeta meta) async {
    final rows = _readRows(
      _metaKey,
    ).where((row) => row['region'] != meta.region.code).toList(growable: false);
    await _writeRows(_metaKey, <Map<String, Object?>>[meta.toRow(), ...rows]);
  }

  @override
  Future<DatasetMeta?> datasetMeta(Region region) async {
    for (final row in _readRows(_metaKey)) {
      if (row['region'] == region.code) return DatasetMeta.fromRow(row);
    }
    return null;
  }

  @override
  Future<int> purgeBefore(String isoDate) async {
    var removed = 0;
    for (final region in Region.values) {
      final rows = _readRows(_regionKey(region));
      final kept = rows
          .where(
            (row) => (row['date'] ?? '').toString().compareTo(isoDate) >= 0,
          )
          .toList();
      removed += rows.length - kept.length;
      if (kept.length != rows.length) {
        await _writeRows(_regionKey(region), kept);
      }
    }
    return removed;
  }
}
