// Tab Phương pháp — port từ `Methodology` + `ProbabilityLab` của bản web.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/lottery_domain.dart';
import '../../logic/statistics.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Một thẻ công thức trong lưới "Công thức & giả định".
typedef MethodCard = ({
  String index,
  IconData icon,
  String title,
  String code,
  String text,
});

const List<MethodCard> kMethodCards = <MethodCard>[
  (
    index: '01',
    icon: Icons.track_changes,
    title: 'Một số trong một kết quả',
    code: 'P = 1 / 100 = 1%',
    text:
        'Khi xét đúng hai chữ số cuối của một kết quả và giả định các số 00–99 đồng khả năng.',
  ),
  (
    index: '02',
    icon: Icons.speed_outlined,
    title: 'Ít nhất một lần trong kỳ',
    code: 'P = 1 − (99/100)^n',
    text:
        'Với n = 27 kết quả, xác suất lý thuyết xấp xỉ 23,77% cho một số đã chọn.',
  ),
  (
    index: '03',
    icon: Icons.casino_outlined,
    title: 'Bộ k số trong một kỳ',
    code: 'P = 1 − ((100−k)/100)^n',
    text:
        'Xấp xỉ khi mỗi vị trí được coi là độc lập; k là số lượng số khác nhau đã chọn.',
  ),
  (
    index: '04',
    icon: Icons.bar_chart,
    title: 'Độ lệch chuẩn hóa',
    code: 'z = (x − np) / √np(1−p)',
    text:
        'So sánh số lần quan sát x với kỳ vọng np. Giá trị z lớn không phải tín hiệu dự đoán.',
  ),
  (
    index: '05',
    icon: Icons.timeline,
    title: 'Tần suất quan sát',
    code: 'f = số lần xuất hiện / tổng vị trí',
    text:
        'Một thống kê mô tả phụ thuộc vào cửa sổ dữ liệu, không thay thế xác suất lý thuyết.',
  ),
  (
    index: '06',
    icon: Icons.calendar_month_outlined,
    title: 'Khoảng cách xuất hiện',
    code: 'gap = kỳ hiện tại − kỳ gần nhất',
    text:
        '“Gan” đo thời gian đã qua. Nó không có nghĩa một số sẽ sớm xuất hiện hơn.',
  ),
];

class MethodologyTab extends StatelessWidget {
  const MethodologyTab({required this.draws, required this.stats, super.key});

  final List<LotteryDraw> draws;
  final List<NumberStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PageHeading(
          eyebrow: 'PHƯƠNG PHÁP MINH BẠCH',
          title: 'Công thức & giả định',
          description:
              'Mỗi chỉ số đều có định nghĩa, giả định và giới hạn sử dụng rõ ràng.',
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 320,
          maxColumns: 3,
          children: <Widget>[
            for (final card in kMethodCards)
              _MethodCard(
                index: card.index,
                icon: card.icon,
                title: card.title,
                code: card.code,
                text: card.text,
              ),
          ],
        ),
        const SizedBox(height: 16),
        ProbabilityLab(draws: draws, stats: stats),
        const SizedBox(height: 16),
        const _ArchitecturePanel(),
        const SizedBox(height: 16),
        const _LimitationsPanel(),
        const SizedBox(height: 18),
        const ResponsibleNotice(),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.code,
    required this.text,
  });

  final String index;
  final IconData icon;
  final String title;
  final String code;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: 18, color: palette.gold),
              ),
              const Spacer(),
              Text(
                index,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.panelSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.lineSoft),
            ),
            child: Text(
              code,
              style: TextStyle(
                color: palette.goldBright,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchitecturePanel extends StatelessWidget {
  const _ArchitecturePanel();

  static const List<(IconData, String, String)> _steps =
      <(IconData, String, String)>[
        (Icons.cloud_outlined, 'Nguồn dữ liệu', 'CSV · API hợp pháp · mẫu'),
        (Icons.fact_check_outlined, 'Kiểm định', 'Trùng · thiếu · định dạng'),
        (Icons.speed_outlined, 'Thống kê thuần', 'Tần suất · gap · z-score'),
        (Icons.dashboard_outlined, 'Trình bày', 'Bộ lọc · biểu đồ · bảng'),
      ];

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.storage,
            eyebrow: 'KIẾN TRÚC',
            title: 'Tách lớp để dễ kiểm tra',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final (index, step) in _steps.indexed) ...<Widget>[
                  if (index > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '→',
                        style: TextStyle(color: palette.muted, fontSize: 16),
                      ),
                    ),
                  Container(
                    width: 190,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: palette.panelSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.lineSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(step.$1, size: 18, color: palette.gold),
                        const SizedBox(height: 8),
                        Text(
                          step.$2,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.$3,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitationsPanel extends StatelessWidget {
  const _LimitationsPanel();

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 22, color: palette.coral),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'GIỚI HẠN CẦN NHỚ',
                  style: TextStyle(
                    color: palette.coral,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ngẫu nhiên không có trí nhớ',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Các mẫu ngắn hạn có thể trông rất thuyết phục chỉ do biến động ngẫu nhiên. '
                  'Không có “cầu chắc thắng”, không có mô hình nào trong ứng dụng cam kết '
                  'lợi nhuận hoặc kết quả tương lai.',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12.5,
                    height: 1.55,
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

/// "Phòng thử xác suất": tính lý thuyết, kiểm định và mô phỏng Monte Carlo.
class ProbabilityLab extends StatefulWidget {
  const ProbabilityLab({required this.draws, required this.stats, super.key});

  final List<LotteryDraw> draws;
  final List<NumberStat> stats;

  @override
  State<ProbabilityLab> createState() => _ProbabilityLabState();
}

class _ProbabilityLabState extends State<ProbabilityLab> {
  late final TextEditingController _choicesController = TextEditingController(
    text: '1',
  );
  late final TextEditingController _ticketController = TextEditingController(
    text: '10000',
  );
  late final TextEditingController _prizeController = TextEditingController(
    text: '70000',
  );

  int _digits = 2;
  int _choices = 1;
  int _ticketPrice = 10000;
  int _prize = 70000;

  @override
  void dispose() {
    _choicesController.dispose();
    _ticketController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final exact = exactDigitProbability(_digits) ?? 0;
    final oneOfMany = math.min(1.0, exact * _choices);
    final ev = expectedValue(_ticketPrice, _prize, oneOfMany);
    var total = 0;
    for (final stat in widget.stats) {
      total += stat.count;
    }
    final startCount = widget.stats.isEmpty ? 0 : widget.stats.first.count;
    final interval = wilsonInterval(startCount, total);
    final chi = chiSquareUniform(widget.stats);
    final labChoices = _choices.clamp(1, 100);
    final simulation = monteCarloAtLeastOne(labChoices, 27);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.casino_outlined,
            eyebrow: 'PHÒNG THỬ XÁC SUẤT',
            title: 'Tính và mô phỏng',
            meta: SelectionCount(label: 'Seed 2409 · 10.000 lượt'),
          ),
          ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 2,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _LabField(
                    label: 'Số chữ số',
                    child: _DigitsPicker(
                      value: _digits,
                      onChanged: (value) => setState(() => _digits = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabField(
                    label: 'Số lựa chọn không trùng',
                    child: TextField(
                      controller: _choicesController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: palette.text, fontSize: 13),
                      onChanged: (text) => setState(() {
                        _choices = math.max(1, int.tryParse(text) ?? 1);
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabField(
                    label: 'Giá vé (₫)',
                    child: TextField(
                      controller: _ticketController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: palette.text, fontSize: 13),
                      onChanged: (text) => setState(() {
                        _ticketPrice = math.max(0, int.tryParse(text) ?? 0);
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabField(
                    label: 'Giải thưởng (₫)',
                    child: TextField(
                      controller: _prizeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: palette.text, fontSize: 13),
                      onChanged: (text) => setState(() {
                        _prize = math.max(0, int.tryParse(text) ?? 0);
                      }),
                    ),
                  ),
                ],
              ),
              ResponsiveGrid(
                minItemWidth: 170,
                maxColumns: 2,
                children: <Widget>[
                  _LabResult(
                    label: 'Xác suất 1 lựa chọn',
                    value: '1 / ${formatNumber(exact == 0 ? 0 : 1 / exact)}',
                    note: formatPercent(exact, math.min(6, _digits)),
                  ),
                  _LabResult(
                    label: 'Một trong $_choices lựa chọn',
                    value: formatPercent(oneOfMany, 4),
                    note: '$_choices kết quả không trùng',
                  ),
                  _LabResult(
                    label: 'Số tổ hợp C(45,6)',
                    value: formatNumber(combinations(45, 6)),
                    note: 'Ví dụ vé chọn 6 từ 45',
                  ),
                  _LabResult(
                    label: 'Giá trị kỳ vọng / vé',
                    value: '${formatNumber(ev)} ₫',
                    note: 'P × giải thưởng − giá vé',
                    tone: ev >= 0 ? _LabTone.positive : _LabTone.negative,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 3,
            children: <Widget>[
              _TestStripItem(
                label: 'Monte Carlo · bộ $labChoices số / 27 vị trí',
                value: formatPercent(simulation, 2),
                note:
                    'Lý thuyết: ${formatPercent(calculateSetProbability(labChoices), 2)}',
              ),
              _TestStripItem(
                label: 'Khoảng tin cậy Wilson 95% · số 00',
                value:
                    '${formatPercent(interval[0], 2)} – ${formatPercent(interval[1], 2)}',
                note: '$startCount/$total vị trí quan sát',
              ),
              _TestStripItem(
                label: 'χ² so với phân phối đều',
                value: formatFixed(chi),
                note: 'df = 99 · mô tả trên ${widget.draws.length} kỳ',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.info_outline, size: 16, color: palette.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kiểm định χ² cần được đọc cùng ngưỡng ý nghĩa và chất lượng dữ liệu. '
                  'Một sai khác thống kê không chứng minh khả năng dự báo.',
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
    );
  }
}

enum _LabTone { neutral, positive, negative }

class _LabField extends StatelessWidget {
  const _LabField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: TextStyle(color: palette.muted, fontSize: 11.5)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _LabResult extends StatelessWidget {
  const _LabResult({
    required this.label,
    required this.value,
    required this.note,
    this.tone = _LabTone.neutral,
  });

  final String label;
  final String value;
  final String note;
  final _LabTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final accent = switch (tone) {
      _LabTone.positive => palette.green,
      _LabTone.negative => palette.coral,
      _LabTone.neutral => palette.goldBright,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: palette.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TestStripItem extends StatelessWidget {
  const _TestStripItem({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: palette.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DigitsPicker extends StatelessWidget {
  const _DigitsPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: palette.line),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        dropdownColor: palette.panelRaised,
        style: TextStyle(
          color: palette.text,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        items: <DropdownMenuItem<int>>[
          for (final digits in const <int>[2, 3, 4, 5, 6])
            DropdownMenuItem<int>(
              value: digits,
              child: Text(
                '$digits chữ số',
                style: TextStyle(color: palette.text, fontSize: 12.5),
              ),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
