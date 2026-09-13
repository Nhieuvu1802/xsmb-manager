/// Hợp đồng lưu trữ cục bộ trên thiết bị.
///
/// Hai hiện thực: SQLite (Android/iOS/desktop) và bộ nhớ khoá-giá trị (Web).
/// Mọi thao tác ghi đều dùng khoá duy nhất `region + date + station + prize +
/// position` nên chạy lại đồng bộ không sinh bản ghi trùng.
library;

import '../../domain/lottery_domain.dart';
import '../models/backtest.dart';
import '../models/draw_record.dart';
import '../models/generated_run.dart';
import '../models/lottery_models.dart';
import '../models/prediction.dart';
import '../models/sync_report.dart';

class UpsertOutcome {
  const UpsertOutcome({required this.inserted, required this.updated});

  final int inserted;
  final int updated;

  int get total => inserted + updated;

  UpsertOutcome operator +(UpsertOutcome other) => UpsertOutcome(
    inserted: inserted + other.inserted,
    updated: updated + other.updated,
  );

  static const UpsertOutcome empty = UpsertOutcome(inserted: 0, updated: 0);
}

class LocalStoreStats {
  const LocalStoreStats({
    required this.draws,
    required this.results,
    this.oldestDate,
    this.newestDate,
    this.perRegion = const <String, int>{},
  });

  final int draws;
  final int results;
  final String? oldestDate;
  final String? newestDate;
  final Map<String, int> perRegion;

  static const LocalStoreStats empty = LocalStoreStats(draws: 0, results: 0);
}

abstract class LocalStore {
  /// Tên hiện thực để hiển thị trong màn hình Cài đặt.
  String get backendName;

  /// Vị trí lưu (đường dẫn file hoặc tên store trình duyệt).
  String get location;

  Future<void> open();

  Future<void> close();

  bool get isOpen;

  Future<String?> latestDrawDate(Region region);

  Future<int> countDraws(Region region);

  /// Đọc kỳ quay. `ascending = true` để tính thống kê theo thứ tự thời gian.
  Future<List<DrawRecord>> loadDraws({
    required Region region,
    String? start,
    String? end,
    int? limit,
    bool ascending = false,
  });

  Future<UpsertOutcome> upsertDraws(Iterable<DrawRecord> draws);

  Future<void> addSyncHistory(SyncHistoryRecord record);

  Future<List<SyncHistoryRecord>> recentSyncHistory({int limit = 20});

  Future<void> upsertProviderStatus(ProviderStatusRecord status);

  Future<List<ProviderStatusRecord>> providerStatuses({Region? region});

  /// Lưu một lần xếp hạng, trả về id của lượt chạy.
  Future<int> savePredictionRun(PredictionRunRecord run);

  Future<List<PredictionRunRecord>> recentPredictionRuns({
    Region? region,
    int limit = 10,
  });

  Future<void> saveBacktestResults(
    Region region,
    String createdAt,
    List<BacktestWindowResult> results, {
    String? note,
  });

  Future<List<BacktestWindowResult>> recentBacktestResults({int limit = 40});

  /// Lưu một lần sinh bộ số, trả về id của lượt chạy.
  ///
  /// Seed và cấu hình được lưu kèm nên có thể tái lập đúng bộ số cũ.
  Future<int> saveGeneratedRun(GeneratedRunRecord run);

  /// Các lần sinh bộ số gần nhất (mới nhất trước), kèm danh sách bộ số.
  Future<List<GeneratedRunRecord>> recentGeneratedRuns({
    Region? region,
    int limit = 10,
  });

  Future<LocalStoreStats> stats();

  /// Lưu metadata dataset (`datasetVersion`, `datasetDate`, nguồn) của một vùng.
  ///
  /// Nhờ bảng này app biết cache đang ở phiên bản nào ngay cả khi mất mạng.
  Future<void> saveDatasetMeta(DatasetMeta meta);

  /// Metadata dataset đã tải gần nhất của một vùng (`null` nếu chưa từng tải).
  Future<DatasetMeta?> datasetMeta(Region region);

  /// Xoá dữ liệu cũ hơn `isoDate`, trả về số kỳ đã xoá.
  Future<int> purgeBefore(String isoDate);
}
