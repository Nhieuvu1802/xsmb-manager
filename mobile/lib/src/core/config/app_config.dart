/// Cấu hình build-time của ứng dụng.
///
/// URL API, tham số mạng và endpoint được định nghĩa **một chỗ** trong
/// `api_config.dart` ([ApiConfig]); lớp này chỉ giữ các khoá SharedPreferences
/// của app và các bí danh tương thích cho code cũ.
///
/// Không có secret nào nằm trong file này. URL API có thể đổi lúc build:
/// `flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/v1`
/// và người dùng vẫn có thể đổi trong màn hình Cài đặt (lưu bằng
/// SharedPreferences).
library;

import 'api_config.dart';

class AppConfig {
  const AppConfig._();

  /// API production chính (Cloudflare Worker). Giá trị đã gồm prefix `/v1`.
  static String get defaultApiBaseUrl => ApiConfig.baseUrl;

  /// Dữ liệu public chỉ đọc trên GitHub, dùng khi API production không đáp ứng.
  static const String defaultGitHubPublicDataBaseUrl =
      ApiConfig.githubPublicDataBaseUrl;

  /// Nguồn dự phòng GitHub có được bật hay không (mặc định tắt — xem
  /// `ApiConfig.githubFallbackEnabled`).
  static const bool githubFallbackEnabled = ApiConfig.githubFallbackEnabled;

  /// Phiên bản ứng dụng hiển thị ở màn hình Trạng thái.
  ///
  /// Ghi đè lúc build:
  /// `--dart-define=APP_VERSION=2.0.0 --dart-define=APP_BUILD=42`
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '2.0.0',
  );

  /// Số build (CI gán); `local` khi chạy trực tiếp từ máy.
  static const String appBuild = String.fromEnvironment(
    'APP_BUILD',
    defaultValue: 'local',
  );

  /// Nhãn gọn `2.0.0+local` cho UI.
  static String get appVersionLabel => '$appVersion+$appBuild';

  /// API có phải là bản production mặc định (Worker) hay không.
  static bool get apiIsDefaultEndpoint => ApiConfig.isDefaultEndpoint;

  /// Thời gian chờ mỗi lần gọi mạng.
  static const Duration requestTimeout = ApiConfig.requestTimeout;

  /// Số lần thử tối đa cho một request (1 lần gốc + retry).
  static const int maxAttempts = ApiConfig.maxAttempts;

  /// Chờ giữa hai lần thử.
  static const Duration retryDelay = ApiConfig.retryDelay;

  /// Số ngày tối đa lấy về trong một lần đồng bộ mặc định.
  static const int defaultSyncDays = ApiConfig.defaultSyncDays;

  /// Số ngày tải ở lần đầu khi cache còn trống (STEP 11/12 cần ≥ 1 năm kỳ).
  static const int bootstrapSyncDays = ApiConfig.bootstrapSyncDays;

  /// Số kỳ tối đa giữ trong bộ nhớ để tính thống kê / backtest.
  static const int maxDrawsInMemory = ApiConfig.maxDrawsInMemory;

  /// User-Agent chung cho các request public.
  static const String userAgent = ApiConfig.userAgent;

  /// Khoá SharedPreferences.
  static const String apiBaseUrlKey = ApiConfig.apiBaseUrlKey;
  static const String themeKey = 'tk24:theme';
  static const String lastSyncKey = 'xsmb-manager:last-sync';

  /// Chuẩn hoá URL API, ném [FormatException] nếu không hợp lệ.
  static String normalizeApiBaseUrl(String value) =>
      ApiConfig.normalizeBaseUrl(value);
}

