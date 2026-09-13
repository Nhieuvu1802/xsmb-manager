/// Điều phối đồng bộ: database cục bộ ↔ chuỗi provider.
///
/// Luồng chuẩn (STEP 4):
/// ```text
/// Cloudflare Worker → LotteryApiClient → LotteryRepository
///                   → LotteryLocalDataSource (SQLite/cache) → Flutter UI
/// ```
/// Khi API lỗi, repository vẫn trả dữ liệu cache để UI chạy ở chế độ offline.
/// Kiểm tra ngày cuối trong database → xác định khoảng còn thiếu → gọi provider
/// → kiểm định → ghi database → trả báo cáo cho UI. Không tải lại toàn bộ lịch
/// sử mỗi lần mở app.
library;

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/lottery_dates.dart';
import '../../domain/lottery_domain.dart';
import '../local/local_store.dart';
import '../models/api_models.dart';
import '../models/backtest.dart';
import '../models/draw_record.dart';
import '../models/draw_validation.dart';
import '../models/generated_run.dart';
import '../models/lottery_models.dart';
import '../models/prediction.dart';
import '../models/sync_report.dart';
import '../providers/provider_chain.dart';
import '../sources/local/lottery_local_data_source.dart';
import '../sources/remote/lottery_api_client.dart';

class LotteryRepository {
  LotteryRepository({
    required this.store,
    required this.chain,
    this.api,
    this.apiBaseUrlLoader,
    LotteryLocalDataSource? local,
    AppLogger? logger,
    DateTime Function()? clock,
  }) : local = local ?? LotteryLocalDataSource(store: store),
       _logger = logger ?? appLogger,
       _clock = clock ?? DateTime.now;

  final LocalStore store;
  final LotteryProviderChain chain;

  /// Client typed của API production (`null` khi app chỉ chạy offline).
  final LotteryApiClient? api;

  /// Đọc URL API đang dùng (để ghi `dataset_meta.api_host`); `null` khi offline.
  final Future<String> Function()? apiBaseUrlLoader;

  /// Tầng cache (SQLite/bộ nhớ) mà UI đọc được cả khi không có mạng.
  final LotteryLocalDataSource local;

  final AppLogger _logger;
  final DateTime Function() _clock;

  bool _opened = false;

  Future<void> open() async {
    if (_opened) return;
    await store.open();
    _opened = true;
    final stats = await store.stats();
    _logger.info(
      'repository',
      'Mở ${store.backendName}: ${stats.draws} kỳ, ${stats.results} kết quả',
    );
  }

  Future<void> close() async {
    await store.close();
    _opened = false;
  }

  Future<String?> latestDate(Region region) => local.latestDate(region);

  Future<LocalStoreStats> stats() => local.stats();

  Future<int> countDraws(Region region) => local.countDraws(region);

  Future<List<ProviderStatusRecord>> providerStatuses(Region region) =>
      local.providerStatuses(region: region);

  Future<List<SyncHistoryRecord>> syncHistory({int limit = 20}) =>
      local.syncHistory(limit: limit);

  Future<List<ProviderAttempt>> healthCheckAll() => chain.healthCheckAll();

  /// Ảnh chụp cache cục bộ cho màn hình Trạng thái (STEP 9).
  Future<CacheSnapshot> cacheSnapshot() => local.snapshot();

  /// Cache đã có dữ liệu của ngày [isoDate] chưa (kiểm tra trước khi tải).
  Future<bool> cacheHasDate({
    required Region region,
    required String isoDate,
  }) => local.hasDate(region: region, isoDate: isoDate);

  /// Metadata dataset đã lưu của một vùng (STEP 5).
  Future<DatasetMeta?> datasetMeta(Region region) => local.datasetMeta(region);

  /// Lưu metadata dataset; lỗi ghi không được làm hỏng luồng đồng bộ.
  Future<void> saveDatasetMeta(DatasetMeta meta) async {
    try {
      await local.saveDatasetMeta(meta);
    } catch (error) {
      _logger.warning('repository', 'Không ghi được dataset_meta: $error');
    }
  }

  /// Trạng thái hệ thống cho màn hình "Trạng thái" (STEP 11).
  ///
  /// Không ném lỗi khi mất mạng: mọi giá trị đều có phương án dự phòng để UI
  /// luôn hiển thị được tình trạng cache.
  Future<SystemStatus> systemStatus({
    required Region region,
    required String apiBaseUrl,
    String? appVersion,
  }) async {
    final snapshot = await local.snapshot();
    final host = Uri.tryParse(apiBaseUrl)?.host ?? apiBaseUrl;
    final health = await remoteHealth();

    // `/v1/config` có thể khai host khác URL app đang gọi (GAP-1: host mới chưa
    // có DNS). Chỉ ghi nhận để cảnh báo, không tự đổi endpoint.
    String? reportedBaseUrl;
    final client = api;
    if (client != null) {
      try {
        reportedBaseUrl = (await client.config()).apiBaseUrl;
      } on LotteryApiException catch (error) {
        _logger.warning(
          'repository',
          'Không đọc được /config: ${error.message}',
        );
      }
    }

    final online = health.status.toLowerCase() == 'ok';
    final meta = await local.datasetMeta(region);

    SyncHistoryRecord? lastSuccess;
    try {
      for (final item in await local.syncHistory(limit: 10)) {
        if (item.status == SyncOutcome.success ||
            item.status == SyncOutcome.upToDate ||
            item.status == SyncOutcome.partial) {
          lastSuccess = item;
          break;
        }
      }
    } catch (error) {
      _logger.warning('repository', 'Không đọc được sync_history: $error');
    }

    final source = online
        ? DataSourceKind.cloudflare
        : (snapshot.hasData ? DataSourceKind.cache : DataSourceKind.none);

    return SystemStatus(
      region: region,
      apiBaseUrl: apiBaseUrl,
      apiHost: host,
      apiOnline: online,
      source: source,
      sourceNote: online
          ? 'Dữ liệu lấy trực tiếp từ Cloudflare Worker.'
          : (snapshot.hasData
                ? 'API không phản hồi; đang đọc dữ liệu đã lưu trên máy.'
                : 'Chưa có dữ liệu ngoại tuyến trên máy.'),
      datasetDate: health.datasetDate ?? meta?.datasetDate,
      datasetVersion: health.datasetVersion,
      lastSuccessfulSyncAt: lastSuccess?.finishedAt,
      lastSyncProvider: lastSuccess?.provider,
      cacheDate: region == Region.mienNam
          ? snapshot.latestMnDate
          : snapshot.latestMbDate,
      cacheDraws: snapshot.stats.draws,
      cacheResults: snapshot.stats.results,
      checkedAt: _clock().toIso8601String(),
      apiReportedBaseUrl: reportedBaseUrl,
      appVersion: appVersion ?? AppConfig.appVersionLabel,
    );
  }

  /// Gọi `/v1/health` của API production; trả trạng thái `offline` khi lỗi
  /// thay vì ném ra ngoài để UI luôn hiển thị được.
  Future<ApiHealth> remoteHealth() async {
    final client = api;
    if (client == null) return ApiHealth.unknown;
    try {
      return await client.health();
    } on LotteryApiException catch (error) {
      _logger.warning('repository', 'Health API lỗi: ${error.message}');
      return const ApiHealth(status: 'offline');
    }
  }

  /// `/v1/manifest` — dùng để so `datasetVersion` trước khi tải (STEP 8).
  Future<ApiManifest?> remoteManifest() async {
    final client = api;
    if (client == null) return null;
    try {
      return await client.manifest();
    } on LotteryApiException catch (error) {
      _logger.warning('repository', 'Manifest API lỗi: ${error.message}');
      return null;
    }
  }

  List<SourceDescriptor> describeSources() => chain.describeSources();

  /// Kỳ quay (model dữ liệu) cho UI, mới nhất trước.
  Future<List<DrawRecord>> recentDraws({
    required Region region,
    int? limit,
    String? start,
    String? end,
    bool ascending = false,
  }) => local.loadDraws(
    region: region,
    limit: limit,
    start: start,
    end: end,
    ascending: ascending,
  );

  /// Kỳ quay ở dạng domain model mà các tab UI đang dùng.
  Future<List<LotteryDraw>> recentDomainDraws({
    required Region region,
    int? limit,
  }) async {
    final draws = await store.loadDraws(region: region, limit: limit);
    return <LotteryDraw>[for (final draw in draws) draw.toDomain()];
  }

  Future<int> savePredictionRun(PredictionRunRecord run) =>
      store.savePredictionRun(run);

  Future<List<PredictionRunRecord>> recentPredictionRuns({
    Region? region,
    int limit = 10,
  }) => store.recentPredictionRuns(region: region, limit: limit);

  Future<void> saveBacktestResults(
    Region region,
    List<BacktestWindowResult> results,
  ) => store.saveBacktestResults(region, _clock().toIso8601String(), results);

  Future<List<BacktestWindowResult>> recentBacktestResults({int limit = 40}) =>
      store.recentBacktestResults(limit: limit);

  /// Lưu một lần sinh bộ số (tab "Bộ tính số").
  Future<int> saveGeneratedRun(GeneratedRunRecord run) =>
      store.saveGeneratedRun(run);

  /// Lịch sử sinh bộ số gần nhất của một vùng.
  Future<List<GeneratedRunRecord>> recentGeneratedRuns({
    Region? region,
    int limit = 10,
  }) => store.recentGeneratedRuns(region: region, limit: limit);

  Future<int> purgeBefore(String isoDate) => local.purgeBefore(isoDate);

  /// Cache mỏng hơn ngưỡng này coi như "gần như trống" (máy cài từ bản cũ chỉ có
  /// vài kỳ) → lần đồng bộ kế tiếp tải bù cả cửa sổ bootstrap một lần.
  ///
  /// Ngưỡng nhỏ để giữ nguyên tính chất "chỉ tải phần còn thiếu" cho máy đã có
  /// dữ liệu thật: cache đủ sâu thì không gọi lại nguồn khi đã mới nhất.
  static const int shallowHistoryDays = 31;

  /// Cửa sổ ngày tối thiểu phải có trong cache: `bootstrapSyncDays` (365) hoặc
  /// `days` nếu caller yêu cầu rộng hơn.
  int _syncWindow(int days) =>
      days < AppConfig.bootstrapSyncDays ? AppConfig.bootstrapSyncDays : days;

  /// Số ngày lịch sử cache đang có cho một miền (`0` nếu cache trống).
  ///
  /// Dùng để phát hiện máy đã cài từ bản cũ chỉ có vài kỳ: khi đó lần đồng bộ kế
  /// tiếp phải tải bù cả cửa sổ thay vì chỉ ngày kế tiếp.
  Future<int> _cachedHistoryDays(Region region, DateTime today) async {
    final oldest = await store.loadDraws(
      region: region,
      limit: 1,
      ascending: true,
    );
    if (oldest.isEmpty) return 0;
    final date = parseIsoDate(oldest.first.date);
    if (date == null) return 0;
    return today.difference(date).inDays + 1;
  }

  /// Đồng bộ theo khoảng ngày; trả về báo cáo cho màn hình Nguồn dữ liệu.
  Future<SyncReport> sync({
    required Region region,
    int days = AppConfig.defaultSyncDays,
    bool force = false,
  }) async {
    final startedAt = _clock().toIso8601String();
    await open();

    final today = todayInVietnam(now: _clock());
    final latest = await store.latestDrawDate(region);
    final latestDate = latest == null ? null : parseIsoDate(latest);

    final window = _syncWindow(days);
    DateTime start;
    if (latestDate == null) {
      // Cache trống (cài mới hoặc đổi máy): tải tối thiểu `bootstrapSyncDays`
      // để các tab thống kê/backtest có đủ dữ liệu ngay lần mở đầu tiên.
      start = today.subtract(Duration(days: window - 1));
    } else if (force) {
      start = today.subtract(const Duration(days: 2));
      if (latestDate.isBefore(start)) start = latestDate;
    } else {
      // Máy đã có dữ liệu: cache gần như trống (bản cũ chỉ lưu vài kỳ) ⇒ tải bù cả
      // cửa sổ bootstrap, không cần xoá app. Cache đủ sâu ⇒ chỉ tải ngày còn thiếu.
      final cachedDays = await _cachedHistoryDays(region, today);
      start = cachedDays < shallowHistoryDays
          ? today.subtract(Duration(days: window - 1))
          : latestDate.add(const Duration(days: 1));
    }

    if (start.isAfter(today)) {
      final report = SyncReport(
        region: region,
        status: SyncOutcome.upToDate,
        provider: 'không cần gọi',
        startedAt: startedAt,
        finishedAt: _clock().toIso8601String(),
        latestDate: latest,
        messages: <String>['Dữ liệu đã tới $latest.'],
      );
      await _writeHistory(report);
      await _persistDatasetMeta(region: region, report: report);
      return report;
    }

    _logger.info(
      'repository',
      'Đồng bộ ${region.code}: ${isoDate(start)} → ${isoDate(today)}',
    );

    final outcome = start == today
        ? await chain.fetchByDate(region: region, date: start)
        : await chain.fetchRange(region: region, start: start, end: today);

    if (outcome.result == null) {
      final report = SyncReport.failed(
        region: region,
        startedAt: startedAt,
        messages: <String>['Không nguồn nào trả dữ liệu.', ...outcome.messages],
        attemptedProviders: <String>[
          for (final attempt in outcome.attempts) attempt.provider,
        ],
      );
      await _writeHistory(report);
      return report;
    }

    final fetched = outcome.result!.draws
        .where((draw) => parseIsoDate(draw.date) != null)
        .where((draw) => !parseIsoDate(draw.date)!.isBefore(start))
        .toList(growable: false);

    final invalid = validateDraws(fetched);
    final valid = <DrawRecord>[
      for (final draw in fetched)
        if (!invalid.containsKey(draw.key)) draw,
    ];
    for (final entry in invalid.entries) {
      _logger.warning('repository', 'Loại ${entry.key}: ${entry.value.first}');
    }

    final upsert = await store.upsertDraws(valid);
    // Không có kỳ hợp lệ nào ⇒ coi là thất bại: nếu báo "thành công" thì UI sẽ
    // tưởng dữ liệu đã đầy đủ trong khi cache vẫn trống.
    final status = valid.isEmpty
        ? SyncOutcome.failed
        : (invalid.isEmpty ? SyncOutcome.success : SyncOutcome.partial);
    final report = SyncReport(
      region: region,
      status: status,
      provider: outcome.result!.provider,
      startedAt: startedAt,
      finishedAt: _clock().toIso8601String(),
      inserted: upsert.inserted,
      updated: upsert.updated,
      rejected: invalid.length,
      latestDate: await store.latestDrawDate(region),
      attemptedProviders: <String>[
        for (final attempt in outcome.attempts) attempt.provider,
      ],
      messages: <String>[
        if (valid.isEmpty)
          'Không có kỳ hợp lệ nào để lưu (nhận ${fetched.length} kỳ).',
        ...outcome.result!.warnings,
        if (invalid.isNotEmpty)
          '${invalid.length} kỳ bị loại vì sai cơ cấu giải.',
        ...outcome.messages,
      ],
    );
    _logger.info('repository', 'Đồng bộ xong: ${report.summary}');
    await _writeHistory(report);
    if (report.status == SyncOutcome.success ||
        report.status == SyncOutcome.partial) {
      await _persistDatasetMeta(region: region, report: report);
    }
    return report;
  }

  /// Ghi `dataset_meta` sau khi cache đã có dữ liệu hợp lệ (STEP 5/8).
  ///
  /// `datasetVersion`/`datasetDate` lấy từ `/v1/health`; nếu API không trả thì
  /// vẫn lưu ngày mới nhất trong cache để lần mở app sau biết đang ở đâu.
  Future<void> _persistDatasetMeta({
    required Region region,
    required SyncReport report,
  }) async {
    final client = api;
    var source = dataSourceFromProviderName(report.provider);
    String? datasetVersion;
    String? datasetDate = report.latestDate;
    if (client != null && LotteryApiClient.supportedRegions.contains(region)) {
      try {
        final health = await client.health();
        datasetVersion = health.datasetVersion;
        datasetDate = health.datasetDate ?? datasetDate;
        source = DataSourceKind.cloudflare;
      } on LotteryApiException catch (error) {
        _logger.warning(
          'repository',
          'Không đọc được /health để lưu dataset_meta: ${error.message}',
        );
      }
    }
    await saveDatasetMeta(
      DatasetMeta(
        region: region,
        source: source,
        fetchedAt: report.finishedAt,
        datasetVersion: datasetVersion,
        datasetDate: datasetDate,
        apiHost: await _currentApiHost(),
        recordCount: report.inserted + report.updated,
      ),
    );
  }

  /// Host API đang dùng, hoặc `null` khi app chạy hoàn toàn offline.
  Future<String?> _currentApiHost() async {
    final loader = apiBaseUrlLoader;
    if (loader == null) return null;
    try {
      return Uri.parse(await loader()).host;
    } catch (error) {
      _logger.warning('repository', 'Không đọc được URL API: $error');
      return null;
    }
  }

  Future<void> _writeHistory(SyncReport report) async {
    try {
      await store.addSyncHistory(
        SyncHistoryRecord(
          region: report.region,
          startedAt: report.startedAt,
          finishedAt: report.finishedAt,
          provider: report.provider,
          status: report.status,
          inserted: report.inserted,
          updated: report.updated,
          rejected: report.rejected,
          note: report.messages.isEmpty ? null : report.messages.first,
        ),
      );
    } catch (error) {
      _logger.warning('repository', 'Không ghi được sync_history: $error');
    }
  }
}
