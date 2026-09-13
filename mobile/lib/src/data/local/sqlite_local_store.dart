/// Hiện thực SQLite (Android/iOS/desktop) cho [LocalStore].
library;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lottery_domain.dart';
import '../models/backtest.dart';
import '../models/draw_record.dart';
import '../models/generated_run.dart';
import '../models/lottery_models.dart';
import '../models/prediction.dart';
import '../models/sync_report.dart';
import 'local_store.dart';

/// Phiên bản schema SQLite cục bộ.
///
/// v2 (STEP 5): thêm bảng `dataset_meta` để lưu `datasetVersion`/`datasetDate`
/// của API. v3 (Bộ tính số): thêm bảng `generated_runs`/`generated_sets` để
/// lưu bộ số đã sinh kèm seed (tái lập được). `_createSchema` chỉ chạy các câu
/// `CREATE TABLE IF NOT EXISTS` nên nâng cấp từ v1/v2 không mất dữ liệu.
const int kLocalSchemaVersion = 3;

const String kLocalSchema = '''
CREATE TABLE IF NOT EXISTS stations (
  code TEXT NOT NULL,
  region TEXT NOT NULL,
  name TEXT NOT NULL,
  weekday INTEGER,
  PRIMARY KEY (region, code)
);

CREATE TABLE IF NOT EXISTS draws (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT NOT NULL,
  draw_date TEXT NOT NULL,
  station TEXT NOT NULL,
  draw_code TEXT,
  provider TEXT NOT NULL,
  collected_at TEXT NOT NULL,
  verification TEXT NOT NULL DEFAULT 'PENDING',
  created_at TEXT NOT NULL,
  UNIQUE (region, draw_date, station)
);

CREATE TABLE IF NOT EXISTS draw_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  draw_id INTEGER NOT NULL,
  region TEXT NOT NULL,
  draw_date TEXT NOT NULL,
  station TEXT NOT NULL,
  prize TEXT NOT NULL,
  position INTEGER NOT NULL,
  value TEXT NOT NULL,
  loto2 TEXT NOT NULL,
  UNIQUE (region, draw_date, station, prize, position),
  FOREIGN KEY (draw_id) REFERENCES draws (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_results_region_loto ON draw_results (region, loto2);
CREATE INDEX IF NOT EXISTS idx_results_region_date ON draw_results (region, draw_date);

CREATE TABLE IF NOT EXISTS sync_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT NOT NULL,
  started_at TEXT NOT NULL,
  finished_at TEXT NOT NULL,
  provider TEXT NOT NULL,
  status TEXT NOT NULL,
  inserted INTEGER NOT NULL DEFAULT 0,
  updated INTEGER NOT NULL DEFAULT 0,
  rejected INTEGER NOT NULL DEFAULT 0,
  note TEXT
);

CREATE TABLE IF NOT EXISTS provider_status (
  provider TEXT NOT NULL,
  region TEXT NOT NULL,
  last_success_at TEXT,
  last_failure_at TEXT,
  latency_ms INTEGER NOT NULL DEFAULT 0,
  successes INTEGER NOT NULL DEFAULT 0,
  failures INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  PRIMARY KEY (provider, region)
);

CREATE TABLE IF NOT EXISTS prediction_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT NOT NULL,
  created_at TEXT NOT NULL,
  model TEXT NOT NULL,
  window_days INTEGER NOT NULL,
  target_date TEXT NOT NULL,
  note TEXT
);

CREATE TABLE IF NOT EXISTS prediction_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id INTEGER NOT NULL,
  number TEXT NOT NULL,
  rank INTEGER NOT NULL,
  score REAL NOT NULL,
  features_json TEXT,
  UNIQUE (run_id, number),
  FOREIGN KEY (run_id) REFERENCES prediction_runs (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS backtest_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT NOT NULL,
  created_at TEXT NOT NULL,
  model TEXT NOT NULL,
  window_days INTEGER NOT NULL,
  samples INTEGER NOT NULL DEFAULT 0,
  top1_hits INTEGER NOT NULL DEFAULT 0,
  top4_hits INTEGER NOT NULL DEFAULT 0,
  top10_hits INTEGER NOT NULL DEFAULT 0,
  baseline_top4_hits INTEGER NOT NULL DEFAULT 0,
  random_top4_hits INTEGER NOT NULL DEFAULT 0,
  avg_hits_at4 REAL NOT NULL DEFAULT 0,
  avg_hits_at10 REAL NOT NULL DEFAULT 0,
  note TEXT,
  UNIQUE (region, created_at, model, window_days)
);

CREATE TABLE IF NOT EXISTS dataset_meta (
  region TEXT NOT NULL PRIMARY KEY,
  source TEXT NOT NULL,
  fetched_at TEXT NOT NULL,
  dataset_version TEXT,
  dataset_date TEXT,
  api_host TEXT,
  record_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS generated_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT NOT NULL,
  created_at TEXT NOT NULL,
  model TEXT NOT NULL,
  strategy TEXT NOT NULL,
  min_value INTEGER NOT NULL DEFAULT 0,
  max_value INTEGER NOT NULL DEFAULT 99,
  numbers_per_set INTEGER NOT NULL DEFAULT 6,
  set_count INTEGER NOT NULL DEFAULT 1,
  excluded_json TEXT,
  sort_order TEXT NOT NULL DEFAULT 'ascending',
  unique_within_set INTEGER NOT NULL DEFAULT 1,
  unique_across_sets INTEGER NOT NULL DEFAULT 1,
  special_max INTEGER,
  seed INTEGER NOT NULL DEFAULT 0,
  target_date TEXT,
  note TEXT
);

CREATE INDEX IF NOT EXISTS idx_generated_runs_region ON generated_runs (region, id DESC);

CREATE TABLE IF NOT EXISTS generated_sets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id INTEGER NOT NULL,
  set_index INTEGER NOT NULL,
  numbers TEXT NOT NULL,
  special TEXT,
  sum INTEGER NOT NULL DEFAULT 0,
  UNIQUE (run_id, set_index),
  FOREIGN KEY (run_id) REFERENCES generated_runs (id) ON DELETE CASCADE
);
''';

class SqliteLocalStore implements LocalStore {
  SqliteLocalStore({this.fileName = 'xsmb_manager.db'});

  final String fileName;
  Database? _db;

  @override
  String get backendName => 'SQLite (sqflite)';

  @override
  String get location => _db?.path ?? fileName;

  @override
  bool get isOpen => _db != null;

  Database get _database {
    final database = _db;
    if (database == null) {
      throw StateError('LocalStore chưa được mở. Gọi open() trước.');
    }
    return database;
  }

  @override
  Future<void> open() async {
    if (_db != null) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      _db = await _openWithRecovery(p.join(directory.path, fileName));
    } catch (error, stackTrace) {
      appLogger.error(
        'local-store',
        'Không mở được SQLite ($fileName) — chuyển sang database tạm trong bộ nhớ',
        '$error\n$stackTrace',
      );
      _db = await _openDatabase(inMemoryDatabasePath);
    }
  }

  /// Mở database; nếu schema/quá trình nâng cấp hỏng thì tạo lại file.
  ///
  /// Dữ liệu trong cache luôn tải lại được từ API nên tạo lại là lựa chọn an
  /// toàn hơn nhiều so với việc app không mở được database (⇒ màn hình trắng).
  Future<Database> _openWithRecovery(String path) async {
    try {
      return await _openDatabase(path);
    } catch (error, stackTrace) {
      appLogger.error(
        'local-store',
        'Mở $fileName thất bại — tạo lại database mới',
        '$error\n$stackTrace',
      );
      await deleteDatabase(path);
      return _openDatabase(path);
    }
  }

  Future<Database> _openDatabase(String path) => openDatabase(
    path,
    version: kLocalSchemaVersion,
    onConfigure: _configure,
    onCreate: (database, version) => _createSchema(database),
    onUpgrade: (database, oldVersion, newVersion) => _createSchema(database),
  );

  /// PRAGMA cấp kết nối **phải** chạy ở `onConfigure` (ngoài transaction).
  ///
  /// sqflite chạy `onCreate`/`onUpgrade` bên trong một transaction, mà SQLite
  /// từ chối hai lệnh sau khi transaction đang mở:
  /// * `PRAGMA journal_mode = WAL` → "cannot change into wal mode from within a transaction"
  /// * `PRAGMA synchronous = NORMAL` → "Safety level may not be changed inside a transaction"
  ///
  /// Trước đây chúng nằm trong `onCreate`, nên lần chạy đầu tiên (file DB mới)
  /// làm `openDatabase` ném lỗi ngay trước `runApp` ⇒ chỉ còn nền trắng.
  Future<void> _configure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
    for (final pragma in const <String>[
      'PRAGMA journal_mode = WAL',
      'PRAGMA synchronous = NORMAL',
      'PRAGMA busy_timeout = 5000',
    ]) {
      try {
        await database.execute(pragma);
      } catch (error) {
        // Một số nền tảng/phiên bản SQLite không cho đổi chế độ journal: không
        // đáng để cả app chết vì tối ưu ghi đĩa.
        appLogger.warning('local-store', 'Bỏ qua "$pragma" ($error)');
      }
    }
  }

  Future<void> _createSchema(DatabaseExecutor database) async {
    for (final statement in kLocalSchema.split(';')) {
      final trimmed = statement.trim();
      if (trimmed.isEmpty) continue;
      await database.execute('$trimmed;');
    }
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<String?> latestDrawDate(Region region) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(draw_date) AS latest FROM draws WHERE region = ?',
      <Object?>[region.code],
    );
    return rows.first['latest'] as String?;
  }

  @override
  Future<int> countDraws(Region region) async {
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) AS total FROM draws WHERE region = ?',
      <Object?>[region.code],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<DrawRecord>> loadDraws({
    required Region region,
    String? start,
    String? end,
    int? limit,
    bool ascending = false,
  }) async {
    if (limit != null && limit <= 0) return const <DrawRecord>[];
    final filters = <String>['region = ?'];
    final arguments = <Object?>[region.code];
    if (start != null) {
      filters.add('draw_date >= ?');
      arguments.add(start);
    }
    if (end != null) {
      filters.add('draw_date <= ?');
      arguments.add(end);
    }
    final rows = await _database.rawQuery(
      'SELECT id, draw_date, station, draw_code, provider, collected_at, verification '
      'FROM draws WHERE ${filters.join(' AND ')} '
      'ORDER BY draw_date ${ascending ? 'ASC' : 'DESC'}, station ASC'
      '${limit == null ? '' : ' LIMIT $limit'}',
      arguments,
    );
    if (rows.isEmpty) return const <DrawRecord>[];

    final ids = <int>[for (final row in rows) (row['id'] as num).toInt()];
    final placeholders = List<String>.filled(ids.length, '?').join(',');
    final resultRows = await _database.rawQuery(
      'SELECT draw_id, prize, position, value FROM draw_results '
      'WHERE draw_id IN ($placeholders) ORDER BY draw_id, id',
      ids,
    );
    final grouped = <int, List<PrizeRecord>>{};
    for (final row in resultRows) {
      grouped
          .putIfAbsent((row['draw_id'] as num).toInt(), () => <PrizeRecord>[])
          .add(
            PrizeRecord(
              prize: (row['prize'] ?? '').toString(),
              position: (row['position'] as num?)?.toInt() ?? 0,
              value: (row['value'] ?? '').toString(),
            ),
          );
    }

    return <DrawRecord>[
      for (final row in rows)
        DrawRecord(
          region: region,
          date: (row['draw_date'] ?? '').toString(),
          station: (row['station'] ?? '').toString(),
          results: grouped[(row['id'] as num).toInt()] ?? const <PrizeRecord>[],
          provider: (row['provider'] ?? '').toString(),
          collectedAt: (row['collected_at'] ?? '').toString(),
          verification: verificationFromCode(row['verification']?.toString()),
          drawCode: row['draw_code']?.toString(),
        ),
    ];
  }

  @override
  Future<UpsertOutcome> upsertDraws(Iterable<DrawRecord> draws) async {
    var inserted = 0;
    var updated = 0;
    await _database.transaction((transaction) async {
      for (final draw in draws) {
        final existing = await transaction.query(
          'draws',
          columns: <String>['id'],
          where: 'region = ? AND draw_date = ? AND station = ?',
          whereArgs: <Object?>[draw.region.code, draw.date, draw.station],
          limit: 1,
        );
        final now = DateTime.now().toIso8601String();
        final collectedAt = draw.collectedAt.isEmpty ? now : draw.collectedAt;
        int drawId;
        if (existing.isEmpty) {
          drawId = await transaction.insert('draws', <String, Object?>{
            'region': draw.region.code,
            'draw_date': draw.date,
            'station': draw.station,
            'draw_code': draw.resolvedDrawCode,
            'provider': draw.provider,
            'collected_at': collectedAt,
            'verification': draw.verification.code,
            'created_at': now,
          });
          inserted += 1;
        } else {
          drawId = (existing.first['id'] as num).toInt();
          await transaction.update(
            'draws',
            <String, Object?>{
              'provider': draw.provider,
              'collected_at': collectedAt,
              'verification': draw.verification.code,
            },
            where: 'id = ?',
            whereArgs: <Object?>[drawId],
          );
          await transaction.delete(
            'draw_results',
            where: 'draw_id = ?',
            whereArgs: <Object?>[drawId],
          );
          updated += 1;
        }
        for (final result in draw.results) {
          await transaction.insert('draw_results', <String, Object?>{
            'draw_id': drawId,
            'region': draw.region.code,
            'draw_date': draw.date,
            'station': draw.station,
            'prize': result.prize,
            'position': result.position,
            'value': result.value,
            'loto2': result.lastTwo,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
    return UpsertOutcome(inserted: inserted, updated: updated);
  }

  @override
  Future<void> addSyncHistory(SyncHistoryRecord record) async {
    await _database.insert('sync_history', record.toRow());
  }

  @override
  Future<List<SyncHistoryRecord>> recentSyncHistory({int limit = 20}) async {
    final rows = await _database.query(
      'sync_history',
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(SyncHistoryRecord.fromRow).toList(growable: false);
  }

  @override
  Future<void> upsertProviderStatus(ProviderStatusRecord status) async {
    await _database.insert(
      'provider_status',
      status.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ProviderStatusRecord>> providerStatuses({Region? region}) async {
    final rows = await _database.query(
      'provider_status',
      where: region == null ? null : 'region = ?',
      whereArgs: region == null ? null : <Object?>[region.code],
      orderBy: 'provider ASC',
    );
    return rows.map(ProviderStatusRecord.fromRow).toList(growable: false);
  }

  @override
  Future<int> savePredictionRun(PredictionRunRecord run) async {
    return _database.transaction((transaction) async {
      final id = await transaction.insert('prediction_runs', run.toRow());
      for (final entry in run.entries) {
        await transaction.insert(
          'prediction_results',
          entry.toRow(id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return id;
    });
  }

  @override
  Future<List<PredictionRunRecord>> recentPredictionRuns({
    Region? region,
    int limit = 10,
  }) async {
    final runs = await _database.query(
      'prediction_runs',
      where: region == null ? null : 'region = ?',
      whereArgs: region == null ? null : <Object?>[region.code],
      orderBy: 'id DESC',
      limit: limit,
    );
    final records = <PredictionRunRecord>[];
    for (final row in runs) {
      final id = (row['id'] as num).toInt();
      final entries = await _database.query(
        'prediction_results',
        where: 'run_id = ?',
        whereArgs: <Object?>[id],
        orderBy: 'rank ASC',
      );
      records.add(
        PredictionRunRecord(
          id: id,
          region: regionFromCode(row['region']?.toString()),
          createdAt: (row['created_at'] ?? '').toString(),
          model: (row['model'] ?? '').toString(),
          windowDays: (row['window_days'] as num?)?.toInt() ?? 0,
          targetDate: (row['target_date'] ?? '').toString(),
          entries: entries
              .map(PredictionEntryRecord.fromRow)
              .toList(growable: false),
          note: row['note']?.toString(),
        ),
      );
    }
    return records;
  }

  @override
  Future<void> saveBacktestResults(
    Region region,
    String createdAt,
    List<BacktestWindowResult> results, {
    String? note,
  }) async {
    await _database.transaction((transaction) async {
      for (final result in results) {
        await transaction.insert('backtest_runs', <String, Object?>{
          'region': region.code,
          'note': note,
          ...result.toRow(createdAt),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<List<BacktestWindowResult>> recentBacktestResults({
    int limit = 40,
  }) async {
    final rows = await _database.query(
      'backtest_runs',
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(BacktestWindowResult.fromRow).toList(growable: false);
  }

  @override
  Future<int> saveGeneratedRun(GeneratedRunRecord run) async {
    return _database.transaction((transaction) async {
      final id = await transaction.insert('generated_runs', run.toRow());
      for (final set in run.sets) {
        await transaction.insert(
          'generated_sets',
          set.toRow(id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return id;
    });
  }

  @override
  Future<List<GeneratedRunRecord>> recentGeneratedRuns({
    Region? region,
    int limit = 10,
  }) async {
    final runs = await _database.query(
      'generated_runs',
      where: region == null ? null : 'region = ?',
      whereArgs: region == null ? null : <Object?>[region.code],
      orderBy: 'id DESC',
      limit: limit,
    );
    final records = <GeneratedRunRecord>[];
    for (final row in runs) {
      final id = (row['id'] as num).toInt();
      final sets = await _database.query(
        'generated_sets',
        where: 'run_id = ?',
        whereArgs: <Object?>[id],
        orderBy: 'set_index ASC',
      );
      records.add(
        GeneratedRunRecord.fromRow(
          row,
          sets: sets.map(GeneratedSetRecord.fromRow).toList(growable: false),
        ),
      );
    }
    return records;
  }

  @override
  Future<LocalStoreStats> stats() async {
    final drawRows = await _database.rawQuery(
      'SELECT COUNT(*) AS draws, MIN(draw_date) AS oldest, MAX(draw_date) AS newest FROM draws',
    );
    final resultRows = await _database.rawQuery(
      'SELECT COUNT(*) AS total FROM draw_results',
    );
    final regionRows = await _database.rawQuery(
      'SELECT region, COUNT(*) AS total FROM draws GROUP BY region',
    );
    return LocalStoreStats(
      draws: (drawRows.first['draws'] as num?)?.toInt() ?? 0,
      results: (resultRows.first['total'] as num?)?.toInt() ?? 0,
      oldestDate: drawRows.first['oldest'] as String?,
      newestDate: drawRows.first['newest'] as String?,
      perRegion: <String, int>{
        for (final row in regionRows)
          (row['region'] ?? '').toString():
              (row['total'] as num?)?.toInt() ?? 0,
      },
    );
  }

  @override
  Future<void> saveDatasetMeta(DatasetMeta meta) async {
    await _database.insert(
      'dataset_meta',
      meta.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<DatasetMeta?> datasetMeta(Region region) async {
    final rows = await _database.query(
      'dataset_meta',
      where: 'region = ?',
      whereArgs: <Object?>[region.code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DatasetMeta.fromRow(rows.first);
  }

  @override
  Future<int> purgeBefore(String isoDate) async {
    return _database.transaction((transaction) async {
      final rows = await transaction.query(
        'draws',
        columns: <String>['id'],
        where: 'draw_date < ?',
        whereArgs: <Object?>[isoDate],
      );
      if (rows.isEmpty) return 0;
      for (final row in rows) {
        await transaction.delete(
          'draw_results',
          where: 'draw_id = ?',
          whereArgs: <Object?>[(row['id'] as num).toInt()],
        );
      }
      return transaction.delete(
        'draws',
        where: 'draw_date < ?',
        whereArgs: <Object?>[isoDate],
      );
    });
  }
}
