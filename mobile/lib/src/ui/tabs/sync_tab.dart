import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/logging/app_logger.dart';
import '../../data/local/local_store.dart';
import '../../data/models/draw_record.dart';
import '../../data/models/lottery_models.dart';
import '../../data/models/sync_report.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Rút gọn timestamp ISO (có cả giờ) thành nhãn ngày.
String shortStamp(String value) => formatDateShort(value.split('T').first);

/// Tab "Nguồn dữ liệu & Cài đặt": trạng thái đồng bộ, nguồn, database, API.
class SyncTab extends StatefulWidget {
  const SyncTab({
    required this.sources,
    required this.statuses,
    required this.history,
    required this.stats,
    required this.apiBaseUrl,
    required this.lastSyncAt,
    required this.storeName,
    required this.storeLocation,
    required this.onSaveApiBaseUrl,
    required this.onCheckHealth,
    required this.onSync,
    required this.onPurgeOld,
    this.status,
    this.onRefreshStatus,
    this.report,
    this.logs = const <LogEntry>[],
    this.busy = false,
    super.key,
  });

  final List<SourceDescriptor> sources;
  final List<ProviderStatusRecord> statuses;
  final List<SyncHistoryRecord> history;
  final LocalStoreStats stats;
  final String apiBaseUrl;
  final String? lastSyncAt;
  final String storeName;
  final String storeLocation;

  /// Trạng thái hệ thống (API, dataset, cache, nguồn) — STEP 11.
  final SystemStatus? status;

  /// Kiểm tra lại `/v1/health` + cache để cập nhật [status].
  final Future<void> Function()? onRefreshStatus;
  final SyncReport? report;
  final List<LogEntry> logs;
  final bool busy;
  final Future<void> Function(String value) onSaveApiBaseUrl;
  final Future<void> Function() onCheckHealth;
  final Future<void> Function() onSync;
  final Future<void> Function(DateTime threshold) onPurgeOld;

  @override
  State<SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends State<SyncTab> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.apiBaseUrl,
  );
  String? _urlError;

  @override
  void didUpdateWidget(SyncTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.apiBaseUrl != oldWidget.apiBaseUrl &&
        _controller.text != widget.apiBaseUrl) {
      _controller.text = widget.apiBaseUrl;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await widget.onSaveApiBaseUrl(_controller.text);
      if (mounted) setState(() => _urlError = null);
    } on FormatException catch (error) {
      if (mounted) setState(() => _urlError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final stats = widget.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeading(
          eyebrow: 'Vận hành',
          title: 'Nguồn dữ liệu & Cài đặt',
          description:
              'Theo dõi nguồn đang dùng, database cục bộ và cấu hình API. '
              'App tự cập nhật khi mở nhưng không tải lại toàn bộ lịch sử.',
          action: AppButton(
            label: widget.busy ? 'Đang cập nhật…' : 'Cập nhật dữ liệu',
            icon: Icons.sync,
            onPressed: widget.busy ? null : () => widget.onSync(),
          ),
        ),
        const SizedBox(height: 14),
        _SystemStatusPanel(
          status: widget.status,
          busy: widget.busy,
          onRefresh: widget.onRefreshStatus,
        ),
        const SizedBox(height: 14),
        _StatusPanel(
          report: widget.report,
          lastSyncAt: widget.lastSyncAt,
          busy: widget.busy,
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.cloud_outlined,
                eyebrow: 'Chuỗi dự phòng',
                title: 'Nguồn dữ liệu theo thứ tự ưu tiên',
              ),
              const SizedBox(height: 10),
              for (final source in widget.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        source.available
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 18,
                        color: source.available ? palette.green : palette.coral,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${source.name} · ${source.kindLabel}',
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              source.description,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              AppButton(
                label: 'Kiểm tra nguồn',
                icon: Icons.network_check,
                tone: AppButtonTone.secondary,
                onPressed: widget.busy ? null : () => widget.onCheckHealth(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.storage_outlined,
                eyebrow: 'Database cục bộ',
                title: 'Dữ liệu đã lưu trên thiết bị',
                meta: SourceChip(label: widget.storeName),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: <Widget>[
                  _Stat(label: 'Số kỳ', value: '${stats.draws}'),
                  _Stat(label: 'Số kết quả giải', value: '${stats.results}'),
                  _Stat(label: 'Kỳ cũ nhất', value: stats.oldestDate ?? '—'),
                  _Stat(label: 'Kỳ mới nhất', value: stats.newestDate ?? '—'),
                  for (final entry in stats.perRegion.entries)
                    _Stat(
                      label: 'Vùng ${entry.key.toUpperCase()}',
                      value: '${entry.value} kỳ',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Vị trí: ${widget.storeLocation}',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Xoá dữ liệu cũ hơn 2 năm',
                icon: Icons.cleaning_services_outlined,
                tone: AppButtonTone.secondary,
                onPressed: widget.busy
                    ? null
                    : () => widget.onPurgeOld(
                        DateTime.now().subtract(const Duration(days: 730)),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.settings_outlined,
                eyebrow: 'Cài đặt',
                title: 'Địa chỉ API backend',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'URL API',
                  hintText: '${ApiConfig.workerBaseUrl}${ApiConfig.versionPath}',
                  errorText: _urlError,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mặc định app dùng Worker production '
                '${ApiConfig.workerBaseUrl}${ApiConfig.versionPath}. URL phải bao '
                'gồm /v1. Worker local trên máy ảo Android dùng '
                'http://10.0.2.2:8787/v1; điện thoại thật trong cùng Wi-Fi dùng '
                'IP máy tính khi chạy bản debug (ví dụ '
                'http://192.168.1.10:8787/v1). Bản release chặn HTTP thường nên '
                'cần API HTTPS. Không có khoá bí mật nào được lưu trong app.',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Lưu URL API',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HistoryPanel(history: widget.history, statuses: widget.statuses),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.terminal_outlined,
                eyebrow: 'Nhật ký',
                title: 'Hoạt động mạng và đồng bộ gần nhất',
              ),
              const SizedBox(height: 10),
              if (widget.logs.isEmpty)
                Text(
                  'Chưa có hoạt động nào.',
                  style: TextStyle(color: palette.muted, fontSize: 12.5),
                )
              else
                for (final entry in widget.logs.reversed.take(18))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      entry.toString(),
                      style: TextStyle(
                        color: entry.level == LogLevel.error
                            ? palette.coral
                            : palette.muted,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.report,
    required this.lastSyncAt,
    required this.busy,
  });

  final SyncReport? report;
  final String? lastSyncAt;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final current = report;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.sync_outlined,
            eyebrow: 'Trạng thái',
            title: busy
                ? 'Đang cập nhật dữ liệu…'
                : (current?.status.label ?? 'Chưa đồng bộ trong phiên này'),
            meta: SourceChip(
              label: lastSyncAt == null
                  ? 'chưa có lần nào'
                  : 'lần cuối ${shortStamp(lastSyncAt!)}',
            ),
          ),
          const SizedBox(height: 10),
          if (current != null) ...<Widget>[
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: <Widget>[
                _Stat(label: 'Nguồn dùng', value: current.provider),
                _Stat(label: 'Bản ghi mới', value: '${current.inserted}'),
                _Stat(label: 'Cập nhật', value: '${current.updated}'),
                _Stat(label: 'Bị loại', value: '${current.rejected}'),
                _Stat(label: 'Kỳ mới nhất', value: current.latestDate ?? '—'),
              ],
            ),
            const SizedBox(height: 10),
            for (final message in current.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $message',
                  style: TextStyle(
                    color: current.status == SyncOutcome.failed
                        ? palette.coral
                        : palette.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
          ] else
            Text(
              'Bấm "Cập nhật dữ liệu" để lấy các kỳ còn thiếu từ nguồn ưu tiên.',
              style: TextStyle(color: palette.muted, fontSize: 12.5),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: TextStyle(color: palette.muted, fontSize: 11.5)),
        Text(
          value,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.history, required this.statuses});

  final List<SyncHistoryRecord> history;
  final List<ProviderStatusRecord> statuses;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.timeline_outlined,
            eyebrow: 'Lịch sử',
            title: 'Sức khoẻ nguồn và các lần đồng bộ',
          ),
          const SizedBox(height: 10),
          if (statuses.isEmpty)
            Text(
              'Chưa ghi nhận lần gọi nguồn nào.',
              style: TextStyle(color: palette.muted, fontSize: 12.5),
            )
          else
            for (final status in statuses)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${status.provider} (${status.region.code}): '
                  '${status.successes} thành công, ${status.failures} lỗi, '
                  '${status.latencyMs}ms'
                  '${status.lastError == null ? '' : ' · ${status.lastError}'}',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Text(
              'Chưa có lần đồng bộ nào được ghi lại.',
              style: TextStyle(color: palette.muted, fontSize: 12.5),
            )
          else
            for (final record in history.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${shortStamp(record.finishedAt)} · ${record.region.code} · '
                  '${record.provider} · ${record.status.label} · '
                  '+${record.inserted} mới, ${record.updated} cập nhật, '
                  '${record.rejected} loại',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ),
        ],
      ),
    );
  }
}

/// Thẻ "Tình trạng hệ thống" (STEP 11): 8 thông tin vận hành bắt buộc.
///
/// Hiển thị cả khi mất mạng nhờ dữ liệu cache + lần đồng bộ gần nhất, nên
/// người dùng luôn biết app đang đọc dữ liệu thật hay dữ liệu ngoại tuyến.
class _SystemStatusPanel extends StatelessWidget {
  const _SystemStatusPanel({this.status, this.onRefresh, this.busy = false});

  final SystemStatus? status;
  final Future<void> Function()? onRefresh;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final value = status;
    if (value == null) {
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const PanelHeader(
              icon: Icons.monitor_heart_outlined,
              eyebrow: 'Trạng thái',
              title: 'Tình trạng hệ thống',
            ),
            const SizedBox(height: 10),
            Text(
              'Đang kiểm tra API và dữ liệu trong máy…',
              style: TextStyle(color: palette.muted, fontSize: 12.5),
            ),
          ],
        ),
      );
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.monitor_heart_outlined,
            eyebrow: 'Trạng thái',
            title: 'Tình trạng hệ thống',
            meta: SourceChip(
              label: value.apiOnline
                  ? 'API · ${value.apiStatusLabel}'
                  : 'Ngoại tuyến · ${value.sourceLabel}',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: <Widget>[
              _Stat(label: 'API', value: value.apiStatusLabel),
              _Stat(label: 'Endpoint', value: value.apiHost),
              _Stat(label: 'Ngày dataset (API)', value: value.datasetDateLabel),
              _Stat(
                label: 'Phiên bản dataset',
                value: value.datasetVersionLabel,
              ),
              _Stat(label: 'Đồng bộ thành công', value: value.lastSyncLabel),
              _Stat(label: 'Ngày dữ liệu trong máy', value: value.cacheDateLabel),
              _Stat(label: 'Nguồn đang dùng', value: value.sourceLabel),
              _Stat(
                label: 'Phiên bản app',
                value: value.appVersion.isEmpty ? '—' : value.appVersion,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value.summary,
            style: TextStyle(color: palette.text, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Text(
            value.sourceNote,
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'URL đang gọi: ${value.apiBaseUrl}',
            style: TextStyle(color: palette.muted, fontSize: 11.5),
          ),
          if (value.hasEndpointMismatch)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Lưu ý: /v1/config khai ${value.apiReportedBaseUrl} trong khi app '
                'đang gọi ${value.apiBaseUrl}. App giữ nguyên endpoint đang chạy '
                'được, không tự đổi host.',
                style: TextStyle(color: palette.coral, fontSize: 11.5),
              ),
            ),
          if (value.cacheBehindApi)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'API đã có kỳ ${value.datasetDateLabel} nhưng máy mới có '
                '${value.cacheDateLabel} — bấm “Cập nhật dữ liệu”.',
                style: TextStyle(color: palette.coral, fontSize: 11.5),
              ),
            ),
          if (onRefresh != null) ...<Widget>[
            const SizedBox(height: 12),
            AppButton(
              label: 'Kiểm tra lại trạng thái',
              icon: Icons.refresh,
              tone: AppButtonTone.secondary,
              onPressed: busy ? null : () => onRefresh!(),
            ),
          ],
        ],
      ),
    );
  }
}
