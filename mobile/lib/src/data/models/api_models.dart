/// Model metadata của API Worker v1: `/health`, `/manifest`, `/config`.
///
/// Parser chịu được field thiếu (trả giá trị mặc định) nhưng từ chối kiểu dữ
/// liệu sai — nhờ vậy một field lỗi không làm sập cả app.
library;

/// Đọc chuỗi an toàn từ JSON.
String jsonString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Đọc số nguyên an toàn từ JSON.
int jsonInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Đọc boolean an toàn từ JSON.
bool jsonBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final value = json[key];
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

/// Đọc danh sách chuỗi an toàn từ JSON.
List<String> jsonStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) return const <String>[];
  return <String>[
    for (final item in value)
      if (item != null) item.toString(),
  ];
}

/// Tóm tắt một vùng dữ liệu trong `/health` và `/manifest`.
class ApiRegionSummary {
  const ApiRegionSummary({
    this.date,
    this.draws = 0,
    this.prizesPerDraw,
    this.stations = const <String>[],
  });

  /// Ngày của kỳ mới nhất vùng này (`yyyy-MM-dd`).
  final String? date;

  /// Số kỳ (miền Bắc luôn 1, miền Nam = số đài trong ngày).
  final int draws;

  /// Số số mỗi kỳ (27 với XSMB, 18 với mỗi đài XSMN).
  final int? prizesPerDraw;

  /// Danh sách đài/tỉnh của kỳ mới nhất (chỉ có ở XSMN).
  final List<String> stations;

  factory ApiRegionSummary.fromJson(Map<String, dynamic> json) =>
      ApiRegionSummary(
        date: json['date']?.toString(),
        draws: jsonInt(json, 'draws'),
        prizesPerDraw: json['prizesPerDraw'] is num
            ? jsonInt(json, 'prizesPerDraw')
            : null,
        stations: jsonStringList(json, 'stations'),
      );

  /// Đọc bản đồ `{region: summary}`.
  static Map<String, ApiRegionSummary> mapFrom(dynamic value) {
    if (value is! Map) return const <String, ApiRegionSummary>{};
    final result = <String, ApiRegionSummary>{};
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is Map<String, dynamic>) {
        result[entry.key.toString()] = ApiRegionSummary.fromJson(item);
      }
    }
    return result;
  }
}

/// Trạng thái `/v1/health`.
class ApiHealth {
  const ApiHealth({
    required this.status,
    this.apiVersion = 'v1',
    this.datasetDate,
    this.datasetVersion,
    this.generatedAt,
    this.database,
    this.environment,
    this.lastDataUpdate,
    this.providers = const <String>[],
    this.regions = const <String, ApiRegionSummary>{},
  });

  final String status;
  final String apiVersion;
  final String? datasetDate;
  final String? datasetVersion;
  final String? generatedAt;
  final String? database;
  final String? environment;
  final String? lastDataUpdate;
  final List<String> providers;
  final Map<String, ApiRegionSummary> regions;

  /// API báo khoẻ (`status == "ok"`).
  bool get isOk => status.toLowerCase() == 'ok';

  /// Có dataset dùng được (có ngày và version).
  bool get hasDataset =>
      (datasetDate ?? '').isNotEmpty && (datasetVersion ?? '').isNotEmpty;

  /// Ngày mới nhất của một vùng (`xsmb`/`xsmn`), mặc định là datasetDate.
  String? regionDate(String region) => regions[region]?.date ?? datasetDate;

  static const ApiHealth unknown = ApiHealth(status: 'unknown');

  factory ApiHealth.fromJson(Map<String, dynamic> json) {
    final status = jsonString(json, 'status');
    return ApiHealth(
      status: status.isEmpty ? 'unknown' : status,
      apiVersion: jsonString(json, 'apiVersion', fallback: 'v1'),
      datasetDate: nullableText(jsonString(json, 'datasetDate')),
      datasetVersion: nullableText(jsonString(json, 'datasetVersion')),
      generatedAt: nullableText(jsonString(json, 'generatedAt')),
      database: nullableText(jsonString(json, 'database')),
      environment: nullableText(jsonString(json, 'environment')),
      lastDataUpdate: nullableText(jsonString(json, 'lastDataUpdate')),
      providers: jsonStringList(json, 'providers'),
      regions: ApiRegionSummary.mapFrom(json['regions']),
    );
  }
}

/// Một file trong `/v1/manifest`.
class ApiManifestFile {
  const ApiManifestFile({required this.path, this.sha256, this.bytes = 0});

  final String path;
  final String? sha256;
  final int bytes;

  factory ApiManifestFile.fromJson(String path, Map<String, dynamic> json) =>
      ApiManifestFile(
        path: path,
        sha256: nullableText(jsonString(json, 'sha256')),
        bytes: jsonInt(json, 'bytes'),
      );
}

/// Manifest dataset mà Worker đang phục vụ.
class ApiManifest {
  const ApiManifest({
    this.schemaVersion = 1,
    this.apiVersion = 'v1',
    this.generatedAt,
    this.datasetVersion,
    this.xsmbLatestDate,
    this.xsmnLatestDate,
    this.servedBy,
    this.files = const <String, ApiManifestFile>{},
    this.regions = const <String, ApiRegionSummary>{},
  });

  final int schemaVersion;
  final String apiVersion;
  final String? generatedAt;
  final String? datasetVersion;
  final String? xsmbLatestDate;
  final String? xsmnLatestDate;
  final String? servedBy;
  final Map<String, ApiManifestFile> files;
  final Map<String, ApiRegionSummary> regions;

  /// Ngày mới nhất của một vùng (`xsmb`/`xsmn`).
  String? latestDate(String region) =>
      region == 'xsmn' ? xsmnLatestDate : xsmbLatestDate;

  factory ApiManifest.fromJson(Map<String, dynamic> json) {
    final files = <String, ApiManifestFile>{};
    final rawFiles = json['files'];
    if (rawFiles is Map) {
      for (final entry in rawFiles.entries) {
        final item = entry.value;
        if (item is Map<String, dynamic>) {
          final path = entry.key.toString();
          files[path] = ApiManifestFile.fromJson(path, item);
        }
      }
    }
    return ApiManifest(
      schemaVersion: jsonInt(json, 'schemaVersion', fallback: 1),
      apiVersion: jsonString(json, 'apiVersion', fallback: 'v1'),
      generatedAt: nullableText(jsonString(json, 'generatedAt')),
      datasetVersion: nullableText(jsonString(json, 'datasetVersion')),
      xsmbLatestDate: nullableText(jsonString(json, 'xsmbLatestDate')),
      xsmnLatestDate: nullableText(jsonString(json, 'xsmnLatestDate')),
      servedBy: nullableText(jsonString(json, 'servedBy')),
      files: files,
      regions: ApiRegionSummary.mapFrom(json['regions']),
    );
  }
}

/// Nội dung `/v1/config` (cấu hình công khai do server trả về).
class ApiRemoteConfig {
  const ApiRemoteConfig({
    this.apiBaseUrl,
    this.apiVersion = 'v1',
    this.fallbackDataUrl,
    this.minimumAppVersion,
    this.maintenance = false,
    this.githubFallbackEnabled = true,
  });

  final String? apiBaseUrl;
  final String apiVersion;
  final String? fallbackDataUrl;
  final String? minimumAppVersion;
  final bool maintenance;
  final bool githubFallbackEnabled;

  factory ApiRemoteConfig.fromJson(Map<String, dynamic> json) =>
      ApiRemoteConfig(
        apiBaseUrl: nullableText(jsonString(json, 'apiBaseUrl')),
        apiVersion: jsonString(json, 'apiVersion', fallback: 'v1'),
        fallbackDataUrl: nullableText(jsonString(json, 'fallbackDataUrl')),
        minimumAppVersion: nullableText(jsonString(json, 'minimumAppVersion')),
        maintenance: jsonBool(json, 'maintenance'),
        githubFallbackEnabled: jsonBool(
          json,
          'githubFallbackEnabled',
          fallback: true,
        ),
      );
}

/// Chuỗi rỗng → `null` cho các field tuỳ chọn.
String? nullableText(String value) => value.isEmpty ? null : value;
