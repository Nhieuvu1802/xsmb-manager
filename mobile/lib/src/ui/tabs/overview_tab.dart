import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/lottery_dates.dart';
import '../../data/models/lottery_models.dart';
import '../../domain/lottery_domain.dart';
import '../../logic/statistics.dart';
import '../charts.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tab "Tổng quan" — port từ `Overview` trong `frontend/components/lottery-app.tsx`.
class OverviewTab extends StatefulWidget {
  const OverviewTab({
    required this.draws,
    required this.stats,
    required this.period,
    required this.onOpenAnalyzer,
    this.onOpenSets,
    super.key,
  });

  final List<LotteryDraw> draws;
  final List<NumberStat> stats;
  final int period;
  final VoidCallback onOpenAnalyzer;

  /// Mở tab "Bộ tính số" từ nút trong dải hero (không bắt buộc).
  final VoidCallback? onOpenSets;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  /// `Ngày` (14 điểm gần nhất), `Tuần` (gộp 7 kỳ) hoặc `Tháng` (gộp 30 kỳ).
  String _trendMode = 'Ngày';

  List<NumberStat> get _hot =>
      ([...widget.stats]..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.number.compareTo(b.number);
          }))
          .take(5)
          .toList(growable: false);

  List<NumberStat> get _cold =>
      ([...widget.stats]..sort((a, b) {
            final byCount = a.count.compareTo(b.count);
            return byCount != 0 ? byCount : a.number.compareTo(b.number);
          }))
          .take(5)
          .toList(growable: false);

  List<NumberStat> get _overdue =>
      (widget.stats.where((stat) => stat.gap != null).toList(growable: false)
            ..sort((a, b) => (b.gap ?? 0).compareTo(a.gap ?? 0)))
          .take(5)
          .toList(growable: false);

  List<ChartPoint> get _trend {
    final hot = _hot;
    final tracked = hot
        .take(3)
        .map((stat) => stat.number)
        .toList(growable: false);
    final raw = buildTrend(widget.draws, tracked);
    if (_trendMode == 'Ngày') {
      final tail = raw.length > 14 ? raw.sublist(raw.length - 14) : raw;
      return [for (final point in tail) ChartPoint(point.date, point.hits)];
    }

    final bucketSize = _trendMode == 'Tuần' ? 7 : 30;
    final points = <ChartPoint>[];
    for (var index = 0; index < raw.length; index += bucketSize) {
      final chunk = raw.sublist(
        index,
        math.min(index + bucketSize, raw.length),
      );
      if (chunk.isEmpty) continue;
      var hits = 0;
      for (final point in chunk) {
        hits += point.hits;
      }
      points.add(ChartPoint(chunk.last.date, hits));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.draws.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PageHeading(
            eyebrow: 'TRUNG TÂM DỮ LIỆU',
            title: 'Tổng quan xác suất',
            description: 'Chưa có kỳ quay nào cho khu vực đã chọn.',
          ),
          Panel(
            child: EmptyState(
              message:
                  'Mở tab “Nguồn & cài đặt” và bấm “Cập nhật dữ liệu”. '
                  'Sau lần đồng bộ đầu tiên, app giữ dữ liệu trong bộ nhớ máy '
                  'và vẫn hiển thị được khi mất mạng.',
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHero(),
        const SizedBox(height: 18),
        _buildSchedule(),
        const SizedBox(height: 18),
        _buildSignals(),
        const SizedBox(height: 18),
        _buildMetrics(),
        const SizedBox(height: 16),
        _buildTopRow(),
        const SizedBox(height: 16),
        _buildChartRow(),
        const SizedBox(height: 16),
        _buildHeatmap(),
        const SizedBox(height: 16),
        _buildStatsRow(),
        const SizedBox(height: 18),
        const ResponsibleNotice(),
      ],
    );
  }

  /// Dải hero tối kiểu trang tham chiếu: câu hỏi lớn, hai nút hành động và thẻ
  /// "Tóm tắt hôm nay" (`bg-white/10`) đặt trên nền navy.
  Widget _buildHero() {
    final palette = PaletteScope.of(context);
    final latest = widget.draws.first;
    var totalResults = 0;
    for (final draw in widget.draws) {
      totalResults += draw.results.length;
    }
    final eyebrowStyle = TextStyle(
      color: palette.onNavySoft,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    );

    return HeroBand(
      eyebrow: 'Dữ liệu & thống kê',
      title: 'Hôm nay số nào đáng chú ý nhất?',
      description:
          'Xem kết quả ${latest.region.label.toLowerCase()}, thống kê số nóng/lạnh và '
          'bộ số tham khảo được phân tích từ dữ liệu lịch sử ${widget.period} kỳ '
          'gần nhất.',
      actions: <Widget>[
        if (widget.onOpenSets != null)
          AppButton(
            label: 'Xem bộ tính số',
            icon: Icons.casino_outlined,
            onPressed: widget.onOpenSets,
          ),
        AppButton(
          label: 'Phân tích bộ số',
          icon: Icons.speed_outlined,
          tone: AppButtonTone.secondary,
          onPressed: widget.onOpenAnalyzer,
        ),
      ],
      aside: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.navyPanel,
          borderRadius: BorderRadius.circular(AppPalette.radius),
          border: Border.all(color: palette.navyLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('TÓM TẮT HÔM NAY', style: eyebrowStyle),
            const SizedBox(height: 12),
            StatTile(
              label: 'Kỳ gần nhất',
              value: formatDateLong(latest.date),
              note: latest.station,
              onNavy: true,
            ),
            const SizedBox(height: 8),
            StatTile(
              label: 'Kỳ đang phân tích',
              value: '${widget.draws.length}',
              note: '${formatNumber(totalResults)} kết quả riêng lẻ',
              onNavy: true,
            ),
            const SizedBox(height: 8),
            StatTile(
              label: 'Nguồn dữ liệu',
              value: latest.source,
              note: latest.verification == Verification.sample
                  ? 'Dữ liệu mẫu · seed cố định'
                  : latest.verification.label,
              onNavy: true,
            ),
            const SizedBox(height: 10),
            Text(
              'Chỉ cung cấp dữ liệu, thống kê và phân tích tham khảo — không cam kết '
              'kết quả.',
              style: TextStyle(
                color: palette.onNavySoft,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Lịch quay kế tiếp" — đúng tinh thần mục cùng tên của trang tham chiếu:
  /// ngày kế tiếp, giờ quay và danh sách đài của khu vực đang chọn.
  Widget _buildSchedule() {
    final palette = PaletteScope.of(context);
    final latest = widget.draws.first;
    final today = todayInVietnam();
    final latestDate = parseIsoDate(latest.date);
    final syncedToday = latestDate != null && !latestDate.isBefore(today);
    final target = syncedToday ? today.add(const Duration(days: 1)) : today;
    final (drawTime, stations) = switch (latest.region) {
      Region.mienBac => ('18:15', const <String>['Miền Bắc']),
      Region.mienTrung => ('17:15', _stationsByWeekday(target, latest.region)),
      Region.mienNam => ('16:15', stationsForDay(target)),
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.event_available,
            eyebrow: 'LỊCH QUAY KẾ TIẾP',
            title: syncedToday
                ? 'Ngày mai xổ số đài nào?'
                : 'Hôm nay xổ số đài nào?',
            meta: StatusChip(
              label: formatDateLong(isoDate(target)),
              tone: PillTone.gold,
              icon: Icons.calendar_today,
            ),
          ),
          if (stations.isEmpty)
            const EmptyState(
              message: 'Chưa có lịch đài cho khu vực này trong kho dữ liệu.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final station in stations)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: palette.panelSoft,
                      borderRadius: BorderRadius.circular(
                        AppPalette.radiusPill,
                      ),
                      border: Border.all(color: palette.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: palette.goldBright,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          drawTime,
                          style: TextStyle(
                            color: palette.goldBright,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          station,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Đài quay trong ngày [day] suy từ lịch sử đã có (dùng cho miền Trung vì
  /// dữ liệu lịch không nằm trong app).
  List<String> _stationsByWeekday(DateTime day, Region region) {
    final names = <String>[];
    for (final draw in widget.draws) {
      if (draw.region != region || draw.station.isEmpty) continue;
      final date = parseIsoDate(draw.date);
      if (date == null || date.weekday != day.weekday) continue;
      if (names.contains(draw.station)) continue;
      names.add(draw.station);
    }
    return names;
  }

  /// "Tín hiệu thống kê nổi bật": các số có điểm dữ liệu cao nhất kèm thang
  /// `Điểm dữ liệu x/100` — đúng dạng thẻ của trang tham chiếu.
  Widget _buildSignals() {
    final ranked =
        ([...widget.stats]..sort((a, b) {
              final byScore = _signalScore(b).compareTo(_signalScore(a));
              return byScore != 0 ? byScore : a.number.compareTo(b.number);
            }))
            .take(5)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeading(
          eyebrow: 'Tín hiệu thống kê nổi bật',
          title: 'Top số có điểm dữ liệu cao nhất',
          description:
              'Điểm dữ liệu là z-score quy đổi về thang 0–100 trên '
              '${widget.draws.length} kỳ gần nhất; chỉ mô tả mẫu đang xem.',
          action: AppButton(
            label: 'Phân tích',
            icon: Icons.speed_outlined,
            tone: AppButtonTone.secondary,
            onPressed: widget.onOpenAnalyzer,
          ),
        ),
        ResponsiveGrid(
          minItemWidth: 210,
          maxColumns: 5,
          children: <Widget>[
            for (final stat in ranked)
              SignalCard(
                number: stat.number,
                tag: _signalTag(stat),
                score: _signalScore(stat),
                tone: stat.zScore >= 0 ? PillTone.gold : PillTone.cold,
                note:
                    '${stat.count} lần trong ${widget.draws.length} kỳ · '
                    '${stat.gap == null ? 'chưa từng xuất hiện' : '${stat.gap} kỳ chưa xuất hiện'}',
                onTap: widget.onOpenAnalyzer,
              ),
          ],
        ),
      ],
    );
  }

  /// z-score → điểm 0–100 (`50 + 20·z`, kẹp về 0–100) cho thẻ tín hiệu.
  int _signalScore(NumberStat stat) =>
      (50 + stat.zScore * 20).round().clamp(0, 100);

  /// Nhãn ngắn cho thẻ tín hiệu, dựa trên độ lệch so với kỳ vọng.
  String _signalTag(NumberStat stat) {
    if (stat.zScore >= 0.5) return 'Số nóng';
    if (stat.zScore <= -0.5) return 'Xuất hiện ít';
    return 'Trung tính';
  }

  Widget _buildMetrics() {
    final hot = _hot.first;
    final cold = _cold.first;
    final overdue = _overdue.first;
    var totalResults = 0;
    for (final draw in widget.draws) {
      totalResults += draw.results.length;
    }

    return ResponsiveGrid(
      minItemWidth: 230,
      maxColumns: 4,
      children: <Widget>[
        MetricCard(
          icon: Icons.timeline,
          label: 'Tổng kỳ phân tích',
          value: '${widget.draws.length}',
          featured: true,
          tone: PillTone.gold,
          footer: '${formatNumber(totalResults)} kết quả riêng lẻ',
          footerIcon: Icons.north_east,
          bars: const <int>[38, 61, 48, 77, 56, 90, 72, 100],
        ),
        MetricCard(
          icon: Icons.local_fire_department_outlined,
          label: 'Đang xuất hiện nhiều',
          value: hot.number,
          tone: PillTone.hot,
          footer: '${hot.count} lần · z = ${formatFixed(hot.zScore)}',
          footerIcon: Icons.north_east,
        ),
        MetricCard(
          icon: Icons.ac_unit,
          label: 'Đang xuất hiện ít',
          value: cold.number,
          tone: PillTone.cold,
          footer: '${cold.count} lần trong mẫu',
          footerIcon: Icons.south_east,
        ),
        MetricCard(
          icon: Icons.schedule,
          label: 'Lâu chưa xuất hiện',
          value: overdue.number,
          footer: '${overdue.gap ?? 0} kỳ kể từ lần gần nhất',
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    final palette = PaletteScope.of(context);
    final latest = widget.draws.first;
    final hot = _hot;
    // Miền Nam quay nhiều đài trong cùng một ngày → hiển thị đủ tên các đài.
    final sameDayStations = <String>[];
    for (final draw in widget.draws) {
      if (draw.date != latest.date) continue;
      if (sameDayStations.contains(draw.station)) continue;
      sameDayStations.add(draw.station);
    }
    final collected = latest.collectedAt;

    return ResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.history,
                eyebrow: 'KỲ QUAY MỚI NHẤT',
                title: formatDateLong(latest.date),
                meta: SourceChip(
                  label: latest.verification == Verification.sample
                      ? 'Dữ liệu mẫu · seed cố định'
                      : latest.source,
                ),
              ),
              _PrizeBoard(draw: latest),
              if (sameDayStations.length > 1) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  '${sameDayStations.length} đài cùng kỳ: '
                  '${sameDayStations.join(' · ')}',
                  style: TextStyle(color: palette.muted, fontSize: 11.5),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Icon(Icons.cloud_outlined, size: 15, color: palette.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nguồn: ${latest.source}',
                      style: TextStyle(color: palette.muted, fontSize: 11.5),
                    ),
                  ),
                  Text(
                    collected.isEmpty
                        ? 'Chưa có mốc thu thập'
                        : 'Thu thập: ${formatIsoMoment(collected)}',
                    style: TextStyle(color: palette.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.trending_up,
                eyebrow: 'NHỊP SỐ',
                title: 'Nhóm nổi bật',
                meta: TextButton(
                  onPressed: widget.onOpenAnalyzer,
                  child: Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      color: palette.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              for (final (index, item) in hot.indexed) ...<Widget>[
                if (index > 0) const SizedBox(height: 10),
                _RankRow(index: index, stat: item, maxCount: hot.first.count),
              ],
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline, size: 16, color: palette.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '“Nhiều” chỉ mô tả mẫu đang xem, không làm tăng cơ hội ở kỳ kế tiếp.',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartRow() {
    final palette = PaletteScope.of(context);
    final tracked = _hot
        .take(3)
        .map((stat) => stat.number)
        .toList(growable: false);

    return ResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.bar_chart,
                eyebrow: 'DIỄN BIẾN',
                title: 'Xu hướng nhóm số nổi bật',
                meta: _Segmented(
                  options: const <String>['Ngày', 'Tuần', 'Tháng'],
                  value: _trendMode,
                  onChanged: (value) => setState(() => _trendMode = value),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Theo dõi',
                    style: TextStyle(color: palette.muted, fontSize: 11.5),
                  ),
                  for (final number in tracked)
                    NumberPill(number: number, tone: PillTone.gold),
                ],
              ),
              const SizedBox(height: 14),
              TrendAreaChart(points: _trend, height: 240),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.track_changes,
                eyebrow: 'XÁC SUẤT LÝ THUYẾT',
                title: 'Một số 2 chữ số',
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 168,
                  height: 168,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        palette.gold.withValues(alpha: 0.22),
                        palette.panel,
                      ],
                    ),
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        formatPercent(calculateSetProbability(1), 2),
                        style: TextStyle(
                          color: palette.goldBright,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'xuất hiện ≥ 1 lần\ntrong 27 kết quả*',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: palette.panelSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: palette.lineSoft),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      '1 − (99/100)^27',
                      style: TextStyle(
                        color: palette.goldBright,
                        fontSize: 12.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '≈ 0,2377',
                      style: TextStyle(
                        color: palette.mutedBright,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '*Mô hình lý thuyết giả định 27 đuôi số độc lập và phân phối đều. '
                'Xác suất trúng riêng giải đặc biệt là 1%.',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap() {
    final hot = _hot;
    final cold = _cold;
    final overdue = _overdue;
    final max = hot.first.count == 0 ? 1 : hot.first.count;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.grid_view,
            eyebrow: 'BẢN ĐỒ 00–99',
            title: 'Mật độ xuất hiện',
            meta: _HeatLegend(),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final stat in widget.stats)
                _HeatCell(stat: stat, intensity: stat.count / max),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minItemWidth: 240,
            maxColumns: 3,
            children: <Widget>[
              _HeatSummary(
                icon: Icons.local_fire_department_outlined,
                tone: PillTone.hot,
                label: 'Nhóm xuất hiện nhiều',
                value: hot.map((stat) => stat.number).join(' · '),
              ),
              _HeatSummary(
                icon: Icons.ac_unit,
                tone: PillTone.cold,
                label: 'Nhóm xuất hiện ít',
                value: cold.map((stat) => stat.number).join(' · '),
              ),
              _HeatSummary(
                icon: Icons.schedule,
                tone: PillTone.gold,
                label: 'Nhóm lâu chưa xuất hiện',
                value: overdue.map((stat) => stat.number).join(' · '),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final palette = PaletteScope.of(context);
    final pairStats = calculatePairStats(widget.draws);
    final dayStats = calculateDayOfWeekStats(widget.draws);
    final maxPair = pairStats.isEmpty || pairStats.first.count == 0
        ? 1
        : pairStats.first.count;

    return ResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.track_changes,
                eyebrow: 'CẶP SỐ',
                title: 'Cặp xuất hiện nhiều nhất',
                meta: SourceChip(label: '${widget.draws.length} kỳ'),
              ),
              if (pairStats.isEmpty)
                const EmptyState(message: 'Chưa đủ dữ liệu.')
              else
                for (final (index, item)
                    in pairStats.take(12).indexed) ...<Widget>[
                  if (index > 0) const SizedBox(height: 8),
                  _PairRow(index: index, stat: item, maxCount: maxPair),
                ],
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.calendar_month_outlined,
                eyebrow: 'NGÀY TRONG TUẦN',
                title: 'Phân bố theo ngày',
                meta: SourceChip(label: 'Trung bình'),
              ),
              const SizedBox(height: 6),
              BarsChart(
                bars: <BarDatum>[
                  for (final stat in dayStats)
                    BarDatum(stat.day, stat.drawHits),
                ],
                height: 200,
                firstBarColor: palette.coral,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final stat in dayStats)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: palette.panelSoft,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: palette.lineSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            stat.day,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stat.drawHits} kỳ · ${formatNumber(stat.count)} kết quả',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bảng giải thưởng của một kỳ quay, sắp theo thứ tự giải quen thuộc.
class _PrizeBoard extends StatelessWidget {
  const _PrizeBoard({required this.draw});

  final LotteryDraw draw;

  static const List<String> _order = <String>[
    'Đặc biệt',
    'Giải nhất',
    'Giải nhì',
    'Giải ba',
    'Giải tư',
    'Giải năm',
    'Giải sáu',
    'Giải bảy',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final groups = <String, List<String>>{};
    for (final result in draw.results) {
      final prize = result.prize.replaceAll('_', ' ');
      (groups[prize] ??= <String>[]).add(result.value);
    }
    final prizes = groups.keys.toList(growable: false)
      ..sort((a, b) {
        final ai = _order.indexOf(a);
        final bi = _order.indexOf(b);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (index, prize) in prizes.indexed) ...<Widget>[
          if (index > 0) const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: prize == 'Đặc biệt' ? palette.goldSoft : palette.panelSoft,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: prize == 'Đặc biệt'
                    ? palette.gold.withValues(alpha: 0.3)
                    : palette.lineSoft,
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 74,
                  child: Text(
                    prize,
                    style: TextStyle(
                      color: prize == 'Đặc biệt' ? palette.gold : palette.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      for (final value in groups[prize]!)
                        Text(
                          value,
                          style: TextStyle(
                            color: prize == 'Đặc biệt'
                                ? palette.goldBright
                                : palette.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.index,
    required this.stat,
    required this.maxCount,
  });

  final int index;
  final NumberStat stat;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final ratio = maxCount == 0 ? 0.16 : math.max(0.16, stat.count / maxCount);
    final accent = index < 2 ? palette.coral : palette.gold;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 20,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: palette.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        NumberPill(
          number: stat.number,
          tone: index < 2 ? PillTone.hot : PillTone.neutral,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: ColoredBox(color: palette.panelSoft),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        alignment: Alignment.centerLeft,
                        child: ColoredBox(color: accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stat.count} lần',
                style: TextStyle(color: palette.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DeltaLabel(value: stat.zScore),
      ],
    );
  }
}

/// Nút chuyển chế độ Ngày / Tuần / Tháng (thay `.segmented` của CSS).
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final option in options)
            Material(
              color: option == value ? palette.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onChanged(option),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: option == value
                          ? const Color(0xFF17130B)
                          : palette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    // Thang nhiệt của site: nền nhạt → vàng `#F6D35A` → cam `#FB923C`.
    final stops = <Color>[
      Color.lerp(palette.panelSoft, palette.amber, 0.35)!,
      Color.lerp(palette.panelSoft, palette.amber, 0.9)!,
      palette.amber,
      palette.warm,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Ít', style: TextStyle(color: palette.muted, fontSize: 10.5)),
        const SizedBox(width: 6),
        for (final color in stops) ...<Widget>[
          if (color != stops.first) const SizedBox(width: 3),
          Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text('Nhiều', style: TextStyle(color: palette.muted, fontSize: 10.5)),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.stat, required this.intensity});

  final NumberStat stat;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final ratio = intensity.clamp(0.0, 1.0);
    // Ô nóng dùng nền cam/vàng đặc nên phải đổi chữ sang tông mực tối.
    final color = ratio < 0.5
        ? Color.lerp(palette.panelSoft, palette.amber, ratio * 2)!
        : Color.lerp(palette.amber, palette.warm, (ratio - 0.5) * 2)!;
    final strong = ratio > 0.45;
    final ink = strong ? const Color(0xFF1F2937) : palette.text;
    return Tooltip(
      message: '${stat.number}: ${stat.count} lần · ${stat.gap ?? '—'} kỳ gan',
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppPalette.radiusSm),
          border: Border.all(color: strong ? Colors.transparent : palette.line),
        ),
        child: Column(
          children: <Widget>[
            Text(
              stat.number,
              style: TextStyle(
                color: ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${stat.count}',
              style: TextStyle(
                color: strong ? const Color(0xFF475569) : palette.mutedBright,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatSummary extends StatelessWidget {
  const _HeatSummary({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final PillTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final accent = switch (tone) {
      PillTone.hot => palette.coral,
      PillTone.cold => palette.blue,
      PillTone.gold => palette.gold,
      PillTone.neutral => palette.mutedBright,
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(color: palette.muted, fontSize: 10.5),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.index,
    required this.stat,
    required this.maxCount,
  });

  final int index;
  final PairStat stat;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final ratio = maxCount == 0 ? 0.0 : (stat.count / maxCount).clamp(0.0, 1.0);

    return Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          child: Text(
            '#${index + 1}',
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            stat.pair,
            style: TextStyle(
              color: palette.goldBright,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(
          width: 62,
          child: Text(
            '${stat.count} lần',
            style: TextStyle(color: palette.mutedBright, fontSize: 11.5),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: ColoredBox(color: palette.panelSoft)),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    alignment: Alignment.centerLeft,
                    child: ColoredBox(
                      color: palette.gold.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
