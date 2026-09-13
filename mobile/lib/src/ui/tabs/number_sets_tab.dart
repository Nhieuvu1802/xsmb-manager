// Tab "Bộ tính số" — sinh bộ số 00–99 theo chiến lược dựa trên lịch sử.
//
// Các nhóm chiến lược: ngẫu nhiên đều, theo tần suất (nóng), theo gan (lạnh),
// cân bằng chỉ số và theo thứ. Mọi lần sinh đều **tái lập được** bằng seed, và
// mỗi bộ được đối chiếu ngay với cửa sổ lịch sử gần nhất để người dùng thấy
// kết quả nằm ở đâu so với xác suất lý thuyết.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/lottery_dates.dart';
import '../../data/models/generated_run.dart';
import '../../domain/archive/lotto_archive.dart';
import '../../domain/generator/history_match.dart';
import '../../domain/generator/number_generator.dart';
import '../../domain/lottery_domain.dart';
import '../../logic/statistics.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class NumberSetsTab extends StatefulWidget {
  const NumberSetsTab({
    required this.draws,
    required this.regionLabel,
    required this.saved,
    required this.onSave,
    super.key,
  });

  /// Lịch sử đã lọc theo vùng và khoảng kỳ đang chọn.
  final List<LotteryDraw> draws;

  final String regionLabel;

  /// Các lần sinh đã lưu trong database cục bộ (mới nhất trước).
  final List<GeneratedRunRecord> saved;

  /// Lưu một lần sinh vào database (do `shell.dart` thực hiện).
  final Future<void> Function(GeneratorOutcome outcome) onSave;

  @override
  State<NumberSetsTab> createState() => _NumberSetsTabState();
}

class _NumberSetsTabState extends State<NumberSetsTab> {
  late final TextEditingController _excludedController =
      TextEditingController();
  late final TextEditingController _seedController = TextEditingController(
    text: '${GeneratorEngine.randomSeed()}',
  );

  GeneratorStrategy _strategy = GeneratorStrategy.balanced;
  GeneratorSortOrder _sortOrder = GeneratorSortOrder.ascending;
  int _numbersPerSet = 6;
  int _setCount = 3;
  int _specialMax = 12;
  int _window = 30;
  bool _uniqueWithinSet = true;
  bool _uniqueAcrossSets = true;
  bool _withSpecial = false;
  bool _fixedSeed = false;
  bool _saving = false;

  GeneratorOutcome? _outcome;
  HistoryMatch? _match;
  String? _error;

  @override
  void dispose() {
    _excludedController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  NumberSetParse get _excludedParse => parseNumberSet(_excludedController.text);

  List<int> get _excludedNumbers => <int>[
    for (final number in _excludedParse.numbers) int.parse(number),
  ];

  /// Ngày mục tiêu cho chiến lược `weekday`: ngày kế tiếp ngày mới nhất.
  String get _targetDate {
    final dates = widget.draws.map((draw) => draw.date).toList()..sort();
    final latest = dates.isEmpty ? null : parseIsoDate(dates.last);
    final base = latest ?? todayInVietnam();
    return isoDate(base.add(const Duration(days: 1)));
  }

  GeneratorSettings get _settings => GeneratorSettings(
    numbersPerSet: _numbersPerSet,
    setCount: _setCount,
    excluded: _excludedNumbers,
    sortOrder: _sortOrder,
    uniqueWithinSet: _uniqueWithinSet,
    uniqueAcrossSets: _uniqueAcrossSets,
    specialMax: _withSpecial ? _specialMax : null,
    seed: _fixedSeed ? int.tryParse(_seedController.text.trim()) : null,
  );

  LottoArchive get _archive =>
      LottoArchive.fromDraws(widget.draws, region: widget.regionLabel);

  void _generate() {
    final settings = _settings;
    if (_excludedParse.invalid.isNotEmpty) {
      setState(
        () => _error =
            'Số loại trừ không hợp lệ: ${_excludedParse.invalid.join(', ')}',
      );
      return;
    }
    final errors = settings.validate();
    if (errors.isNotEmpty) {
      setState(() => _error = errors.first);
      return;
    }
    try {
      final archive = _archive;
      final outcome = GeneratorEngine.generate(
        history: widget.draws,
        strategy: _strategy,
        settings: settings,
        targetDate: _targetDate,
        archive: archive,
        seed: settings.seed ?? GeneratorEngine.randomSeed(),
      );
      setState(() {
        _outcome = outcome;
        _match = HistoryMatch.backcheck(
          sets: outcome.sets,
          history: widget.draws,
          archive: archive,
          window: _window,
        );
        _error = null;
      });
    } catch (error) {
      setState(() => _error = 'Không sinh được bộ số: $error');
    }
  }

  void _rollSeed() {
    setState(() {
      _seedController.text = '${GeneratorEngine.randomSeed()}';
      _fixedSeed = true;
    });
  }

  Future<void> _copyOutcome() async {
    final outcome = _outcome;
    if (outcome == null) return;
    final lines = <String>[
      '${widget.regionLabel} · ${outcome.strategy.label} · seed ${outcome.seed}',
      for (final set in outcome.sets)
        'Bộ ${set.index}: ${set.numbers.join(' ')}'
            '${set.special == null ? '' : ' | ĐB ${set.special}'}',
      GeneratorOutcome.disclaimer,
    ];
    try {
      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    } catch (_) {
      // Clipboard có thể bị chặn (web/desktop) — không làm hỏng luồng UI.
    }
  }

  Future<void> _saveOutcome() async {
    final outcome = _outcome;
    if (outcome == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(outcome);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Thứ của ngày mục tiêu — giải thích cho chiến lược `weekday`.
  String get _targetWeekday {
    final label = weekdayLabelOf(_targetDate) ?? '—';
    return '$label · ${formatDateLong(_targetDate)}';
  }

  String get _historyLabel {
    final draws = widget.draws;
    if (draws.isEmpty) return 'Chưa có kỳ nào trong khoảng đang chọn';
    final dates = draws.map((draw) => draw.date).toList()..sort();
    return '${draws.length} kỳ · ${dates.first} → ${dates.last}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeading(
          eyebrow: 'Bộ tính số',
          title: 'Sinh bộ số theo lịch sử',
          description:
              'Trọng số lấy từ $historyLabelText. Mỗi lần sinh đều tái lập được '
              'bằng seed và được đối chiếu ngay với lịch sử gần nhất.',
          action: AppButton(
            label: 'Sinh bộ số',
            icon: Icons.casino_outlined,
            tone: AppButtonTone.gold,
            onPressed: _generate,
          ),
        ),
        ResponsiveGrid(
          minItemWidth: 340,
          maxColumns: 2,
          children: <Widget>[_configPanel(palette), _resultPanel(palette)],
        ),
        const SizedBox(height: 14),
        _matchPanel(palette),
        const SizedBox(height: 14),
        _historyPanel(palette),
        const SizedBox(height: 14),
        const ResponsibleNotice(),
      ],
    );
  }

  String get historyLabelText => '${widget.regionLabel} ($_historyLabel)';

  /// Tính lại bảng đối chiếu khi cửa sổ kỳ thay đổi.
  void _refreshMatch() {
    final outcome = _outcome;
    if (outcome == null) return;
    _match = HistoryMatch.backcheck(
      sets: outcome.sets,
      history: widget.draws,
      archive: _archive,
      window: _window,
    );
  }

  Widget _configPanel(AppPalette palette) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.tune,
            eyebrow: 'CẤU HÌNH',
            title: 'Chiến lược và kho số',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final strategy in GeneratorStrategy.values)
                _StrategyChip(
                  label: strategy.label,
                  selected: strategy == _strategy,
                  onTap: () => setState(() => _strategy = strategy),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _strategy.description,
            style: TextStyle(color: palette.muted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Kho số: $_historyLabel',
            style: TextStyle(color: palette.muted, fontSize: 11.5),
          ),
          if (_strategy == GeneratorStrategy.weekday) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Ngày mục tiêu: $_targetWeekday',
              style: TextStyle(
                color: palette.goldBright,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _NumberSlider(
            label: 'Số mỗi bộ',
            value: _numbersPerSet,
            min: 1,
            max: 20,
            onChanged: (value) => setState(() => _numbersPerSet = value),
          ),
          _NumberSlider(
            label: 'Số bộ mỗi lần sinh',
            value: _setCount,
            min: 1,
            max: 20,
            onChanged: (value) => setState(() => _setCount = value),
          ),
          _NumberSlider(
            label: 'Bóng đặc biệt (1–$_specialMax)',
            value: _specialMax,
            min: 2,
            max: 99,
            enabled: _withSpecial,
            onChanged: (value) => setState(() => _specialMax = value),
          ),
          _NumberSlider(
            label: 'Cửa sổ đối chiếu ($_window kỳ)',
            value: _window,
            min: 10,
            max: 90,
            step: 10,
            onChanged: (value) => setState(() {
              _window = value;
              _refreshMatch();
            }),
          ),
          const Divider(height: 26),
          Text(
            'SẮP XẾP SỐ TRONG BỘ',
            style: TextStyle(
              color: palette.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final order in GeneratorSortOrder.values)
                _StrategyChip(
                  label: order.label,
                  selected: order == _sortOrder,
                  onTap: () => setState(() => _sortOrder = order),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _ToggleRow(
            label: 'Không trùng số trong một bộ',
            value: _uniqueWithinSet,
            onChanged: (value) => setState(() => _uniqueWithinSet = value),
          ),
          _ToggleRow(
            label: 'Các bộ không trùng nhau',
            value: _uniqueAcrossSets,
            onChanged: (value) => setState(() => _uniqueAcrossSets = value),
          ),
          _ToggleRow(
            label: 'Thêm bóng đặc biệt',
            value: _withSpecial,
            onChanged: (value) => setState(() => _withSpecial = value),
          ),
          _ToggleRow(
            label: 'Cố định seed (tái lập kết quả)',
            value: _fixedSeed,
            onChanged: (value) => setState(() => _fixedSeed = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _excludedController,
            style: TextStyle(color: palette.text, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Số loại trừ',
              hintText: 'Ví dụ: 00, 05, 42',
              helperText: 'Cách nhau bởi dấu phẩy hoặc khoảng trắng.',
              helperStyle: TextStyle(color: palette.muted, fontSize: 11),
              labelStyle: TextStyle(color: palette.muted, fontSize: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _seedController,
            enabled: _fixedSeed,
            keyboardType: TextInputType.number,
            style: TextStyle(color: palette.text, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Seed',
              helperText: 'Cùng seed + cùng cấu hình ⇒ cùng bộ số.',
              helperStyle: TextStyle(color: palette.muted, fontSize: 11),
              labelStyle: TextStyle(color: palette.muted, fontSize: 12),
              isDense: true,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: palette.coral, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              AppButton(
                label: 'Sinh bộ số',
                icon: Icons.casino_outlined,
                onPressed: _generate,
              ),
              AppButton(
                label: 'Seed mới',
                icon: Icons.autorenew,
                tone: AppButtonTone.secondary,
                onPressed: _rollSeed,
              ),
              AppButton(
                label: 'Lưu vào lịch sử',
                icon: Icons.save_outlined,
                tone: AppButtonTone.secondary,
                onPressed: _outcome == null || _saving ? null : _saveOutcome,
              ),
              AppButton(
                label: 'Sao chép',
                icon: Icons.copy_all_outlined,
                tone: AppButtonTone.secondary,
                onPressed: _outcome == null ? null : _copyOutcome,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultPanel(AppPalette palette) {
    final outcome = _outcome;
    final match = _match;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.grid_view_outlined,
            eyebrow: 'KẾT QUẢ',
            title: outcome == null ? 'Chưa sinh bộ số' : 'Bộ số vừa sinh',
            meta: outcome == null
                ? null
                : SelectionCount(label: 'seed ${outcome.seed}'),
          ),
          if (outcome == null)
            const EmptyState(
              message:
                  'Chọn chiến lược, chỉnh cấu hình rồi bấm "Sinh bộ số". '
                  'Mọi bộ sinh ra đều được đối chiếu với lịch sử ở bên dưới.',
            )
          else ...<Widget>[
            Text(
              outcome.summary,
              style: TextStyle(
                color: palette.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nguồn trọng số: ${outcome.weights.source}',
              style: TextStyle(color: palette.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Số có trọng số cao nhất: '
              '${outcome.weights.topNumbers(6).join(' · ')}',
              style: TextStyle(color: palette.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 12),
            for (final set in outcome.sets) _setCard(palette, set, match),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: palette.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GeneratorOutcome.disclaimer,
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
        ],
      ),
    );
  }

  Widget _setCard(AppPalette palette, GeneratedSet set, HistoryMatch? match) {
    final rows = match?.rows;
    final row = rows == null || set.index > rows.length
        ? null
        : rows[set.index - 1];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Bộ ${set.index}',
                style: TextStyle(
                  color: palette.goldBright,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tổng ${set.sum}',
                style: TextStyle(color: palette.muted, fontSize: 11.5),
              ),
              const Spacer(),
              if (set.special != null)
                Text(
                  'ĐB ${set.special}',
                  style: TextStyle(
                    color: palette.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final number in set.numbers)
                NumberPill(number: number, tone: PillTone.gold),
            ],
          ),
          if (row != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '${row.hitDraws}/${row.windowDraws} kỳ gần nhất có số của bộ · '
              '${row.verdict}',
              style: TextStyle(
                color: palette.muted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Nạp lại một lần sinh đã lưu (kèm seed) vào bảng cấu hình + kết quả.
  void _loadRun(GeneratedRunRecord run) {
    final settings = run.settings;
    setState(() {
      _strategy = run.strategy;
      _sortOrder = settings.sortOrder;
      _numbersPerSet = settings.numbersPerSet;
      _setCount = settings.setCount;
      _uniqueWithinSet = settings.uniqueWithinSet;
      _uniqueAcrossSets = settings.uniqueAcrossSets;
      _withSpecial = settings.specialMax != null;
      if (settings.specialMax != null) _specialMax = settings.specialMax!;
      _fixedSeed = true;
      _seedController.text = '${run.seed}';
      _excludedController.text = <String>[
        for (final number in settings.excluded)
          number.toString().padLeft(2, '0'),
      ].join(', ');
      _outcome = run.toOutcome(history: widget.draws);
      _error = null;
      _refreshMatch();
    });
  }

  Widget _matchPanel(AppPalette palette) {
    final match = _match;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.fact_check_outlined,
            eyebrow: 'ĐỐI CHIẾU LỊCH SỬ',
            title: 'Bộ số so với kỳ vọng lý thuyết',
            meta: SelectionCount(label: 'cửa sổ $_window kỳ'),
          ),
          if (match == null || match.isEmpty)
            const EmptyState(
              message:
                  'Sinh bộ số để đối chiếu với các kỳ gần nhất: bao nhiêu kỳ có '
                  'ít nhất một số của bộ, so với xác suất lý thuyết.',
            )
          else ...<Widget>[
            Text(
              match.verdict,
              style: TextStyle(
                color: palette.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kỳ vọng lý thuyết cho bộ $_numbersPerSet số: '
              '${SetBackcheck.formatRate(match.expectedRate)} · quan sát trung '
              'bình: ${SetBackcheck.formatRate(match.averageHitRate)} · kho '
              '${match.archiveDrawCount} kỳ',
              style: TextStyle(
                color: palette.muted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in match.rows) _matchRow(palette, row),
            Text(
              'Khoảng tin cậy Wilson 95%: nếu xác suất lý thuyết nằm trong '
              'khoảng này thì khác biệt chỉ là dao động mẫu, không phải bộ số '
              '"tốt hơn".',
              style: TextStyle(
                color: palette.muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _matchRow(AppPalette palette, SetBackcheck row) {
    final interval = row.hitRateInterval;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Bộ ${row.setIndex}',
                style: TextStyle(
                  color: palette.goldBright,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${row.hitDraws}/${row.windowDraws} kỳ',
                style: TextStyle(color: palette.muted, fontSize: 11.5),
              ),
              const Spacer(),
              SelectionCount(label: SetBackcheck.formatRate(row.hitRate)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kỳ vọng ${SetBackcheck.formatRate(row.expectedRate)} · khoảng 95% '
            '${SetBackcheck.formatRate(interval.first)}–'
            '${SetBackcheck.formatRate(interval.last)}',
            style: TextStyle(color: palette.muted, fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Text(
            row.verdict,
            style: TextStyle(
              color: row.matchesExpectation ? palette.green : palette.coral,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final number in row.numbers)
                NumberPill(
                  number: number,
                  tone: (row.occurrences[number] ?? 0) > 0
                      ? PillTone.hot
                      : PillTone.cold,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lượt về trong cửa sổ: '
            '${<String>[for (final number in row.numbers) '$number:${row.occurrences[number] ?? 0}'].join(' · ')}',
            style: TextStyle(color: palette.muted, fontSize: 11),
          ),
          if (row.neverSeenNumbers.isNotEmpty)
            Text(
              'Chưa từng về trong kho: ${row.neverSeenNumbers.join(', ')}',
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _historyPanel(AppPalette palette) {
    final saved = widget.saved;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            icon: Icons.history,
            eyebrow: 'LỊCH SỬ SINH',
            title: 'Các lần sinh đã lưu',
            meta: SelectionCount(label: '${saved.length} lần'),
          ),
          if (saved.isEmpty)
            const EmptyState(
              message:
                  'Chưa lưu lần sinh nào. Bấm "Lưu vào lịch sử" để giữ lại bộ số '
                  'kèm seed — lần sau nạp lại là ra đúng bộ số cũ.',
            )
          else
            for (final run in saved) _runRow(palette, run),
        ],
      ),
    );
  }

  Widget _runRow(AppPalette palette, GeneratedRunRecord run) {
    final createdAt = run.createdAt;
    final date = createdAt.length >= 10
        ? formatDateLong(createdAt.substring(0, 10))
        : createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${run.strategy.label} · ${run.setCount} bộ',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SelectionCount(label: 'seed ${run.seed}'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$date · ${run.settings.numbersPerSet} số/bộ · '
            '${run.settings.sortOrder.label}',
            style: TextStyle(color: palette.muted, fontSize: 11.5),
          ),
          if (run.targetDate != null)
            Text(
              'Ngày mục tiêu: ${run.targetDate}',
              style: TextStyle(color: palette.muted, fontSize: 11.5),
            ),
          const SizedBox(height: 8),
          for (final set in run.sets)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Bộ ${set.index}: ${set.numbers.join(' ')}'
                '${set.special == null ? '' : ' | ĐB ${set.special}'}',
                style: TextStyle(
                  color: palette.mutedBright,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 6),
          AppButton(
            label: 'Nạp lại cấu hình + seed',
            icon: Icons.replay_outlined,
            tone: AppButtonTone.secondary,
            onPressed: () => _loadRun(run),
          ),
        ],
      ),
    );
  }
}

/// Chip chọn chiến lược / cách sắp xếp.
class _StrategyChip extends StatelessWidget {
  const _StrategyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Material(
      color: selected ? palette.goldSoft : palette.panelSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? palette.gold : palette.lineSoft,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? palette.goldBright : palette.mutedBright,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng bật/tắt dạng ô chọn — tránh `Switch` để không phụ thuộc phiên bản.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(
              value ? Icons.check_box_outlined : Icons.check_box_outline_blank,
              size: 19,
              color: value ? palette.gold : palette.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: palette.mutedBright, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh trượt số nguyên kèm nhãn, giá trị và bước nhảy.
class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.enabled = true,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final divisions = ((max - min) / step).round();
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: palette.goldBright,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions < 1 ? 1 : divisions,
            activeColor: palette.gold,
            label: '$value',
            onChanged: enabled ? (raw) => onChanged(_snap(raw)) : null,
          ),
        ],
      ),
    );
  }

  int _snap(double raw) {
    if (step <= 1) return raw.round().clamp(min, max);
    final steps = ((raw - min) / step).round();
    return (min + steps * step).clamp(min, max);
  }
}
