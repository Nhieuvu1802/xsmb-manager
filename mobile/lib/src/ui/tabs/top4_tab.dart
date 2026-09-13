import 'package:flutter/material.dart';

import '../../data/models/backtest.dart';
import '../../domain/scoring/prediction_engine.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tab "TOP 4 tham khảo" — điểm thống kê, KHÔNG phải xác suất trúng.
class Top4Tab extends StatelessWidget {
  const Top4Tab({
    required this.prediction,
    required this.drawCount,
    this.backtest,
    this.period = 90,
    super.key,
  });

  final PredictionResult prediction;
  final int drawCount;
  final BacktestWindowResult? backtest;
  final int period;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    if (drawCount == 0) {
      return const EmptyState(
        message:
            'Chưa có kỳ quay nào trong bộ lọc. Hãy cập nhật dữ liệu ở mục '
            'Nguồn dữ liệu rồi quay lại.',
      );
    }

    final top4 = prediction.top4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeading(
          eyebrow: 'Xếp hạng thống kê',
          title: 'TOP 4 THAM KHẢO KỲ TIẾP THEO',
          description:
              '${prediction.regionLabel} · $drawCount kỳ trong bộ lọc · '
              'mô hình ${prediction.model}',
        ),
        const SizedBox(height: 14),
        if (backtest != null) ...<Widget>[
          _BacktestSummaryRow(result: backtest!),
          const SizedBox(height: 14),
        ],
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.local_fire_department_outlined,
                eyebrow: 'Bảng xếp hạng',
                title: 'Bốn số đứng đầu theo Điểm thống kê',
              ),
              const SizedBox(height: 12),
              for (final entry in top4) ...<Widget>[
                _TopRow(entry: entry, palette: palette),
                if (entry != top4.last) const SizedBox(height: 10),
              ],
              const SizedBox(height: 16),
              _Disclaimer(text: PredictionResult.disclaimer),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.list_alt_outlined,
                eyebrow: 'Đối chiếu',
                title: 'Các số điểm cao kế tiếp',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final entry in prediction.top(24))
                    NumberPill(
                      number: entry.number,
                      tone: entry.rank <= 4
                          ? PillTone.hot
                          : (entry.rank <= 10
                                ? PillTone.gold
                                : PillTone.neutral),
                      width: 76,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Điểm số là thứ hạng tương đối giữa 100 số trong dữ liệu đã '
                'chọn, sau khi chuẩn hoá từng feature về [0, 1].',
                style: TextStyle(color: palette.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.entry, required this.palette});

  final ScoredNumber entry;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final metrics = entry.metrics;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 30,
                  child: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      color: palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                NumberPill(number: entry.number, tone: PillTone.hot, width: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Điểm thống kê ${entry.score.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: <Widget>[
                _Metric(
                  label: 'Tần suất 10 kỳ',
                  value: formatPercent(metrics.windowRates[10] ?? 0),
                ),
                _Metric(
                  label: 'Tần suất 30 kỳ',
                  value: formatPercent(metrics.windowRates[30] ?? 0),
                ),
                _Metric(
                  label: 'Kỳ chưa xuất hiện',
                  value: metrics.gap == null ? 'chưa có' : '${metrics.gap}',
                ),
                _Metric(
                  label: 'Xu hướng (30 kỳ)',
                  value: formatSigned(metrics.trendShort, 2),
                ),
                _Metric(
                  label: 'Momentum',
                  value: formatSigned(metrics.momentum, 2),
                ),
                _Metric(
                  label: 'Lượt xuất hiện',
                  value: '${metrics.occurrences}',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Yếu tố đóng góp: ${entry.topDrivers.join(' · ')}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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

class _BacktestSummaryRow extends StatelessWidget {
  const _BacktestSummaryRow({required this.result});

  final BacktestWindowResult result;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final window = result.windowDays == 0
        ? 'toàn bộ'
        : '${result.windowDays} kỳ';
    final edge = result.edgeOverBaseline;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.verified_outlined,
            eyebrow: 'Backtest walk-forward',
            title: 'Hiệu quả Top 4 trên $window dữ liệu',
            meta: SourceChip(label: '${result.samples} kỳ kiểm tra'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: <Widget>[
              _Metric(
                label: 'Top 1 có trúng',
                value: formatPercent(result.top1HitRate),
              ),
              _Metric(
                label: 'Top 4 có trúng',
                value: formatPercent(result.top4HitRate),
              ),
              _Metric(
                label: 'Top 10 có trúng',
                value: formatPercent(result.top10HitRate),
              ),
              _Metric(
                label: 'Baseline tần suất Top 4',
                value: formatPercent(result.baselineTop4HitRate),
              ),
              _Metric(
                label: 'Ngẫu nhiên Top 4',
                value: formatPercent(result.randomTop4HitRate),
              ),
              _Metric(
                label: 'Chênh lệch so baseline',
                value: '${formatSigned(edge * 100, 1)}%',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            edge > 0
                ? 'Trong $window này, Top 4 của mô hình cao hơn baseline tần '
                      'suất. Kết quả quá khứ không bảo đảm cho kỳ tới.'
                : 'Trong $window này, Top 4 của mô hình KHÔNG cao hơn baseline. '
                      'Đây chỉ là thứ hạng tham khảo, không phải lợi thế.',
            style: TextStyle(
              color: edge > 0 ? palette.green : palette.coral,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, size: 18, color: palette.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: palette.muted, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
