// Tab Kho dữ liệu — port từ `DataCenter` trong frontend/components/lottery-app.tsx.
library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../domain/lottery_domain.dart';
import '../../logic/statistics.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class DataCenterTab extends StatefulWidget {
  const DataCenterTab({required this.draws, required this.onImport, super.key});

  final List<LotteryDraw> draws;
  final ValueChanged<List<LotteryDraw>> onImport;

  @override
  State<DataCenterTab> createState() => _DataCenterTabState();
}

class _DataCenterTabState extends State<DataCenterTab> {
  String _fileName = '';
  String _fileText = '';
  Region _region = Region.mienBac;

  bool get _isJson => _fileName.toLowerCase().endsWith('.json');

  /// Báo cáo kiểm định: CSV dùng `validateCsv`, JSON thử phân tích trước.
  CsvValidation? get _report {
    if (_fileText.isEmpty) return null;
    if (!_isJson) return validateCsv(_fileText);
    try {
      final parsed = parseJsonDraws(_fileText, _region);
      return CsvValidation(
        validRows: parsed.length,
        duplicateRows: 0,
        issues: const <DataIssue>[],
      );
    } on FormatException catch (error) {
      return _errorReport(error.message);
    } on Object {
      return _errorReport('JSON không hợp lệ.');
    }
  }

  CsvValidation _errorReport(String message) => CsvValidation(
    validRows: 0,
    duplicateRows: 0,
    issues: <DataIssue>[
      DataIssue(row: 0, level: DataIssueLevel.error, message: message),
    ],
  );

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'json'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fileName = file.name;
      _fileText = utf8.decode(bytes, allowMalformed: true);
    });
  }

  void _confirmImport() {
    final report = _report;
    if (report == null || report.validRows == 0 || report.hasError) return;
    final imported = _isJson
        ? parseJsonDraws(_fileText, _region)
        : parseCsvDraws(_fileText, region: _region);
    if (imported.isNotEmpty) widget.onImport(imported);
  }

  String get _latestDate {
    if (widget.draws.isEmpty) return '—';
    var latest = widget.draws.first.date;
    for (final draw in widget.draws) {
      if (draw.date.compareTo(latest) > 0) latest = draw.date;
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeading(
          eyebrow: 'QUẢN TRỊ DỮ LIỆU',
          title: 'Kho dữ liệu',
          description:
              'Biết dữ liệu đến từ đâu, được kiểm tra thế nào và cập nhật khi nào.',
          action: AppButton(
            label: 'Chọn CSV / JSON',
            icon: Icons.upload_file,
            onPressed: _pickFile,
          ),
        ),
        const SizedBox(height: 16),
        _buildSourceGrid(),
        const SizedBox(height: 16),
        _buildImportRow(),
        const SizedBox(height: 16),
        _buildProvenance(),
      ],
    );
  }

  Widget _buildSourceGrid() {
    final palette = PaletteScope.of(context);
    return ResponsiveGrid(
      minItemWidth: 340,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(Icons.storage, size: 20, color: palette.gold),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ĐANG SỬ DỤNG',
                      style: TextStyle(
                        color: palette.green,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dữ liệu mẫu cục bộ',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${widget.draws.length} kỳ · sinh bằng seed cố định để chạy thử an toàn.',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.check, size: 15, color: palette.green),
                  const SizedBox(width: 4),
                  Text(
                    'Sẵn sàng',
                    style: TextStyle(
                      color: palette.green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  size: 20,
                  color: palette.blue,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'TÙY CHỌN',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'API hợp pháp',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ánh xạ endpoint của đơn vị được cấp quyền trong lớp dữ liệu.',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Kết nối sau',
                tone: AppButtonTone.secondary,
                onPressed: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportRow() {
    final palette = PaletteScope.of(context);
    final report = _report;

    return ResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PanelHeader(
                icon: Icons.cloud_upload_outlined,
                eyebrow: 'NHẬP DỮ LIỆU',
                title: 'Kiểm tra trước khi lưu',
              ),
              _DropZone(fileName: _fileName, onTap: _pickFile),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.panelSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: palette.lineSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Định dạng tối thiểu',
                      style: TextStyle(
                        color: palette.mutedBright,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'date,dac_biet,giai_nhat,giai_nhi\n'
                      '2026-09-12,12345,54321,"11111 22222"',
                      style: TextStyle(
                        color: palette.goldBright,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Khu vực dữ liệu',
                style: TextStyle(color: palette.muted, fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              _RegionPicker(
                value: _region,
                onChanged: (value) => setState(() => _region = value),
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                icon: Icons.fact_check_outlined,
                eyebrow: 'KIỂM ĐỊNH',
                title: 'Báo cáo chất lượng',
                meta: report == null
                    ? null
                    : _QualityBadge(hasError: report.hasError),
              ),
              if (report == null)
                const EmptyState(
                  message:
                      'Chọn CSV hoặc JSON để xem lỗi định dạng, '
                      'dòng trùng và kỳ có thể bị thiếu.',
                )
              else ...<Widget>[
                ResponsiveGrid(
                  minItemWidth: 110,
                  maxColumns: 3,
                  children: <Widget>[
                    _ValidationStat(
                      value: '${report.validRows}',
                      label: 'Dòng hợp lệ',
                    ),
                    _ValidationStat(
                      value: '${report.duplicateRows}',
                      label: 'Dòng trùng',
                    ),
                    _ValidationStat(
                      value: '${report.issues.length}',
                      label: 'Cảnh báo',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (report.issues.isEmpty)
                  const _IssueRow(
                    title: 'Không phát hiện lỗi',
                    detail: 'Tệp sẵn sàng để nhập.',
                    isError: false,
                  )
                else
                  for (final (index, issue)
                      in report.issues.take(7).indexed) ...<Widget>[
                    if (index > 0) const SizedBox(height: 7),
                    _IssueRow(
                      title: issue.row > 0 ? 'Dòng ${issue.row}' : 'Chuỗi ngày',
                      detail: issue.message,
                      isError: issue.level == DataIssueLevel.error,
                    ),
                  ],
                const SizedBox(height: 14),
                AppButton(
                  label: 'Nhập ${report.validRows} kỳ hợp lệ',
                  icon: Icons.storage,
                  expanded: true,
                  onPressed: (report.validRows == 0 || report.hasError)
                      ? null
                      : _confirmImport,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProvenance() {
    final palette = PaletteScope.of(context);
    final head = TextStyle(
      color: palette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.7,
    );
    final cell = TextStyle(color: palette.mutedBright, fontSize: 12);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PanelHeader(
            icon: Icons.history,
            eyebrow: 'DẤU VẾT DỮ LIỆU',
            title: 'Nguồn và lần cập nhật',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ProvenanceRow(
                  cells: <Widget>[
                    for (final label in const <String>[
                      'Nguồn',
                      'Phạm vi',
                      'Cập nhật gần nhất',
                      'Trạng thái',
                    ])
                      Text(label, style: head),
                  ],
                ),
                Divider(height: 1, color: palette.lineSoft),
                _ProvenanceRow(
                  cells: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.storage, size: 15, color: palette.muted),
                        const SizedBox(width: 7),
                        Text('Mẫu cục bộ', style: cell),
                      ],
                    ),
                    Text('Miền Bắc · ${widget.draws.length} kỳ', style: cell),
                    Text('20:10 · ${formatDateLong(_latestDate)}', style: cell),
                    Row(
                      children: <Widget>[
                        Icon(Icons.check, size: 15, color: palette.green),
                        const SizedBox(width: 6),
                        Text(
                          'Đã kiểm tra',
                          style: TextStyle(
                            color: palette.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _ProvenanceRow extends StatelessWidget {
  const _ProvenanceRow({required this.cells});

  final List<Widget> cells;

  static const List<double> _widths = <double>[150, 200, 210, 170];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < cells.length; index++)
            SizedBox(width: _widths[index], child: cells[index]),
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.fileName, required this.onTap});

  final String fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Material(
      color: palette.panelSoft,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: palette.line),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.upload_file, size: 20, color: palette.gold),
              ),
              const SizedBox(height: 10),
              Text(
                fileName.isEmpty ? 'Chọn tệp CSV hoặc JSON' : fileName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fileName.isEmpty
                    ? 'Bấm để chọn · tối đa 10 MB'
                    : 'Chọn tệp khác',
                style: TextStyle(color: palette.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final color = hasError ? palette.coral : palette.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        hasError ? 'Cần xử lý' : 'Đạt',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ValidationStat extends StatelessWidget {
  const _ValidationStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: palette.muted, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    required this.title,
    required this.detail,
    required this.isError,
  });

  final String title;
  final String detail;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final color = isError ? palette.coral : palette.gold;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isError ? palette.coralSoft : palette.panelSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 16, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11.5,
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

class _RegionPicker extends StatelessWidget {
  const _RegionPicker({required this.value, required this.onChanged});

  final Region value;
  final ValueChanged<Region> onChanged;

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
      child: DropdownButton<Region>(
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
        items: <DropdownMenuItem<Region>>[
          for (final region in Region.values)
            DropdownMenuItem<Region>(
              value: region,
              child: Text(
                region.label,
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
