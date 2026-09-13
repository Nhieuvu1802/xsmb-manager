/// Model dùng chung cho **toàn bộ** luồng dữ liệu của app (STEP 5).
///
/// Một kỳ quay chỉ có một hình dạng dữ liệu duy nhất đi qua mọi tầng:
///
/// ```text
/// JSON của API v1 (Worker)      →  model dữ liệu            →  model UI (domain)
/// draws[].results[].prize       →  DrawRecord / PrizeRecord →  LotteryDraw / PrizeResult
/// draws[].station               →  LotteryStation           →  LotteryDraw.station
/// datasetVersion / datasetDate  →  DatasetMeta              →  SystemStatus
/// ```
///
/// Nhờ vậy client API, cache SQLite/bộ nhớ và giao diện không còn mỗi nơi hiểu
/// một kiểu: đổi hợp đồng JSON chỉ cần sửa `DrawRecord.fromJson` và
/// [DatasetMeta], phần còn lại giữ nguyên.
library;

import '../../domain/lottery_domain.dart';
import 'draw_record.dart';

/// Kỳ quay đã chuẩn hoá (một đài trong một ngày).
///
/// `DrawRecord` là hiện thực duy nhất của kiểu này; bí danh được khai báo để
/// code mới (thống kê, backtest, UI) đọc đúng tên miền nghiệp vụ.
typedef LotteryResult = DrawRecord;

/// Một đài/tỉnh phát hành kết quả (miền Bắc là hội đồng duy nhất của miền).
class LotteryStation {
  const LotteryStation({
    required this.name,
    required this.region,
    this.code,
    this.weekday,
  });

  /// Tên hiển thị, cũng là khoá đài trong cache (`draws.station`).
  final String name;

  final Region region;

  /// Mã đài nếu API cung cấp (ví dụ `long_an`); mặc định suy ra từ [name].
  final String? code;

  /// Thứ trong tuần đài quay (1 = thứ Hai … 7 = Chủ Nhật), `null` nếu chưa biết.
  final int? weekday;

  /// Mã đài ổn định để so sánh/khử trùng: ưu tiên `code`, nếu không có thì
  /// chuẩn hoá tên (bỏ dấu cách, viết thường).
  String get id =>
      code ?? name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  bool get isNorthernBoard => region == Region.mienBac;

  factory LotteryStation.fromJson(
    Map<String, dynamic> json, {
    Region? region,
  }) => LotteryStation(
    name: (json['name'] ?? json['station'] ?? json['province'] ?? '')
        .toString(),
    region: region ?? regionFromCode(json['region']?.toString()),
    code: (json['code'] ?? json['station_code'])?.toString(),
    weekday: (json['weekday'] as num?)?.toInt(),
  );

  /// Trạm mặc định khi API không nêu tên đài.
  factory LotteryStation.defaultFor(Region region) =>
      LotteryStation(name: DrawRecord.defaultStation(region), region: region);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'region': region.code,
    if (code != null) 'code': code,
    if (weekday != null) 'weekday': weekday,
  };
}

/// Nguồn đang thực sự phục vụ dữ liệu cho người dùng.
enum DataSourceKind { cloudflare, github, cache, sample, none }

extension DataSourceKindInfo on DataSourceKind {
  /// Nhãn hiển thị trên UI (đã phân biệt rõ dữ liệu thật và dữ liệu offline).
  String get label => switch (this) {
    DataSourceKind.cloudflare => 'Cloudflare Worker API',
    DataSourceKind.github => 'GitHub snapshot (dự phòng)',
    DataSourceKind.cache => 'Bộ nhớ máy (offline)',
    DataSourceKind.sample => 'Dữ liệu mẫu có seed',
    DataSourceKind.none => 'Chưa có nguồn dữ liệu',
  };

  /// `true` khi dữ liệu vừa được lấy từ mạng trong phiên hiện tại.
  bool get isLive =>
      this == DataSourceKind.cloudflare || this == DataSourceKind.github;

  /// Nguồn có cần mạng hay không (để hiển thị cảnh báo offline).
  bool get needsNetwork => isLive;
}

/// Suy ra [DataSourceKind] từ tên nguồn trong `provider_status`/`sync_history`.
DataSourceKind dataSourceFromProviderName(String? provider) {
  final name = (provider ?? '').toLowerCase();
  if (name.isEmpty || name.startsWith('không')) return DataSourceKind.none;
  if (name.contains('api')) return DataSourceKind.cloudflare;
  if (name.contains('github')) return DataSourceKind.github;
  if (name.contains('bộ nhớ') || name.contains('cache')) {
    return DataSourceKind.cache;
  }
  if (name.contains('mẫu') || name.contains('sample')) {
    return DataSourceKind.sample;
  }
  return DataSourceKind.cache;
}

/// Metadata của dataset mà thiết bị đã tải về cho **một vùng**.
///
/// Đây là chỗ duy nhất lưu `datasetVersion`/`datasetDate` của API để lần mở app
/// sau biết cache đang ở phiên bản nào, kể cả khi không có mạng.
class DatasetMeta {
  const DatasetMeta({
    required this.region,
    required this.source,
    required this.fetchedAt,
    this.datasetVersion,
    this.datasetDate,
    this.apiHost,
    this.recordCount = 0,
  });

  final Region region;
  final DataSourceKind source;

  /// Thời điểm tải xong (ISO-8601, giờ máy).
  final String fetchedAt;

  /// Phiên bản dataset do API công bố (`/v1/health`, `/v1/manifest`).
  final String? datasetVersion;

  /// Ngày của kỳ mới nhất trong dataset (`yyyy-MM-dd`).
  final String? datasetDate;

  /// Host API đã dùng khi tải (để phát hiện đổi endpoint).
  final String? apiHost;

  /// Số kỳ đã ghi vào cache trong lần tải này.
  final int recordCount;

  /// Metadata rỗng (chưa từng tải) — vẫn hợp lệ để ghi/đọc.
  factory DatasetMeta.empty(Region region) =>
      DatasetMeta(region: region, source: DataSourceKind.none, fetchedAt: '');

  bool get isEmpty => fetchedAt.isEmpty && recordCount == 0;

  String get sourceLabel => source.label;

  DatasetMeta copyWith({
    DataSourceKind? source,
    String? fetchedAt,
    String? datasetVersion,
    String? datasetDate,
    String? apiHost,
    int? recordCount,
  }) => DatasetMeta(
    region: region,
    source: source ?? this.source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    datasetVersion: datasetVersion ?? this.datasetVersion,
    datasetDate: datasetDate ?? this.datasetDate,
    apiHost: apiHost ?? this.apiHost,
    recordCount: recordCount ?? this.recordCount,
  );

  Map<String, Object?> toRow() => <String, Object?>{
    'region': region.code,
    'source': source.name,
    'fetched_at': fetchedAt,
    'dataset_version': datasetVersion,
    'dataset_date': datasetDate,
    'api_host': apiHost,
    'record_count': recordCount,
  };

  factory DatasetMeta.fromRow(Map<String, Object?> row) => DatasetMeta(
    region: regionFromCode(row['region']?.toString()),
    source: _sourceFromName(row['source']?.toString()),
    fetchedAt: (row['fetched_at'] ?? '').toString(),
    datasetVersion: row['dataset_version']?.toString(),
    datasetDate: row['dataset_date']?.toString(),
    apiHost: row['api_host']?.toString(),
    recordCount: (row['record_count'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'region': region.code,
    'source': source.name,
    'fetchedAt': fetchedAt,
    'datasetVersion': datasetVersion,
    'datasetDate': datasetDate,
    'apiHost': apiHost,
    'recordCount': recordCount,
  };

  factory DatasetMeta.fromJson(Map<String, dynamic> json) => DatasetMeta(
    region: regionFromCode(json['region']?.toString()),
    source: _sourceFromName(json['source']?.toString()),
    fetchedAt: (json['fetchedAt'] ?? '').toString(),
    datasetVersion: json['datasetVersion']?.toString(),
    datasetDate: json['datasetDate']?.toString(),
    apiHost: json['apiHost']?.toString(),
    recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
  );

  static DataSourceKind _sourceFromName(String? name) =>
      DataSourceKind.values.firstWhere(
        (item) => item.name == name,
        orElse: () => DataSourceKind.none,
      );
}

/// Trạng thái hệ thống hiển thị ở màn hình "Trạng thái" (STEP 11).
///
/// Gồm 8 thông tin bắt buộc: API online/offline, endpoint, ngày dataset, phiên
/// bản dataset, lần đồng bộ thành công gần nhất, ngày cache, nguồn hiện tại và
/// phiên bản ứng dụng.
class SystemStatus {
  const SystemStatus({
    required this.region,
    required this.apiBaseUrl,
    required this.apiHost,
    required this.apiOnline,
    required this.source,
    this.sourceNote = '',
    this.datasetDate,
    this.datasetVersion,
    this.lastSuccessfulSyncAt,
    this.lastSyncProvider,
    this.cacheDate,
    this.cacheDraws = 0,
    this.cacheResults = 0,
    this.checkedAt,
    this.apiReportedBaseUrl,
    this.appVersion = '',
  });

  final Region region;

  /// URL API app đang gọi (đã gồm `/v1`).
  final String apiBaseUrl;

  final String apiHost;

  /// `/v1/health` có trả `status: ok` hay không.
  final bool apiOnline;

  /// Nguồn đang phục vụ số liệu cho UI.
  final DataSourceKind source;

  /// Ghi chú thêm về nguồn (ví dụ lý do phải dùng cache).
  final String sourceNote;

  /// Ngày kỳ mới nhất theo API (`/v1/health.datasetDate`).
  final String? datasetDate;

  /// Phiên bản dataset theo API (`/v1/health.datasetVersion`).
  final String? datasetVersion;

  /// Thời điểm đồng bộ thành công gần nhất (`sync_history.finished_at`).
  final String? lastSuccessfulSyncAt;

  /// Nguồn của lần đồng bộ thành công gần nhất.
  final String? lastSyncProvider;

  /// Ngày mới nhất có trong cache thiết bị.
  final String? cacheDate;

  final int cacheDraws;
  final int cacheResults;

  /// Thời điểm dựng trạng thái này (ISO-8601).
  final String? checkedAt;

  /// `apiBaseUrl` do server tự khai trong `/v1/config` (có thể khác URL app
  /// đang dùng khi host mới chưa hoạt động).
  final String? apiReportedBaseUrl;

  final String appVersion;

  bool get hasCache => cacheDraws > 0;

  String get apiStatusLabel => apiOnline ? 'Online' : 'Offline';

  String get datasetDateLabel => datasetDate ?? '—';

  String get datasetVersionLabel => shortVersion(datasetVersion);

  String get cacheDateLabel => cacheDate ?? '—';

  String get sourceLabel => source.label;

  String get lastSyncLabel {
    final value = lastSuccessfulSyncAt;
    if (value == null || value.isEmpty) return 'Chưa đồng bộ';
    return '${formatIsoMoment(value)}'
        '${lastSyncProvider == null ? '' : ' · $lastSyncProvider'}';
  }

  /// Cache đang chậm hơn dataset của API ít nhất một kỳ.
  bool get cacheBehindApi {
    final remote = datasetDate;
    final local = cacheDate;
    if (remote == null || local == null) return false;
    return remote.compareTo(local) > 0;
  }

  /// `true` khi server khai một URL khác URL app đang gọi (GAP tiềm ẩn).
  bool get hasEndpointMismatch {
    final reported = apiReportedBaseUrl;
    if (reported == null || reported.isEmpty) return false;
    return reported.replaceAll(RegExp(r'/+$'), '') !=
        apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  /// Câu tóm tắt một dòng cho thẻ trạng thái.
  String get summary {
    if (!apiOnline && !hasCache) {
      return 'Không có mạng và chưa có dữ liệu ngoại tuyến.';
    }
    if (!apiOnline) {
      return 'Đang dùng dữ liệu ngoại tuyến (kỳ $cacheDateLabel).';
    }
    if (cacheBehindApi) {
      return 'API có kỳ mới hơn cache ($datasetDateLabel > $cacheDateLabel).';
    }
    return 'API và cache đã đồng bộ.';
  }

  /// Trạng thái chưa kiểm tra (dùng làm giá trị khởi tạo cho UI).
  factory SystemStatus.pending({
    required Region region,
    required String apiBaseUrl,
    required String apiHost,
    required DataSourceKind source,
    String appVersion = '',
    int cacheDraws = 0,
    int cacheResults = 0,
    String? cacheDate,
    String? lastSuccessfulSyncAt,
    String? lastSyncProvider,
  }) => SystemStatus(
    region: region,
    apiBaseUrl: apiBaseUrl,
    apiHost: apiHost,
    apiOnline: false,
    source: source,
    datasetDate: null,
    datasetVersion: null,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt,
    lastSyncProvider: lastSyncProvider,
    cacheDate: cacheDate,
    cacheDraws: cacheDraws,
    cacheResults: cacheResults,
    appVersion: appVersion,
  );
}

/// Rút gọn `datasetVersion` dài thành dạng dễ đọc trên UI.
String shortVersion(String? value, {int head = 8, int tail = 4}) {
  if (value == null || value.isEmpty) return '—';
  if (value.length <= head + tail + 1) return value;
  return '${value.substring(0, head)}…${value.substring(value.length - tail)}';
}

/// `2026-09-13T02:37:39.787Z` → `13/09/2026 09:37` (giờ Việt Nam, UTC+7).
String formatIsoMoment(String iso, {bool withDate = true}) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final vn = parsed.toUtc().add(const Duration(hours: 7));
  String two(int value) => value.toString().padLeft(2, '0');
  final clock = '${two(vn.hour)}:${two(vn.minute)}';
  if (!withDate) return clock;
  return '${two(vn.day)}/${two(vn.month)}/${vn.year} $clock';
}
