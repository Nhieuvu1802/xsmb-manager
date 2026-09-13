import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'theme.dart';

/// Khung panel dùng chung (`class="panel"` trong CSS).
class Panel extends StatelessWidget {
  const Panel({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.line),
        boxShadow: [
          // `shadow-sm` của Tailwind: 0 1px 2px rgba(0,0,0,.05).
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.3 : 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.meta,
    super.key,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget? meta;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
              border: Border.all(color: palette.gold.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 18, color: palette.goldBright),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: palette.goldBright,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          ?meta,
        ],
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: palette.goldBright,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

enum PillTone { neutral, hot, cold, gold }

class NumberPill extends StatelessWidget {
  const NumberPill({
    required this.number,
    this.tone = PillTone.neutral,
    this.width,
    super.key,
  });

  final String number;
  final PillTone tone;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final (background, foreground) = switch (tone) {
      PillTone.hot => (palette.coralSoft, palette.coral),
      PillTone.cold => (palette.blueSoft, palette.blue),
      PillTone.gold => (palette.goldSoft, palette.goldBright),
      PillTone.neutral => (palette.panelSoft, palette.mutedBright),
    };

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppPalette.radiusPill),
        border: Border.all(color: foreground.withValues(alpha: 0.28)),
      ),
      child: Text(
        number,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foreground,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class SourceChip extends StatelessWidget {
  const SourceChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: palette.mutedBright,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionCount extends StatelessWidget {
  const SelectionCount({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.lineSoft),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
      child: Column(
        children: [
          Icon(Icons.search, size: 24, color: palette.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

enum AppButtonTone { primary, secondary, gold }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = AppButtonTone.primary,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonTone tone;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final (background, foreground, border) = switch (tone) {
      AppButtonTone.primary => (palette.gold, palette.onGold, palette.gold),
      AppButtonTone.gold => (
        palette.goldBright,
        palette.onGold,
        palette.goldBright,
      ),
      AppButtonTone.secondary => (
        palette.panel,
        palette.mutedBright,
        palette.line,
      ),
    };

    return Opacity(
      opacity: onPressed == null ? 0.52 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhãn Δ (σ) dùng ở danh sách xếp hạng và bảng hồ sơ số.
class DeltaLabel extends StatelessWidget {
  const DeltaLabel({
    required this.value,
    this.digits = 1,
    this.unit = 'σ',
    super.key,
  });

  final double value;
  final int digits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final up = value >= 0;
    return Text(
      '${up ? '+' : ''}${value.toStringAsFixed(digits)}$unit',
      style: TextStyle(
        color: up ? palette.coral : palette.blue,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footer,
    this.footerIcon,
    this.tone = PillTone.neutral,
    this.featured = false,
    this.bars,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? footer;
  final IconData? footerIcon;
  final PillTone tone;
  final bool featured;
  final List<int>? bars;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final accent = switch (tone) {
      PillTone.hot => palette.coral,
      PillTone.cold => palette.blue,
      PillTone.gold => palette.goldBright,
      PillTone.neutral => palette.goldBright,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: featured ? palette.bgSoft : palette.panel,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.3 : 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
            ),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (footerIcon != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(footerIcon, size: 13, color: accent),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          footer!,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (bars != null)
            SizedBox(
              width: 74,
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final height in bars!)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: 40 * height / 100,
                          decoration: BoxDecoration(
                            color: palette.gold.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
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

class ResponsibleNotice extends StatelessWidget {
  const ResponsibleNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.bgSoft,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: palette.goldBright,
            size: 22,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '18+ · CHƠI CÓ TRÁCH NHIỆM',
                  style: TextStyle(
                    color: palette.goldBright,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Hiểu xác suất. Giữ giới hạn.',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Công cụ này chỉ phục vụ học tập và giải trí; không phải tư vấn tài chính hay hệ '
                  'thống dự đoán chắc chắn. Không vay tiền, không theo đuổi thua lỗ và hãy tuân thủ '
                  'pháp luật nơi bạn sinh sống.',
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

/// Lưới thẻ co giãn: nhiều cột trên màn hình rộng, 1 cột trên di động,
/// các thẻ trong cùng hàng luôn cao bằng nhau.
///
/// Dùng `Table` (không dùng `IntrinsicHeight`) nên có thể lồng nhau mà vẫn
/// tính được kích thước nội tại khi widget cha cần.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.minItemWidth = 280,
    this.maxColumns = 4,
    this.spacing = 14,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minItemWidth;
        final columns = math.max(
          1,
          math.min(maxColumns, (available / minItemWidth).floor()),
        );
        final rowStarts = <int>[
          for (var start = 0; start < children.length; start += columns) start,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (rowIndex, start) in rowStarts.indexed) ...<Widget>[
              if (rowIndex > 0) SizedBox(height: spacing),
              _EqualHeightRow(
                spacing: spacing,
                children: <Widget>[
                  for (var index = 0; index < columns; index++)
                    if (start + index < children.length)
                      children[start + index],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Hàng các ô có chiều cao bằng nhau.
///
/// Đo chiều cao thật của từng ô (không dùng intrinsics như `IntrinsicHeight`)
/// rồi căn lại theo ô cao nhất — nhờ vậy lưới lồng nhau vẫn hoạt động.
class _EqualHeightRow extends MultiChildRenderObjectWidget {
  const _EqualHeightRow({required this.spacing, required super.children});

  final double spacing;

  @override
  _RenderEqualHeightRow createRenderObject(BuildContext context) =>
      _RenderEqualHeightRow(spacing);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualHeightRow renderObject,
  ) {
    renderObject.spacing = spacing;
  }
}

class _EqualHeightRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualHeightRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightRowParentData> {
  _RenderEqualHeightRow(this._spacing);

  double _spacing;

  double get spacing => _spacing;

  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightRowParentData) {
      child.parentData = _EqualHeightRowParentData();
    }
  }

  @override
  void performLayout() {
    final count = childCount;
    final available = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : 0.0;
    if (count == 0) {
      size = Size(available, 0);
      return;
    }

    final childWidth = math.max(
      0.0,
      (available - _spacing * (count - 1)) / count,
    );

    var tallest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(
        BoxConstraints(minWidth: childWidth, maxWidth: childWidth),
        parentUsesSize: true,
      );
      tallest = math.max(tallest, child.size.height);
    }

    // Căn lại theo ô cao nhất nhưng vẫn cho phép ô cần thêm chỗ được cao hơn,
    // nhờ vậy không bao giờ tràn (overflow) như khi ép chiều cao tuyệt đối.
    var rowHeight = 0.0;
    var dx = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(
        BoxConstraints(
          minWidth: childWidth,
          maxWidth: childWidth,
          minHeight: tallest,
        ),
        parentUsesSize: true,
      );
      rowHeight = math.max(rowHeight, child.size.height);
      (child.parentData! as _EqualHeightRowParentData).offset = Offset(dx, 0);
      dx += childWidth + _spacing;
    }

    size = Size(available, rowHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

/// Tiêu đề khu vực kiểu trang tham chiếu: nhãn nhỏ **in hoa màu cam**
/// (`text-xs font-black uppercase tracking-wide`) + tiêu đề đậm và hành động
/// bên phải (như nút "Mở trang AI" của bản web).
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.eyebrow,
    required this.title,
    this.description,
    this.action,
    this.onNavy = false,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final Widget? action;

  /// Dùng trong dải hero tối → chữ chuyển sang tông `orange-100/200`.
  final bool onNavy;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 14,
        runSpacing: 10,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: onNavy ? palette.onNavySoft : palette.goldBright,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: onNavy ? palette.onNavy : palette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (description != null) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    description!,
                    style: TextStyle(
                      color: onNavy ? palette.onNavySoft : palette.muted,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Chip tròn nhỏ (`rounded-full px-2 py-1 text-xs font-black`) dùng cho nhãn
/// "Số nóng", "Lâu chưa về", trạng thái nguồn…
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final (background, foreground) = switch (tone) {
      PillTone.hot => (palette.coralSoft, palette.coral),
      PillTone.cold => (palette.blueSoft, palette.blue),
      PillTone.gold => (palette.goldSoft, palette.goldBright),
      PillTone.neutral => (palette.panelSoft, palette.mutedBright),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppPalette.radiusPill),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô số liệu nhỏ trong dải "Tóm tắt hôm nay" của site
/// (`rounded-lg bg-white/10 px-3 py-2`: nhãn mờ + giá trị lớn).
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.note,
    this.onNavy = false,
    super.key,
  });

  final String label;
  final String value;
  final String? note;
  final bool onNavy;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: onNavy ? palette.navyPanel : palette.panelSoft,
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        border: Border.all(color: onNavy ? palette.navyLine : palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: onNavy ? palette.onNavySoft : palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: onNavy ? palette.onNavy : palette.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              note!,
              style: TextStyle(
                color: onNavy ? palette.onNavySoft : palette.muted,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thanh "Điểm dữ liệu x/100" của site (`h-1.5 rounded-full bg-slate-100`).
class ScoreBar extends StatelessWidget {
  const ScoreBar({
    required this.score,
    this.tone = PillTone.gold,
    this.height = 6,
    super.key,
  });

  /// Điểm 0–100 (tự kẹp về khoảng hợp lệ).
  final int score;
  final PillTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final color = switch (tone) {
      PillTone.hot => palette.coral,
      PillTone.cold => palette.blue,
      PillTone.gold => palette.gold,
      PillTone.neutral => palette.muted,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppPalette.radiusPill),
      child: Stack(
        children: <Widget>[
          Container(height: height, color: palette.goldSoft),
          FractionallySizedBox(
            widthFactor: score.clamp(0, 100) / 100,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "tín hiệu thống kê" kiểu site: số lớn `text-3xl font-black tabular-nums`
/// + nhãn tròn ("Số nóng"…) + dòng "Điểm dữ liệu x/100" + mô tả số liệu thật.
class SignalCard extends StatelessWidget {
  const SignalCard({
    required this.number,
    required this.tag,
    required this.score,
    required this.note,
    this.tone = PillTone.hot,
    this.onTap,
    super.key,
  });

  final String number;
  final String tag;

  /// Điểm dữ liệu 0–100 suy từ z-score của số trong kỳ đang xét.
  final int score;
  final String note;
  final PillTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final accent = switch (tone) {
      PillTone.hot => palette.coral,
      PillTone.cold => palette.blue,
      PillTone.gold => palette.goldBright,
      PillTone.neutral => palette.mutedBright,
    };
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.3 : 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                number,
                style: TextStyle(
                  color: accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              StatusChip(label: tag, tone: tone),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                'Điểm dữ liệu',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$score/100',
                style: TextStyle(
                  color: palette.mutedBright,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ScoreBar(score: score, tone: tone),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppPalette.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppPalette.radius),
        child: card,
      ),
    );
  }
}

/// Dải hero tối kiểu trang tham chiếu: nền `navy-950` chuyển dần sang
/// `#0B224A`, quầng sáng cam ở góc, nhãn nhỏ, tiêu đề lớn, mô tả, nút hành
/// động và vùng thẻ mờ (`bg-white/10`) bên phải.
class HeroBand extends StatelessWidget {
  const HeroBand({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.actions = const <Widget>[],
    this.aside,
    this.badgeIcon = Icons.auto_awesome,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> actions;
  final Widget? aside;
  final IconData badgeIcon;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    final lead = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: palette.navyPanel,
            borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            border: Border.all(color: palette.navyLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(badgeIcon, size: 13, color: palette.warm),
              const SizedBox(width: 6),
              Text(
                eyebrow.toUpperCase(),
                style: TextStyle(
                  color: palette.onNavySoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            color: palette.onNavy,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.18,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            color: palette.onNavySoft,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        if (actions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppPalette.radius + 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[palette.navy, palette.navySoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -70,
              right: -50,
              child: _HeroGlow(
                size: 210,
                color: palette.warm.withValues(alpha: 0.3),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: _HeroGlow(
                size: 230,
                color: palette.gold.withValues(alpha: 0.22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (aside == null) return lead;
                  if (constraints.maxWidth >= 820) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(flex: 5, child: lead),
                        const SizedBox(width: 22),
                        Expanded(flex: 4, child: aside!),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      lead,
                      const SizedBox(height: 18),
                      aside!,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quầng sáng mờ trang trí cho [HeroBand].
class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ),
    ),
  );
}
