import 'package:flutter/material.dart';

import '../../data/models/backtest.dart';
import '../../domain/backtest/backtest_engine.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tab backtest walk-forward: đánh giá mô hình bằng dữ liệu quá khứ.
class BacktestTab extends StatelessWidget {
  const BacktestTab({
    required this.outcome,
    required this.running,
    required this.onRun,
    required this.drawCount,
    this.saved = const <BacktestWindowResult>[],
    super.key,
  });

  final BacktestOutcome? outcome;
  final bool running;
  final VoidCallback onRun;
  final int drawCount;
  final List<BacktestWindowResult> saved;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final current = outcome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeading(
          eyebrow: 'Kiểm chứng',
          title: 'Backtest walk-forward',
          description:
              'Dùng dữ liệu TRƯỚC ngày D để xếp hạng ngày D, rồi so với kết '
              'quả thật. Hiện có $drawCount kỳ trong database.',
          action: AppButton(
            label: running ? 'Đang chạy…' : 'Chạy backtest',
            icon: Icons.play_arrow_outlined,
            onPressed: running ? null : onRun,
          ),
        ),
        const SizedBox(height: 14),
        if (current == null)
          const EmptyState(
            message:
                'Chưa có kết quả. Bấm "Chạy backtest" để đánh giá mô hình trên '
                'dữ liệu đã tải về.',
          )
        else ...<Widget>[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PanelHeader(
                  icon: Icons.gavel_outlined,
                  eyebrow: 'Kết luận',
                  title: 'Mô hình có vượt baseline không?',
                ),
                const SizedBox(height: 10),
                Text(
                  current.verdict,
                  style: TextStyle(
                    color: current.beatsBaselineEverywhere
                        ? palette.green
                        : palette.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final note in current.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $note',
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final window in _windowsOf(current.results)) ...<Widget>[
            _WindowPanel(
              windowDays: window,
              rows: current.results
                  .where((item) => item.windowDays == window)
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
          ],
        ],
        if (saved.isNotEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PanelHeader(
                  icon: Icons.history_outlined,
                  eyebrow: 'Đã lưu trên máy',
                  title: 'Kết quả backtest gần nhất',
                ),
                const SizedBox(height: 10),
                for (final row in saved.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${row.model} · '
                      '${row.windowDays == 0 ? 'toàn bộ' : '${row.windowDays} kỳ'} · '
                      'Top 4 ${formatPercent(row.top4HitRate)} · '
                      'baseline ${formatPercent(row.baselineTop4HitRate)}',
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static List<int> _windowsOf(List<BacktestWindowResult> rows) {
    final windows = <int>{for (final row in rows) row.windowDays};
    return windows.toList()..sort();
  }
}

class _WindowPanel extends StatelessWidget {
  const _WindowPanel({required this.windowDays, required this.rows});

  final int windowDays;
  final List<BacktestWindowResult> rows;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final label = windowDays == 0
        ? 'Toàn bộ dữ liệu'
        : '$windowDays kỳ gần nhất';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.stacked_line_chart_outlined,
            eyebrow: 'Cửa sổ đánh giá',
            title: label,
            meta: SourceChip(
              label: rows.isEmpty ? 'không có mẫu' : '${rows.first.samples} kỳ',
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingTextStyle: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              dataTextStyle: TextStyle(color: palette.text, fontSize: 12.5),
              columns: const <DataColumn>[
                DataColumn(label: Text('Mô hình')),
                DataColumn(label: Text('Top 1')),
                DataColumn(label: Text('Top 4')),
                DataColumn(label: Text('Top 10')),
                DataColumn(label: Text('precision@4')),
                DataColumn(label: Text('precision@10')),
                DataColumn(label: Text('Δ baseline')),
              ],
              rows: <DataRow>[
                for (final row in rows)
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text(modelLabel(row.model))),
                      DataCell(Text(formatPercent(row.top1HitRate))),
                      DataCell(Text(formatPercent(row.top4HitRate))),
                      DataCell(Text(formatPercent(row.top10HitRate))),
                      DataCell(Text(formatFixed(row.averageHitsAt4 / 4, 3))),
                      DataCell(Text(formatFixed(row.averageHitsAt10 / 10, 3))),
                      DataCell(
                        Text(
                          '${formatSigned(row.edgeOverBaseline * 100, 1)}%',
                          style: TextStyle(
                            color: row.edgeOverBaseline >= 0
                                ? palette.green
                                : palette.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn tiếng Việt cho tên mô hình trong backtest.
String modelLabel(String model) => switch (model) {
  kScoreModel => 'Điểm thống kê',
  kFrequencyBaseline => 'Baseline tần suất',
  kRandomBaseline => 'Chọn ngẫu nhiên',
  _ => model,
};
