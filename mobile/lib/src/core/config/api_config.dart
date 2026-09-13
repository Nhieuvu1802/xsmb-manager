/// Cấu hình API tập trung — nguồn duy nhất cho mọi URL mạng của ứng dụng.
///
/// Quy tắc của dự án: provider/repository/client **chỉ** lấy URL từ đây,
/// không hard-code host ở bất kỳ file nào khác. Nhờ vậy khi chuyển API từ
/// `https://xsmb-api.nhieuvu1802.workers.dev` sang `https://api.vvn.freedev.app`
/// chỉ cần đổi một chỗ (hoặc truyền `--dart-define=API_BASE_URL=...`), không
/// phải sửa business logic.
///
/// Không có secret nào trong file này: mọi giá trị đều là thông tin công khai.
library;

class ApiConfig {
  const ApiConfig._();

  // ---------------------------------------------------------------- phiên bản

  /// Phiên bản API; cũng là hậu tố bắt buộc của [baseUrl].
  static const String apiVersion = 'v1';

  /// Tiền tố đường dẫn đầy đủ của phiên bản API (`/v1`).
  static String get versionPath => '/$apiVersion';

  // ---------------------------------------------------------------- host

  /// Host production đang dùng: Cloudflare Worker.
  static const String workerHost = 'xsmb-api.nhieuvu1802.workers.dev';

  /// Base URL Worker chưa gồm phiên bản.
  static const String workerBaseUrl = 'https://$workerHost';

  /// Host dự kiến khi đã có quyền DNS cho zone `freedev.app`.
  static const String plannedHost = 'api.vvn.freedev.app';

  /// Base URL tương lai (chưa hoạt động, chưa có DNS record).
  static const String plannedBaseUrl = 'https://$plannedHost';

  /// Cho phép ghi đè lúc build:
  /// `flutter build apk --release --dart-define=API_BASE_URL=https://api.vvn.freedev.app/v1`
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL API đang dùng, luôn ở dạng `https://host/v1`.
  static String get baseUrl => normalizeBaseUrl(
    _overrideBaseUrl.isEmpty ? workerBaseUrl : _overrideBaseUrl,
  );

  /// Bí danh rõ nghĩa cho [baseUrl] khi ghép với các endpoint cụ thể.
  static String get primaryApiUrl => baseUrl;

  /// Host đang gọi (hiển thị ở màn hình Trạng thái / Cài đặt).
  static String get host => Uri.parse(baseUrl).host;

  /// `true` khi app đang trỏ tới Worker production mặc định.
  static bool get isDefaultEndpoint =>
      baseUrl == normalizeBaseUrl(workerBaseUrl);

  /// `true` khi URL đang dùng là host dự kiến trong tương lai.
  static bool get isPlannedEndpoint => host == plannedHost;

  // ---------------------------------------------------------------- fallback

  /// Snapshot JSON công khai chỉ đọc trên GitHub (nguồn dự phòng thứ hai).
  ///
  /// Lưu ý STEP 8: repository `Nhieuvu1802/xsmb-manager` hiện **private** nên
  /// `raw.githubusercontent.com/.../public-data/...` trả 404. Vì vậy nguồn này
  /// mặc định **tắt** ([githubFallbackEnabled] = false) và app chỉ dùng cache
  /// cục bộ + thử lại Worker. Khi repo/public-data được công khai (hoặc snapshot
  /// được host trên một origin công khai), bật lại bằng:
  /// `--dart-define=GITHUB_FALLBACK_ENABLED=true`.
  static const String githubPublicDataBaseUrl = String.fromEnvironment(
    'GITHUB_PUBLIC_DATA_BASE_URL',
    defaultValue:
        'https://raw.githubusercontent.com/Nhieuvu1802/xsmb-manager/main/public-data',
  );

  /// Nguồn dự phòng GitHub có được bật hay không (mặc định tắt — xem ghi chú).
  static const bool githubFallbackEnabled = bool.fromEnvironment(
    'GITHUB_FALLBACK_ENABLED',
    defaultValue: false,
  );

  // ---------------------------------------------------------------- tham số mạng

  /// Thời gian chờ mỗi lần gọi mạng.
  static const Duration requestTimeout = Duration(seconds: 12);

  /// Số lần thử tối đa cho một request (1 lần gốc + retry).
  static const int maxAttempts = 3;

  /// Chờ giữa hai lần thử.
  static const Duration retryDelay = Duration(milliseconds: 400);

  /// User-Agent chung cho các request công khai.
  static const String userAgent =
      'VVN-Lottery/2.0 (Flutter; +https://vvn.freedev.app)';

  // ---------------------------------------------------------------- tuỳ chọn app

  /// Khoá SharedPreferences lưu URL API người dùng tự đổi trong Cài đặt.
  static const String apiBaseUrlKey = 'xsmb-manager:api-base-url';

  /// Số ngày tối đa lấy về trong một lần đồng bộ mặc định.
  static const int defaultSyncDays = 30;

  /// Số ngày tải ở lần đầu (bootstrap) để đủ dữ liệu cho thống kê/backtest.
  ///
  /// Cache trống → tải `bootstrapSyncDays` ngày gần nhất; sau đó chỉ tải phần
  /// còn thiếu. Nhờ vậy màn hình thống kê có ngay ~1 năm kỳ để tính.
  static const int bootstrapSyncDays = 365;

  /// Số kỳ tối đa giữ trong bộ nhớ để tính thống kê / backtest.
  static const int maxDrawsInMemory = 3000;

  // ---------------------------------------------------------------- endpoint

  /// Ghép `path` vào [baseUrl], kèm query nếu có.
  static Uri endpoint(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  /// `GET /v1/health`
  static Uri health() => endpoint('/health');

  /// `GET /v1/config`
  static Uri publicConfig() => endpoint('/config');

  /// `GET /v1/manifest`
  static Uri manifest() => endpoint('/manifest');

  /// `GET /v1/{xsmb|xsmn}/latest?days=n`
  static Uri latest(String regionPath, {int? days}) =>
      endpoint('/$regionPath/latest', <String, String>{
        if (days != null) 'days': '$days',
      });

  /// `GET /v1/{xsmb|xsmn}/{yyyy-MM-dd}`
  static Uri byDate(String regionPath, String isoDate) =>
      endpoint('/$regionPath/$isoDate');

  /// `GET /v1/{xsmb|xsmn}/history` theo khoảng ngày hoặc số ngày gần nhất.
  static Uri history(
    String regionPath, {
    String? start,
    String? end,
    int? days,
  }) => endpoint('/$regionPath/history', <String, String>{
    if (start != null) 'start': start,
    if (end != null) 'end': end,
    if (days != null) 'days': '$days',
  });

  /// Chuẩn hoá URL API: bỏ dấu `/` cuối, thêm `/v1` nếu thiếu, ném
  /// [FormatException] nếu không phải URL http(s) hợp lệ.
  static String normalizeBaseUrl(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    var uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'URL API phải bắt đầu bằng http:// hoặc https:// và có tên máy chủ.',
      );
    }
    if (uri.path.isEmpty) {
      normalized = '$normalized/$apiVersion';
      uri = Uri.parse(normalized);
    }
    if (!uri.path.endsWith('/$apiVersion')) {
      throw const FormatException('URL API phải kết thúc bằng /v1.');
    }
    return normalized;
  }
}
