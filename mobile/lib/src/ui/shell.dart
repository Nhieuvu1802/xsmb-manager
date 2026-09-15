import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/utils/lottery_dates.dart';
import '../data/local/local_store.dart';
import '../data/models/backtest.dart';
import '../data/models/draw_record.dart';
import '../data/models/generated_run.dart';
import '../data/models/lottery_models.dart';
import '../data/models/sync_report.dart';
import '../data/repositories/lottery_repository.dart';
import '../domain/backtest/backtest_engine.dart';
import '../domain/generator/number_generator.dart';
import '../domain/lottery_domain.dart';
import '../domain/scoring/prediction_engine.dart';
import '../domain/statistics/number_statistics.dart';
import '../logic/statistics.dart';
import 'tabs/analyzer_tab.dart';
import 'tabs/backtest_tab.dart';
import 'tabs/data_tab.dart';
import 'tabs/methodology_tab.dart';
import 'tabs/number_sets_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/sync_tab.dart';
import 'tabs/top4_tab.dart';
import 'theme.dart';

/// Các khu vực của ứng dụng, tương ứng `NAV_ITEMS` trong bản web.
enum AppView {
  overview('Tổng quan', 'Nhịp dữ liệu', Icons.dashboard_outlined),
  top4('Top 4', 'Xếp hạng tham khảo', Icons.local_fire_department_outlined),
  analyzer('Phân tích', 'Kiểm tra bộ số', Icons.speed_outlined),
  sets('Bộ tính số', 'Sinh bộ số theo lịch sử', Icons.casino_outlined),
  backtest('Backtest', 'Kiểm chứng mô hình', Icons.verified_outlined),
  data('Kho dữ liệu', 'Nguồn & nhập liệu', Icons.storage_outlined),
  sync('Nguồn & cài đặt', 'Vận hành', Icons.cloud_sync_outlined),
  method('Phương pháp', 'Công thức rõ ràng', Icons.menu_book_outlined);

  const AppView(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

/// Các mục hiển thị trên thanh điều hướng dưới của điện thoại.
const List<AppView> kPrimaryViews = <AppView>[
  AppView.overview,
  AppView.top4,
  AppView.backtest,
  AppView.data,
  AppView.sync,
];

const List<int> kPeriodOptions = <int>[7, 30, 90, 180, 365];

const List<String> kLotteryTypes = <String>[
  'Lô tô 2 số',
  'Giải đặc biệt',
  'Vé 6/45',
];

/// Khung ứng dụng: điều hướng, bộ lọc, nội dung từng tab và toast.
class LotteryApp extends StatefulWidget {
  const LotteryApp({
    required this.repository,
    required this.isDark,
    required this.onToggleTheme,
    required this.apiBaseUrl,
    required this.onSaveApiBaseUrl,
    super.key,
  });

  final LotteryRepository repository;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String apiBaseUrl;
  final Future<void> Function(String value) onSaveApiBaseUrl;

  @override
  State<LotteryApp> createState() => _LotteryAppState();
}

class _LotteryAppState extends State<LotteryApp> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  /// Dùng `GlobalKey` để mở ngăn kéo từ `_TopBar`: `Scaffold.of(context)` không
  /// tìm thấy `Scaffold` vì `context` ở đây là của `LayoutBuilder` — chính là
  /// widget tạo ra `Scaffold` (nút menu từng không mở được ngăn kéo trên máy hẹp).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppView _view = AppView.overview;
  int _period = 90;
  Region _region = Region.mienBac;
  String _lotteryType = kLotteryTypes.first;
  List<LotteryDraw> _draws = const <LotteryDraw>[];
  String? _toast;
  Timer? _toastTimer;
  Timer? _autoRefreshTimer;

  bool _busy = false;
  bool _runningBacktest = false;
  SyncReport? _report;
  String? _lastSyncAt;
  BacktestOutcome? _backtestOutcome;
  List<BacktestWindowResult> _savedBacktests = const <BacktestWindowResult>[];

  /// Các lần sinh bộ số đã lưu của vùng đang chọn (tab "Bộ tính số").
  List<GeneratedRunRecord> _savedGeneratedRuns = const <GeneratedRunRecord>[];
  List<ProviderStatusRecord> _providerStatuses = const <ProviderStatusRecord>[];
  List<SyncHistoryRecord> _syncHistory = const <SyncHistoryRecord>[];
  LocalStoreStats _storeStats = LocalStoreStats.empty;
  List<SourceDescriptor> _sources = const <SourceDescriptor>[];

  /// Trạng thái hệ thống hiển thị ở tab "Nguồn & cài đặt" (STEP 11).
  SystemStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Mở database, nạp dữ liệu có sẵn rồi đồng bộ phần còn thiếu.
  Future<void> _bootstrap() async {
    await widget.repository.open();
    await _reloadFromStore();
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _lastSyncAt = preferences.getString(AppConfig.lastSyncKey));
    await _sync(silent: true);
    _scheduleAutoRefresh();
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(liveRefreshInterval(), () async {
      if (!mounted) return;
      await _sync(force: true, silent: true);
      if (mounted) _scheduleAutoRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_sync(force: true, silent: true));
      _scheduleAutoRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _autoRefreshTimer?.cancel();
    }
  }

  Future<void> _reloadFromStore() async {
    final draws = await widget.repository.recentDomainDraws(
      region: _region,
      limit: AppConfig.maxDrawsInMemory,
    );
    final statuses = await widget.repository.providerStatuses(_region);
    final history = await widget.repository.syncHistory(limit: 10);
    final stats = await widget.repository.stats();
    final saved = await widget.repository.recentBacktestResults(limit: 12);
    final generated = await widget.repository.recentGeneratedRuns(
      region: _region,
      limit: 10,
    );
    final status = await _loadSystemStatus();
    if (!mounted) return;
    setState(() {
      _draws = draws;
      _providerStatuses = statuses;
      _syncHistory = history;
      _storeStats = stats;
      _savedBacktests = saved;
      _savedGeneratedRuns = generated;
      _sources = widget.repository.describeSources();
      if (status != null) _status = status;
    });
  }

  /// Dựng trạng thái hệ thống (API/dataset/cache/nguồn) mà không làm sập UI.
  Future<SystemStatus?> _loadSystemStatus() async {
    try {
      return await widget.repository.systemStatus(
        region: _region,
        apiBaseUrl: widget.apiBaseUrl,
      );
    } catch (error) {
      appLogger.warning('shell', 'Không dựng được trạng thái hệ thống: $error');
      return null;
    }
  }

  /// Người dùng bấm "Kiểm tra lại trạng thái" ở tab Nguồn & cài đặt.
  Future<void> _refreshStatus() async {
    final status = await _loadSystemStatus();
    if (!mounted || status == null) return;
    setState(() => _status = status);
  }

  Future<void> _sync({bool force = false, bool silent = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final report = await widget.repository.sync(
        region: _region,
        force: force,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(AppConfig.lastSyncKey, report.finishedAt);
      await _reloadFromStore();
      if (!mounted) return;
      setState(() {
        _report = report;
        _lastSyncAt = report.finishedAt;
      });
      if (!silent) _showToast(report.summary);
    } catch (error) {
      if (mounted) _showToast('Đồng bộ lỗi: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkSources() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final attempts = await widget.repository.healthCheckAll();
      await _reloadFromStore();
      if (!mounted) return;
      final ok = attempts.where((item) => item.ok).length;
      _showToast('Nguồn sẵn sàng: $ok/${attempts.length}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runBacktest() async {
    if (_runningBacktest) return;
    setState(() => _runningBacktest = true);
    try {
      final draws = await widget.repository.recentDomainDraws(
        region: _region,
        limit: AppConfig.maxDrawsInMemory,
      );
      final outcome = BacktestEngine.run(draws: draws);
      if (outcome.results.isNotEmpty) {
        await widget.repository.saveBacktestResults(_region, outcome.results);
      }
      await _reloadFromStore();
      if (!mounted) return;
      setState(() => _backtestOutcome = outcome);
      _showToast(outcome.verdict);
    } catch (error) {
      if (mounted) _showToast('Backtest lỗi: $error');
    } finally {
      if (mounted) setState(() => _runningBacktest = false);
    }
  }

  Future<void> _purgeOld(DateTime threshold) async {
    final removed = await widget.repository.purgeBefore(isoDate(threshold));
    await _reloadFromStore();
    if (mounted) _showToast('Đã xoá $removed kỳ cũ.');
  }

  /// Lưu một lần sinh bộ số (tab "Bộ tính số") rồi nạp lại lịch sử.
  Future<void> _saveGeneratedSet(GeneratorOutcome outcome) async {
    try {
      await widget.repository.saveGeneratedRun(
        GeneratedRunRecord.fromOutcome(region: _region, outcome: outcome),
      );
      await _reloadFromStore();
      if (mounted) {
        _showToast(
          'Đã lưu ${outcome.sets.length} bộ số theo ${outcome.strategy.label} '
          '(seed ${outcome.seed}).',
        );
      }
    } catch (error) {
      if (mounted) _showToast('Không lưu được bộ số: $error');
    }
  }

  List<LotteryDraw> get _filteredDraws => _draws
      .where((draw) => draw.region == _region)
      .take(_period)
      .toList(growable: false);

  List<NumberStat> get _stats => calculateNumberStats(_filteredDraws);

  StatisticsSnapshot get _snapshot =>
      analyseNumbers(_filteredDraws, label: _region.label);

  PredictionResult get _prediction => PredictionEngine.rank(
    snapshot: _snapshot,
    regionLabel: _region.label,
    targetDate: '${_region.label} — kỳ kế tiếp',
  );

  /// Kết quả backtest gần nhất phù hợp với khoảng đang chọn.
  BacktestWindowResult? get _latestBacktestForPeriod {
    final rows = _backtestOutcome?.results
        .where((item) => item.model == kScoreModel)
        .toList();
    if (rows == null || rows.isEmpty) return null;
    for (final row in rows) {
      if (row.windowDays == _period) return row;
    }
    for (final row in rows) {
      if (row.windowDays == 0) return row;
    }
    return rows.first;
  }

  void _navigate(AppView next) {
    setState(() => _view = next);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 4200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  /// Gộp dữ liệu vừa nhập vào phiên làm việc và lưu lại trên thiết bị.
  Future<void> _importDraws(List<LotteryDraw> imported) async {
    if (imported.isEmpty) return;
    final records = <DrawRecord>[
      for (final draw in imported) DrawRecord.fromDomain(draw),
    ];
    await widget.repository.store.upsertDraws(records);
    await _reloadFromStore();
    if (mounted) {
      setState(() {
        if (imported.isNotEmpty) _region = imported.first.region;
      });
      _showToast('Đã nhập ${imported.length} kỳ vào database cục bộ.');
    }
  }

  Widget _buildContent() {
    return switch (_view) {
      AppView.overview => OverviewTab(
        draws: _filteredDraws,
        stats: _stats,
        period: _period,
        onOpenAnalyzer: () => _navigate(AppView.analyzer),
        onOpenSets: () => _navigate(AppView.sets),
      ),
      AppView.analyzer => AnalyzerTab(draws: _filteredDraws, stats: _stats),
      AppView.sets => NumberSetsTab(
        draws: _filteredDraws,
        regionLabel: _region.label,
        saved: _savedGeneratedRuns,
        onSave: _saveGeneratedSet,
      ),
      AppView.top4 => Top4Tab(
        prediction: _prediction,
        drawCount: _snapshot.drawCount,
        backtest: _latestBacktestForPeriod,
        period: _period,
      ),
      AppView.backtest => BacktestTab(
        outcome: _backtestOutcome,
        running: _runningBacktest,
        onRun: () => unawaited(_runBacktest()),
        drawCount: _draws.length,
        saved: _savedBacktests,
      ),
      AppView.sync => SyncTab(
        sources: _sources,
        statuses: _providerStatuses,
        history: _syncHistory,
        stats: _storeStats,
        apiBaseUrl: widget.apiBaseUrl,
        lastSyncAt: _lastSyncAt,
        storeName: widget.repository.store.backendName,
        storeLocation: widget.repository.store.location,
        status: _status,
        onRefreshStatus: _refreshStatus,
        report: _report,
        logs: appLogger.entries,
        busy: _busy,
        onSaveApiBaseUrl: widget.onSaveApiBaseUrl,
        onCheckHealth: _checkSources,
        onSync: () => _sync(force: true),
        onPurgeOld: _purgeOld,
      ),
      AppView.data => DataCenterTab(
        draws: _draws,
        onImport: (imported) => unawaited(_importDraws(imported)),
      ),
      AppView.method => MethodologyTab(draws: _filteredDraws, stats: _stats),
    };
  }

  List<Widget> _buildFilters({required bool desktop}) {
    return <Widget>[
      _Select<Region>(
        label: desktop ? 'Khu vực' : null,
        value: _region,
        items: <(Region, String)>[
          for (final region in Region.values) (region, region.label),
        ],
        onChanged: (value) => setState(() => _region = value),
      ),
      _Select<String>(
        label: desktop ? 'Loại phân tích' : null,
        value: _lotteryType,
        items: <(String, String)>[
          for (final type in kLotteryTypes) (type, type),
        ],
        onChanged: (value) => setState(() => _lotteryType = value),
      ),
      _Select<int>(
        label: desktop ? 'Khoảng dữ liệu' : null,
        value: _period,
        items: <(int, String)>[
          for (final value in kPeriodOptions)
            (value, desktop ? '$value kỳ gần nhất' : '$value kỳ'),
        ],
        onChanged: (value) => setState(() => _period = value),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        final page = <Widget>[
          _buildContent(),
          const SizedBox(height: 20),
          const _AppFooter(),
        ];
        final scroller = SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            wide ? 26 : 14,
            wide ? 20 : 16,
            wide ? 26 : 14,
            26,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPalette.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: page,
              ),
            ),
          ),
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: palette.bg,
          drawer: wide
              ? null
              : Drawer(
                  width: 272,
                  backgroundColor: palette.sidebar,
                  child: _Sidebar(
                    view: _view,
                    onNavigate: (next) {
                      Navigator.of(context).pop();
                      _navigate(next);
                    },
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
          body: Stack(
            children: <Widget>[
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      width: AppPalette.sidebarWidth,
                      child: _Sidebar(view: _view, onNavigate: _navigate),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          _TopBar(
                            title: _view.label,
                            isDark: widget.isDark,
                            onToggleTheme: widget.onToggleTheme,
                            filters: _buildFilters(desktop: true),
                          ),
                          Expanded(child: scroller),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: <Widget>[
                    _TopBar(
                      title: _view.label,
                      isDark: widget.isDark,
                      onToggleTheme: widget.onToggleTheme,
                      onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      filters: const <Widget>[],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Row(
                        children: <Widget>[
                          for (final (index, filter) in _buildFilters(
                            desktop: false,
                          ).indexed) ...<Widget>[
                            if (index > 0) const SizedBox(width: 8),
                            Expanded(child: filter),
                          ],
                        ],
                      ),
                    ),
                    Expanded(child: scroller),
                  ],
                ),
              if (_toast != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: wide ? 24 : 88,
                  child: Center(child: _ToastCard(message: _toast!)),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _busy ? null : () => unawaited(_sync(force: true)),
            backgroundColor: palette.gold,
            foregroundColor: palette.onGold,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
            ),
            icon: Icon(_busy ? Icons.hourglass_top : Icons.sync),
            label: Text(
              _busy ? 'Đang cập nhật…' : 'Cập nhật',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : _BottomNav(view: _view, onNavigate: _navigate),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.view, required this.onNavigate, this.onClose});

  final AppView view;
  final ValueChanged<AppView> onNavigate;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.sidebar,
        // Chỉ vẽ đường phân cách khi là sidebar cố định (ngăn kéo đã có viền).
        border: onClose == null
            ? Border(right: BorderSide(color: palette.line))
            : null,
      ),
      // Ngăn kéo phải cuộn được: màn hình thấp (hoặc máy nằm ngang) không đủ
      // chỗ cho toàn bộ mục điều hướng + thẻ trách nhiệm, nếu không sẽ tràn.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight - 36
                  : 0,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.gold,
                          borderRadius: BorderRadius.circular(
                            AppPalette.radiusSm + 2,
                          ),
                        ),
                        child: Text(
                          '24',
                          style: TextStyle(
                            color: palette.onGold,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Thống Kê 24',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Dữ liệu minh bạch',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onClose != null)
                        IconButton(
                          onPressed: onClose,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'KHÔNG GIAN PHÂN TÍCH',
                    style: TextStyle(
                      color: palette.goldBright,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in AppView.values) ...<Widget>[
                    _SidebarNavButton(
                      item: item,
                      active: item == view,
                      onTap: () => onNavigate(item),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const Spacer(),
                  const _SidebarResponsibleCard(),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: palette.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Dữ liệu mẫu',
                        style: TextStyle(
                          color: palette.mutedBright,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'v3.0.0',
                        style: TextStyle(color: palette.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarResponsibleCard extends StatelessWidget {
  const _SidebarResponsibleCard();

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.verified_user_outlined, size: 19, color: palette.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '18+ · Có trách nhiệm',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Thống kê để tham khảo, không phải cam kết trúng thưởng.',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  const _SidebarNavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final AppView item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Material(
      color: active ? palette.goldSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
            border: Border.all(
              color: active
                  ? palette.gold.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? palette.gold : palette.panelSoft,
                  borderRadius: BorderRadius.circular(AppPalette.radiusSm),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: active ? palette.onGold : palette.muted,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: TextStyle(
                        color: active ? palette.goldBright : palette.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown nhỏ gọn dùng cho bộ lọc ở topbar và thanh lọc di động.
class _Select<T> extends StatelessWidget {
  const _Select({
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        border: Border.all(color: palette.line),
      ),
      child: DropdownButton<T>(
        value: value,
        isDense: true,
        isExpanded: label == null,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        dropdownColor: palette.panelRaised,
        icon: Icon(Icons.expand_more, size: 16, color: palette.muted),
        style: TextStyle(
          color: palette.text,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        items: <DropdownMenuItem<T>>[
          for (final (itemValue, itemLabel) in items)
            DropdownMenuItem<T>(
              value: itemValue,
              child: Text(
                itemLabel,
                style: TextStyle(color: palette.text, fontSize: 12.5),
              ),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );

    if (label == null) return dropdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label!,
          style: TextStyle(
            color: palette.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        dropdown,
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isDark,
    required this.onToggleTheme,
    required this.filters,
    this.onOpenMenu,
  });

  final String title;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final List<Widget> filters;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Row(
        children: <Widget>[
          if (onOpenMenu != null) ...<Widget>[
            IconButton(
              onPressed: onOpenMenu,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.menu, size: 20, color: palette.mutedBright),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Thống Kê 24',
                  style: TextStyle(
                    color: palette.goldBright,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          for (final (index, filter) in filters.indexed) ...<Widget>[
            if (index > 0) const SizedBox(width: 14),
            filter,
          ],
          const SizedBox(width: 12),
          IconButton(
            onPressed: onToggleTheme,
            tooltip: isDark
                ? 'Chuyển sang giao diện sáng'
                : 'Chuyển sang giao diện tối',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              size: 19,
              color: palette.mutedBright,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.panelSoft,
              shape: BoxShape.circle,
              border: Border.all(color: palette.line),
            ),
            child: Text(
              'AN',
              style: TextStyle(
                color: palette.mutedBright,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.view, required this.onNavigate});

  final AppView view;
  final ValueChanged<AppView> onNavigate;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        children: <Widget>[
          for (final item in kPrimaryViews)
            Expanded(
              child: InkWell(
                onTap: () => onNavigate(item),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: item == view ? palette.goldSoft : null,
                    borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 20,
                        color: item == view
                            ? palette.goldBright
                            : palette.muted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: item == view
                              ? palette.goldBright
                              : palette.muted,
                          fontSize: 10.5,
                          fontWeight: item == view
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final style = TextStyle(color: palette.muted, fontSize: 11.5, height: 1.5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.bgSoft,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: palette.goldBright),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 6,
              children: <Widget>[
                Text(
                  '© 2026 Thống Kê 24 · Công cụ học tập & giải trí',
                  style: style,
                ),
                Text(
                  'Kết quả quá khứ không đảm bảo kết quả tương lai.',
                  style: style,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.panelRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check, size: 17, color: palette.green),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: palette.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
