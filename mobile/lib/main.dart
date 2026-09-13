import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/config/api_config.dart';
import 'src/core/config/app_config.dart';
import 'src/core/logging/app_logger.dart';
import 'src/data/local/local_store_factory.dart';
import 'src/data/providers/backend_api_provider.dart';
import 'src/data/providers/github_json_provider.dart';
import 'src/data/providers/local_cache_provider.dart';
import 'src/data/providers/lottery_data_provider.dart';
import 'src/data/providers/provider_chain.dart';
import 'src/data/repositories/lottery_repository.dart';
import 'src/data/sources/local/lottery_local_data_source.dart';
import 'src/data/sources/remote/lottery_api_client.dart';
import 'src/ui/shell.dart';
import 'src/ui/startup_error_app.dart';
import 'src/ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  Widget root;
  try {
    root = await buildRoot();
  } catch (error, stackTrace) {
    // Lưới an toàn thứ hai: kể cả khi chính bước dựng gốc ở trên ném lỗi thì
    // vẫn luôn có `runApp` để Flutter vẽ một màn hình thay vì bỏ trống cửa sổ.
    root = StartupFailureApp(
      error: error,
      stackTrace: stackTrace,
      bootstrap: buildRoot,
    );
  }
  runApp(root);
}

/// Dựng cây widget gốc của app.
///
/// Mọi lỗi ở bước chuẩn bị (SharedPreferences, SQLite…) đều được trả về dưới
/// dạng [StartupFailureApp] để người dùng thấy thông báo và bấm "Thử lại",
/// thay vì chỉ còn nền trắng của LaunchTheme như trước đây.
Future<Widget> buildRoot() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final store = await createLocalStore();
    final local = LotteryLocalDataSource(store: store);
    await local.open();

    // URL API được đọc lại mỗi lần gọi nên đổi trong màn hình Cài đặt có hiệu lực ngay.
    Future<String> baseUrlLoader() async => ApiConfig.normalizeBaseUrl(
      preferences.getString(ApiConfig.apiBaseUrlKey) ?? ApiConfig.baseUrl,
    );

    // Client typed của API production; mọi provider dùng chung một client.
    final apiClient = LotteryApiClient(baseUrlLoader: baseUrlLoader);

    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        BackendApiProvider(apiClient: apiClient),
        GitHubJsonProvider(
          baseUrlLoader: () async => ApiConfig.githubPublicDataBaseUrl,
          enabled: ApiConfig.githubFallbackEnabled,
        ),
        LocalCacheProvider(store: store),
      ],
      store: store,
    );

    final repository = LotteryRepository(
      store: store,
      chain: chain,
      api: apiClient,
      apiBaseUrlLoader: baseUrlLoader,
      local: local,
    );
    appLogger.info(
      'main',
      'Khởi động ${store.backendName}; API ${ApiConfig.host}; đồng bộ gần nhất '
          '${preferences.getString(AppConfig.lastSyncKey) ?? 'chưa có'}',
    );

    return ThongKe24App(
      repository: repository,
      // Mặc định giao diện sáng như trang tham chiếu; người dùng vẫn bật được
      // chế độ tối từ nút trên thanh tiêu đề.
      initialIsDark: preferences.getString(AppConfig.themeKey) == 'dark',
    );
  } catch (error, stackTrace) {
    appLogger.error('main', 'Khởi động thất bại', '$error\n$stackTrace');
    return StartupFailureApp(
      error: error,
      stackTrace: stackTrace,
      bootstrap: buildRoot,
    );
  }
}

/// Ứng dụng "Thống Kê 24" cho Android và Web.
class ThongKe24App extends StatefulWidget {
  const ThongKe24App({
    required this.repository,
    required this.initialIsDark,
    super.key,
  });

  final LotteryRepository repository;
  final bool initialIsDark;

  @override
  State<ThongKe24App> createState() => _ThongKe24AppState();
}

class _ThongKe24AppState extends State<ThongKe24App> {
  late bool _isDark = widget.initialIsDark;
  late String _apiBaseUrl = ApiConfig.baseUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _apiBaseUrl = ApiConfig.normalizeBaseUrl(
        preferences.getString(ApiConfig.apiBaseUrlKey) ?? ApiConfig.baseUrl,
      );
      _loaded = true;
    });
  }

  Future<void> _toggleTheme() async {
    final next = !_isDark;
    setState(() => _isDark = next);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(AppConfig.themeKey, next ? 'dark' : 'light');
  }

  Future<void> _saveApiBaseUrl(String value) async {
    final normalized = ApiConfig.normalizeBaseUrl(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(ApiConfig.apiBaseUrlKey, normalized);
    if (!mounted) return;
    setState(() => _apiBaseUrl = normalized);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _isDark ? AppPalette.dark : AppPalette.light;
    return PaletteScope(
      palette: palette,
      child: MaterialApp(
        title: 'Thống Kê 24',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi'),
        supportedLocales: const <Locale>[Locale('vi'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(palette),
        home: _loaded
            ? LotteryApp(
                repository: widget.repository,
                isDark: _isDark,
                onToggleTheme: _toggleTheme,
                apiBaseUrl: _apiBaseUrl,
                onSaveApiBaseUrl: _saveApiBaseUrl,
              )
            : Scaffold(
                backgroundColor: palette.bg,
                body: const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}
