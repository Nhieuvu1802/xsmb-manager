// Tab Phân tích — port từ `Analyzer` trong frontend/components/lottery-app.tsx.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lottery_domain.dart';
import '../../logic/statistics.dart';
import '../charts.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Khóa lưu danh sách bộ số yêu thích, tương đương `tk24:favorites` của web.
const String kFavoritesPreferenceKey = 'tk24:favorites';

/// Một bộ số trong phần so sánh "Nhiều bộ số trên cùng màn hình".
class CompareSet {
  const CompareSet({
    required this.id,
    required this.label,
    required this.numbers,
  });

  final int id;
  final String label;
  final List<String> numbers;
}

class AnalyzerTab extends StatefulWidget {
  const AnalyzerTab({required this.draws, required this.stats, super.key});

  final List<LotteryDraw> draws;
  final List<NumberStat> stats;

  @override
  State<AnalyzerTab> createState() => _AnalyzerTabState();
}

class _AnalyzerTabState extends State<AnalyzerTab> {
  static const int _maxFavorites = 12;
  static const List<String> _defaultNumbers = <String>['08', '23', '47', '62'];

  late final TextEditingController _controller = TextEditingController(
    text: _defaultNumbers.join(', '),
  );
  final List<CompareSet> _sets = <CompareSet>[
    const CompareSet(
      id: 1,
      label: 'Bộ A',
      numbers: <String>['08', '23', '47', '62'],
    ),
    const CompareSet(
      id: 2,
      label: 'Bộ B',
      numbers: <String>['11', '36', '58', '90'],
    ),
  ];
  int _randomSize = 5;
  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final stored =
        preferences.getStringList(kFavoritesPreferenceKey) ?? const <String>[];
    if (mounted) setState(() => _favoriteCount = stored.length);
  }

  NumberSetParse get _parsed => parseNumberSet(_controller.text);

  Map<String, NumberStat> get _statMap => <String, NumberStat>{
    for (final stat in widget.stats) stat.number: stat,
  };

  List<NumberStat> get _selectedStats => <NumberStat>[
    for (final number in _parsed.numbers)
      if (_statMap[number] case final NumberStat stat) stat,
  ];

  /// Bảng xác suất lý thuyết và tỷ lệ quan sát của từng bộ số.
  List<({CompareSet set, double theory, double history})> get _comparison {
    return <({CompareSet set, double theory, double history})>[
      for (final set in _sets)
        (
          set: set,
          theory: calculateSetProbability(set.numbers.length) * 100,
          history: widget.draws.isEmpty
              ? 0
              : _hits(set.numbers) / widget.draws.length * 100,
        ),
    ];
  }

  int _hits(List<String> numbers) {
    var hits = 0;
    for (final draw in widget.draws) {
      final values = draw.results
          .map((result) => lastTwoDigits(result.value))
          .toList(growable: false);
      if (numbers.any(values.contains)) hits += 1;
    }
    return hits;
  }

  void _generate() {
    final numbers = secureRandomNumbers(_randomSize);
    _controller.text = numbers.join(', ');
    setState(() {});
  }

  void _addComparison() {
    final parsed = _parsed;
    if (parsed.numbers.isEmpty) return;
    final label = 'Bộ ${String.fromCharCode(65 + _sets.length)}';
    final keep = _sets.length > 3 ? _sets.sublist(_sets.length - 3) : _sets;
    setState(() {
      _sets
        ..clear()
        ..addAll(keep)
        ..add(
          CompareSet(
            id: DateTime.now().microsecondsSinceEpoch,
            label: label,
            numbers: parsed.numbers,
          ),
        );
    });
  }

  Future<void> _saveFavorite() async {
    final parsed = _parsed;
    if (parsed.numbers.isEmpty) return;
    final key = parsed.numbers.join('-');
    final preferences = await SharedPreferences.getInstance();
    final stored =
        preferences.getStringList(kFavoritesPreferenceKey) ?? <String>[];
    final unique = <String>[...stored.where((item) => item != key), key];
    final trimmed = unique.length > _maxFavorites
        ? unique.sublist(unique.length - _maxFavorites)
        : unique;
    await preferences.setStringList(kFavoritesPreferenceKey, trimmed);
    if (mounted) setState(() => _favoriteCount = trimmed.length);
  }

  void _clearInput() {
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PageHeading(
          eyebrow: 'PHÒNG PHÂN TÍCH',
          title: 'Kiểm tra bộ số',
          description:
              'Đặt lịch sử cạnh xác suất lý thuyết để có một góc nhìn tỉnh táo hơn.',
        ),
        const SizedBox(height: 16),
        _buildInputRow(),
        const SizedBox(height: 16),
        _buildMetrics(),
        const SizedBox(height: 16),
        _buildStatsAndIndependence(),
        const SizedBox(height: 16),
        _buildStructure(),
        const SizedBox(height: 16),
        _buildCompare(),
        const SizedBox(height: 18),
        const ResponsibleNotice(),
      ],
    );
  }

  Widget _buildInputRow() {
    final palette = PaletteScope.of(context);
    final parsed = _parsed;

    return ResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.speed_outlined,
                eyebrow: 'BƯỚC 1',
                title: 'Nhập bộ số',
                meta: SelectionCount(label: '${parsed.numbers.length}/20 số'),
              ),
              Text(
                'Dãy số cần phân tích',
                style: TextStyle(color: palette.muted, fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                minLines: 3,
                maxLines: 5,
                style: TextStyle(color: palette.text, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: 08, 23, 47, 62',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tách số bằng dấu phẩy hoặc khoảng trắng.',
                      style: TextStyle(color: palette.muted, fontSize: 11.5),
                    ),
                  ),
                  if (parsed.invalid.isNotEmpty)
                    Flexible(
                      child: Text(
                        'Sai định dạng: ${parsed.invalid.join(', ')}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: palette.coral,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final number in parsed.numbers)
                    NumberPill(number: number, tone: PillTone.gold),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  AppButton(
                    label: 'Thêm vào so sánh',
                    icon: Icons.add,
                    onPressed: _addComparison,
                  ),
                  AppButton(
                    label: 'Lưu ($_favoriteCount)',
                    icon: Icons.star_border,
                    tone: AppButtonTone.secondary,
                    onPressed: _saveFavorite,
                  ),
                  AppButton(
                    label: 'Xóa',
                    icon: Icons.close,
                    tone: AppButtonTone.secondary,
                    onPressed: _clearInput,
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
              const PanelHeader(
                icon: Icons.casino_outlined,
                eyebrow: 'BỘ TẠO MINH BẠCH',
                title: 'Chọn số ngẫu nhiên',
              ),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(text: 'Dùng '),
                    TextSpan(
                      text: 'Random.secure()',
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' cùng rejection sampling để tránh thiên lệch modulo. '
                          'Không dùng lịch sử để “tối ưu” kết quả.',
                    ),
                  ],
                ),
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Số lượng: ',
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                    TextSpan(
                      text: '$_randomSize',
                      style: TextStyle(
                        color: palette.goldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: _randomSize.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                activeColor: palette.gold,
                label: '$_randomSize',
                onChanged: (value) =>
                    setState(() => _randomSize = value.round()),
              ),
              AppButton(
                label: 'Tạo bộ số mới',
                icon: Icons.refresh,
                tone: AppButtonTone.gold,
                expanded: true,
                onPressed: _generate,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.verified_user_outlined,
                    size: 17,
                    color: palette.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Có thể kiểm tra mã nguồn hàm sinh số trong '
                      'lib/src/logic/statistics.dart.',
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

  Widget _buildMetrics() {
    final selected = _selectedStats;
    var totalHits = 0;
    var rateSum = 0.0;
    var maxZ = 0.0;
    for (final stat in selected) {
      totalHits += stat.count;
      rateSum += stat.drawRate;
      maxZ = math.max(maxZ, stat.zScore.abs());
    }
    final averageRate = selected.isEmpty ? 0.0 : rateSum / selected.length;

    return ResponsiveGrid(
      minItemWidth: 230,
      maxColumns: 4,
      children: <Widget>[
        _AnalysisMetric(
          label: 'Xác suất ≥ 1 số xuất hiện',
          value: formatPercent(
            calculateSetProbability(_parsed.numbers.length),
            2,
          ),
          note: 'Lý thuyết · 27 kết quả',
        ),
        _AnalysisMetric(
          label: 'Tổng lượt trong lịch sử',
          value: formatNumber(totalHits),
          note: 'Trên ${widget.draws.length} kỳ đã lọc',
        ),
        _AnalysisMetric(
          label: 'Tỷ lệ quan sát trung bình',
          value: formatPercent(averageRate),
          note: 'Mỗi số · theo kỳ',
        ),
        _AnalysisMetric(
          label: 'Độ lệch lớn nhất',
          value: '${formatFixed(maxZ)}σ',
          note: 'So với phân phối đều',
        ),
      ],
    );
  }

  Widget _buildStatsAndIndependence() {
    final palette = PaletteScope.of(context);
    final selected = _selectedStats;

    return ResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.timeline,
                eyebrow: 'LỊCH SỬ',
                title: 'Hồ sơ từng số',
                meta: SourceChip(label: '${widget.draws.length} kỳ'),
              ),
              if (selected.isEmpty)
                const EmptyState(
                  message: 'Nhập ít nhất một số hợp lệ từ 00 đến 99.',
                )
              else
                _StatsTable(stats: selected),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.verified_user_outlined,
                eyebrow: 'ĐỌC ĐÚNG DỮ LIỆU',
                title: 'Các kỳ quay độc lập',
              ),
              Row(
                children: <Widget>[
                  _IndependenceChip(label: 'P(A)'),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette.panelSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _IndependenceChip(label: 'P(B)'),
                  const SizedBox(width: 10),
                  Text(
                    '=',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IndependenceChip(label: 'P(A) × P(B)'),
                ],
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(
                      text:
                          'Nếu quy trình quay là công bằng và các kỳ độc lập, '
                          'việc một số đã lâu chưa xuất hiện ',
                    ),
                    TextSpan(
                      text: 'không khiến nó “đến lượt”',
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: ' ở kỳ tiếp theo.'),
                  ],
                ),
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.coralSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.coral.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.error_outline, size: 18, color: palette.coral),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Tần suất, độ lệch và khoảng gan chỉ mô tả dữ liệu quá khứ.',
                        style: TextStyle(
                          color: palette.mutedBright,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStructure() {
    final palette = PaletteScope.of(context);
    final structure = calculateStructure(widget.draws);
    final statMap = _statMap;
    var maxCount = 1;
    for (final stat in widget.stats) {
      maxCount = math.max(maxCount, stat.count);
    }

    LabeledCount? topSum;
    for (final item in structure.sums) {
      if (topSum == null || item.count > topSum.count) topSum = item;
    }
    LabeledCount? topRange;
    for (final item in structure.ranges) {
      if (topRange == null || item.count > topRange.count) topRange = item;
    }
    final sequences = structure.sequences
        .take(4)
        .map((item) => '${item.sequence} (${item.count})')
        .join(' · ');

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.speed_outlined,
            eyebrow: 'CẤU TRÚC 2 CHỮ SỐ',
            title: 'Đầu, đuôi, tổng và khoảng số',
            meta: SelectionCount(label: '${widget.draws.length} kỳ'),
          ),
          ResponsiveGrid(
            minItemWidth: 320,
            maxColumns: 2,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _SubHeading(title: 'Tần suất chữ số 0–9'),
                  const SizedBox(height: 10),
                  BarsChart(
                    bars: <BarDatum>[
                      for (final item in structure.digitCounts)
                        BarDatum(
                          item.label,
                          item.count,
                          color: int.parse(item.label).isEven
                              ? palette.gold
                              : palette.muted,
                        ),
                    ],
                    height: 190,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _SubHeading(title: 'Heatmap đầu–đuôi'),
                  const SizedBox(height: 10),
                  _HeadTailGrid(stats: statMap, maxCount: maxCount),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minItemWidth: 240,
            maxColumns: 4,
            children: <Widget>[
              _StructureSummary(
                label: 'Chẵn / lẻ',
                value:
                    '${formatNumber(structure.evenCount)} / ${formatNumber(structure.oddCount)}',
              ),
              _StructureSummary(
                label: 'Tổng phổ biến',
                value: topSum?.label ?? '—',
              ),
              _StructureSummary(
                label: 'Khoảng nổi bật',
                value: topRange?.label ?? '—',
              ),
              _StructureSummary(
                label: 'Chuỗi cặp / bộ ba lặp lại',
                value: sequences.isEmpty ? 'Chưa đủ dữ liệu' : sequences,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompare() {
    final palette = PaletteScope.of(context);
    final comparison = _comparison;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.bar_chart,
            eyebrow: 'SO SÁNH',
            title: 'Nhiều bộ số trên cùng màn hình',
            meta: SelectionCount(label: 'Tối đa 4 bộ'),
          ),
          if (comparison.isEmpty)
            const EmptyState(message: 'Thêm một bộ số để bắt đầu so sánh.')
          else ...<Widget>[
            GroupedBarsChart(
              labels: <String>[for (final entry in comparison) entry.set.label],
              series: <BarSeries>[
                BarSeries(
                  name: 'Lý thuyết',
                  values: <num>[for (final entry in comparison) entry.theory],
                  color: palette.gold,
                ),
                BarSeries(
                  name: 'Lịch sử',
                  values: <num>[for (final entry in comparison) entry.history],
                  color: const Color(0xFF58657A),
                ),
              ],
              unit: '%',
              height: 240,
            ),
            const SizedBox(height: 14),
            for (final (index, entry) in comparison.indexed) ...<Widget>[
              if (index > 0) const SizedBox(height: 8),
              _CompareRow(
                index: index,
                label: entry.set.label,
                numbers: entry.set.numbers,
                percentage: entry.theory / 100,
                onRemove: () => setState(
                  () => _sets.removeWhere((set) => set.id == entry.set.id),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AnalysisMetric extends StatelessWidget {
  const _AnalysisMetric({
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: palette.muted, fontSize: 11.5)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.goldBright,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: palette.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _IndependenceChip extends StatelessWidget {
  const _IndependenceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.mutedBright,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Text(
      title,
      style: TextStyle(
        color: palette.text,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.stats});

  final List<NumberStat> stats;

  static const List<double> _widths = <double>[64, 62, 76, 76, 84, 72];

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final body = TextStyle(color: palette.mutedBright, fontSize: 12.5);
    final head = TextStyle(
      color: palette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );

    Widget row(List<Widget> cells) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < cells.length; index++)
            SizedBox(width: _widths[index], child: cells[index]),
        ],
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          row(<Widget>[
            for (final label in const <String>[
              'Số',
              'Lượt',
              'Tỷ lệ ô',
              'Tỷ lệ kỳ',
              'Khoảng gan',
              'Độ lệch',
            ])
              Text(label, style: head),
          ]),
          Divider(height: 1, color: palette.lineSoft),
          for (final stat in stats) ...<Widget>[
            row(<Widget>[
              NumberPill(
                number: stat.number,
                tone: stat.zScore > 1
                    ? PillTone.hot
                    : (stat.zScore < -1 ? PillTone.cold : PillTone.neutral),
              ),
              Text(
                '${stat.count}',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(formatPercent(stat.rate, 2), style: body),
              Text(formatPercent(stat.drawRate), style: body),
              Text('${stat.gap ?? '—'} kỳ', style: body),
              DeltaLabel(value: stat.zScore, digits: 2),
            ]),
            Divider(height: 1, color: palette.lineSoft),
          ],
        ],
      ),
    );
  }
}

class _HeadTailGrid extends StatelessWidget {
  const _HeadTailGrid({required this.stats, required this.maxCount});

  final Map<String, NumberStat> stats;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    const double cell = 34;

    Widget label(String text) => SizedBox(
      width: cell,
      height: 28,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: palette.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    Widget heat(String number) {
      final count = stats[number]?.count ?? 0;
      final intensity = maxCount == 0 ? 0.0 : count / maxCount;
      return Tooltip(
        message: '$number: $count lần',
        child: Container(
          width: cell,
          height: 30,
          alignment: Alignment.center,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: palette.gold.withValues(alpha: 0.06 + intensity * 0.4),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: palette.lineSoft),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: palette.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: cell, height: 28),
              for (var tail = 0; tail < 10; tail++) label('$tail'),
            ],
          ),
          for (var head = 0; head < 10; head++)
            Row(
              children: <Widget>[
                label('$head'),
                for (var tail = 0; tail < 10; tail++) heat('$head$tail'),
              ],
            ),
        ],
      ),
    );
  }
}

class _StructureSummary extends StatelessWidget {
  const _StructureSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.index,
    required this.label,
    required this.numbers,
    required this.percentage,
    required this.onRemove,
  });

  final int index;
  final String label;
  final List<String> numbers;
  final double percentage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: index == 0 ? palette.gold : const Color(0xFF58657A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  numbers.join(' · '),
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            formatPercent(percentage),
            style: TextStyle(
              color: palette.goldBright,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Xóa $label',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 16, color: palette.muted),
          ),
        ],
      ),
    );
  }
}
