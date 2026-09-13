/// Nguồn dữ liệu cục bộ (SQLite trên máy / bộ nhớ web) — tầng cache của app.
///
/// Repository dùng lớp này theo thứ tự:
/// 1. đọc cache để UI có dữ liệu ngay;
/// 2. gọi API production rồi ghi vào cache khi dữ liệu hợp lệ;
/// 3. nếu API lỗi thì UI vẫn chạy ở chế độ offline bằng dữ liệu cache.
library;

import '../../../core/logging/app_logger.dart';
import '../../../domain/lottery_domain.dart';
import '../../local/local_store.dart';
import '../../models/draw_record.dart';
import '../../models/draw_validation.dart';
import '../../models/lottery_models.dart';
import '../../models/sync_report.dart';

/// Kết quả một lần ghi cache: số kỳ ghi được và số kỳ bị từ chối.
class LocalWriteResult {
  const LocalWriteResult({
    required this.upsert,
    this.rejected = 0,
    this.errors = const <String>[],
  });

  final UpsertOutcome upsert;
  final int rejected;
  final List<String> errors;

  int get inserted => upsert.inserted;
  int get updated => upsert.updated;

  static const LocalWriteResult empty = LocalWriteResult(
    upsert: UpsertOutcome.empty,
  );
}

/// Ảnh chụp nhanh tình trạng cache để hiển thị ở màn hình Trạng thái.
class CacheSnapshot {
  const CacheSnapshot({
    required this.backendName,
    required this.location,
    required this.isOpen,
    required this.stats,
    this.latestMbDate,
    this.latestMnDate,
    this.lastSync,
    this.mbMeta,
    this.mnMeta,
  });

  final String backendName;
  final String location;
  final bool isOpen;
  final LocalStoreStats stats;
  final String? latestMbDate;
  final String? latestMnDate;
  final SyncHistoryRecord? lastSync;

  /// Metadata dataset của miền Bắc / miền Nam mà app đã tải về.
  final DatasetMeta? mbMeta;
  final DatasetMeta? mnMeta;

  bool get hasData => stats.draws > 0;

  /// Ngày mới nhất có trong cache (để so với `datasetVersion` của API).
  String? get newestDate => stats.newestDate;

  String get summary =>
      '${stats.draws} kỳ · ${stats.results} kết quả'
      '${stats.newestDate == null ? '' : ' · mới nhất ${stats.newestDate}'}';

  static const CacheSnapshot empty = CacheSnapshot(
    backendName: 'chưa mở',
    location: '',
    isOpen: false,
    stats: LocalStoreStats.empty,
  );
}

class LotteryLocalDataSource {
  LotteryLocalDataSource({required this.store, AppLogger? logger})
    : _logger = logger ?? appLogger;

  final LocalStore store;
  final AppLogger _logger;

  String get backendName => store.backendName;

  String get location => store.location;

  bool get isOpen => store.isOpen;

  Future<void> open() async {
    if (store.isOpen) return;
    await store.open();
    _logger.info(
      'cache',
      'Mở cache ${store.backendName} tại ${store.location}',
    );
  }

  Future<void> close() => store.close();

  Future<String?> latestDate(Region region) => store.latestDrawDate(region);

  Future<int> countDraws(Region region) => store.countDraws(region);

  Future<LocalStoreStats> stats() => store.stats();

  Future<List<DrawRecord>> loadDraws({
    required Region region,
    int? limit,
    String? start,
    String? end,
    bool ascending = false,
  }) => store.loadDraws(
    region: region,
    limit: limit,
    start: start,
    end: end,
    ascending: ascending,
  );

  /// N kỳ gần nhất theo thứ tự thời gian (cũ → mới) để tính thống kê.
  Future<List<DrawRecord>> loadLatestDays({
    required Region region,
    int days = 1,
  }) async {
    final all = await store.loadDraws(region: region, ascending: false);
    final dates = <String>[];
    for (final draw in all) {
      if (!dates.contains(draw.date)) dates.add(draw.date);
      if (dates.length == days) break;
    }
    final selected = all
        .where((draw) => dates.contains(draw.date))
        .toList(growable: false);
    return List<DrawRecord>.of(selected)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Cache đã có dữ liệu của ngày [isoDate] chưa?
  Future<bool> hasDate({
    required Region region,
    required String isoDate,
  }) async {
    final draws = await loadDraws(region: region, start: isoDate, end: isoDate);
    return draws.isNotEmpty;
  }

  /// Ghi cache có kiểm định cơ cấu giải; kỳ sai bị loại, không ghi.
  Future<LocalWriteResult> saveDraws(
    Iterable<DrawRecord> draws, {
    bool validate = true,
  }) async {
    final list = draws.toList(growable: false);
    if (list.isEmpty) return LocalWriteResult.empty;
    if (!validate) {
      return LocalWriteResult(upsert: await store.upsertDraws(list));
    }

    final invalid = validateDraws(list);
    final errors = <String>[
      for (final entry in invalid.entries) '${entry.key}: ${entry.value.first}',
    ];
    final valid = <DrawRecord>[
      for (final draw in list)
        if (!invalid.containsKey(draw.key)) draw,
    ];
    for (final message in errors) {
      _logger.warning('cache', 'Từ chối ghi cache — $message');
    }
    if (valid.isEmpty) {
      return LocalWriteResult(
        upsert: UpsertOutcome.empty,
        rejected: invalid.length,
        errors: errors,
      );
    }
    return LocalWriteResult(
      upsert: await store.upsertDraws(valid),
      rejected: invalid.length,
      errors: errors,
    );
  }

  Future<void> recordSyncHistory(SyncHistoryRecord record) =>
      store.addSyncHistory(record);

  Future<List<SyncHistoryRecord>> syncHistory({int limit = 20}) =>
      store.recentSyncHistory(limit: limit);

  Future<void> recordProviderStatus(ProviderStatusRecord status) =>
      store.upsertProviderStatus(status);

  Future<List<ProviderStatusRecord>> providerStatuses({Region? region}) =>
      store.providerStatuses(region: region);

  Future<int> purgeBefore(String isoDate) => store.purgeBefore(isoDate);

  /// Lưu metadata dataset sau mỗi lần đồng bộ thành công (STEP 5).
  Future<void> saveDatasetMeta(DatasetMeta meta) => store.saveDatasetMeta(meta);

  /// Metadata dataset đã tải gần nhất của một vùng (`null` nếu chưa từng tải).
  Future<DatasetMeta?> datasetMeta(Region region) => store.datasetMeta(region);

  /// Thông tin gọn cho màn hình Trạng thái.
  Future<CacheSnapshot> snapshot() async {
    final stats = await store.stats();
    final mb = await store.latestDrawDate(Region.mienBac);
    final mn = await store.latestDrawDate(Region.mienNam);
    SyncHistoryRecord? last;
    try {
      final history = await store.recentSyncHistory(limit: 1);
      last = history.isEmpty ? null : history.first;
    } catch (error) {
      _logger.warning('cache', 'Không đọc được lịch sử đồng bộ: $error');
    }
    DatasetMeta? mbMeta;
    DatasetMeta? mnMeta;
    try {
      mbMeta = await store.datasetMeta(Region.mienBac);
      mnMeta = await store.datasetMeta(Region.mienNam);
    } catch (error) {
      _logger.warning('cache', 'Không đọc được dataset_meta: $error');
    }
    return CacheSnapshot(
      backendName: store.backendName,
      location: store.location,
      isOpen: store.isOpen,
      stats: stats,
      latestMbDate: mb,
      latestMnDate: mn,
      lastSync: last,
      mbMeta: mbMeta,
      mnMeta: mnMeta,
    );
  }
}
