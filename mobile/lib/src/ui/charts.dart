import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Một điểm dữ liệu cho biểu đồ xu hướng (`AreaChart` của recharts).
@immutable
class ChartPoint {
  const ChartPoint(this.label, this.value);

  final String label;
  final num value;

  @override
  bool operator ==(Object other) =>
      other is ChartPoint && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);
}

/// Biểu đồ vùng cho xu hướng nhóm số (thay `<AreaChart>` + gradient vàng).
class TrendAreaChart extends StatelessWidget {
  const TrendAreaChart({required this.points, this.height = 260, super.key});

  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrendPainter(points: points, palette: palette),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.palette});

  final List<ChartPoint> points;
  final AppPalette palette;

  static const EdgeInsets _padding = EdgeInsets.only(
    left: 34,
    right: 10,
    top: 14,
    bottom: 26,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _padding.left,
      _padding.top,
      size.width - _padding.right,
      size.height - _padding.bottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final maxValue = math.max(
      1,
      points.fold<num>(0, (previous, point) => math.max(previous, point.value)),
    );
    final axisMax = _niceMax(maxValue.toDouble());

    // Lưới ngang + nhãn trục Y (allowDecimals={false}).
    final gridPaint = Paint()
      ..color = palette.line.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const rows = 4;
    for (var index = 0; index <= rows; index++) {
      final ratio = index / rows;
      final y = plot.bottom - plot.height * ratio;
      _drawDashedLine(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        gridPaint,
      );
      _drawChartText(
        canvas,
        (axisMax * ratio).round().toString(),
        Offset(plot.left - 8, y),
        palette.muted,
        10,
        alignRight: true,
        centerVertically: true,
      );
    }

    if (points.isEmpty) {
      _drawChartText(
        canvas,
        'Chưa đủ dữ liệu',
        plot.center,
        palette.muted,
        12,
        alignCenter: true,
        centerVertically: true,
      );
      return;
    }

    final step = points.length == 1 ? 0.0 : plot.width / (points.length - 1);
    final offsets = <Offset>[
      for (var index = 0; index < points.length; index++)
        Offset(
          points.length == 1 ? plot.center.dx : plot.left + step * index,
          plot.bottom - plot.height * (points[index].value / axisMax),
        ),
    ];

    final areaPath = _monotonePath(offsets)..lineTo(plot.right, plot.bottom);
    if (points.length == 1) areaPath.lineTo(plot.left, plot.bottom);
    areaPath.close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.gold.withValues(alpha: 0.35),
            palette.gold.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );

    canvas.drawPath(
      _monotonePath(offsets),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = palette.gold,
    );

    if (points.length <= 20) {
      final dotFill = Paint()..color = palette.gold;
      final dotRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = palette.panel;
      for (final offset in offsets) {
        canvas.drawCircle(offset, 3, dotFill);
        canvas.drawCircle(offset, 3, dotRing);
      }
    }

    // Nhãn trục X: giữ điểm đầu và điểm cuối (`interval="preserveStartEnd"`).
    final labelStep = math.max(1, (points.length / 6).ceil());
    for (var index = 0; index < points.length; index++) {
      final isEdge = index == 0 || index == points.length - 1;
      if (!isEdge && index % labelStep != 0) continue;
      _drawChartText(
        canvas,
        points[index].label,
        Offset(offsets[index].dx, plot.bottom + 8),
        palette.muted,
        10,
        alignCenter: true,
      );
    }
  }

  double _niceMax(double value) {
    if (value <= 4) return math.max(1, value.ceilToDouble());
    final magnitude = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    for (final factor in <double>[1, 1.5, 2, 2.5, 3, 4, 5, 7.5, 10]) {
      final candidate = magnitude * factor;
      if (candidate >= value) return candidate;
    }
    return magnitude * 10;
  }

  /// Nội suy đơn điệu (Fritsch–Carlson) — tương đương `type="monotone"`.
  Path _monotonePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 2) return path;

    final count = points.length;
    final deltas = <double>[];
    for (var index = 0; index < count - 1; index++) {
      final dx = points[index + 1].dx - points[index].dx;
      deltas.add(dx == 0 ? 0 : (points[index + 1].dy - points[index].dy) / dx);
    }

    final slopes = List<double>.filled(count, 0);
    slopes[0] = deltas.first;
    slopes[count - 1] = deltas.last;
    for (var index = 1; index < count - 1; index++) {
      slopes[index] = (deltas[index - 1] + deltas[index]) / 2;
    }

    for (var index = 0; index < count - 1; index++) {
      if (deltas[index] == 0) {
        slopes[index] = 0;
        slopes[index + 1] = 0;
        continue;
      }
      final alpha = slopes[index] / deltas[index];
      final beta = slopes[index + 1] / deltas[index];
      if (alpha < 0) slopes[index] = 0;
      if (beta < 0) slopes[index + 1] = 0;
      final magnitude = alpha * alpha + beta * beta;
      if (magnitude > 9) {
        final scale = 3 / math.sqrt(magnitude);
        slopes[index] = scale * alpha * deltas[index];
        slopes[index + 1] = scale * beta * deltas[index];
      }
    }

    for (var index = 0; index < count - 1; index++) {
      final dx = (points[index + 1].dx - points[index].dx) / 3;
      path.cubicTo(
        points[index].dx + dx,
        points[index].dy + slopes[index] * dx,
        points[index + 1].dx - dx,
        points[index + 1].dy - slopes[index + 1] * dx,
        points[index + 1].dx,
        points[index + 1].dy,
      );
    }
    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 3.0;
    const gap = 5.0;
    var x = from.dx;
    while (x < to.dx) {
      canvas.drawLine(
        Offset(x, from.dy),
        Offset(math.min(x + dash, to.dx), to.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.points != points || !identical(oldDelegate.palette, palette);
}

void _drawChartText(
  Canvas canvas,
  String text,
  Offset position,
  Color color,
  double fontSize, {
  bool alignCenter = false,
  bool alignRight = false,
  bool centerVertically = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  final dx = alignCenter
      ? position.dx - painter.width / 2
      : alignRight
      ? position.dx - painter.width
      : position.dx;
  final dy = centerVertically ? position.dy - painter.height / 2 : position.dy;
  painter.paint(canvas, Offset(dx, dy));
}

/// Một cột của biểu đồ cột (`BarChart`/`Bar` của recharts).
@immutable
class BarDatum {
  const BarDatum(this.label, this.value, {this.color});

  final String label;
  final num value;
  final Color? color;
}

/// Biểu đồ cột đơn (ngày trong tuần, tần suất chữ số).
class BarsChart extends StatelessWidget {
  const BarsChart({
    required this.bars,
    this.height = 200,
    this.barColor,
    this.firstBarColor,
    this.unit = '',
    this.maxBarWidth = 46,
    super.key,
  });

  final List<BarDatum> bars;
  final double height;
  final Color? barColor;
  final Color? firstBarColor;
  final String unit;
  final double maxBarWidth;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarsPainter(
          bars: bars,
          palette: palette,
          barColor: barColor ?? palette.gold,
          firstBarColor: firstBarColor,
          unit: unit,
          maxBarWidth: maxBarWidth,
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.bars,
    required this.palette,
    required this.barColor,
    required this.unit,
    required this.maxBarWidth,
    this.firstBarColor,
  });

  final List<BarDatum> bars;
  final AppPalette palette;
  final Color barColor;
  final Color? firstBarColor;
  final String unit;
  final double maxBarWidth;

  static const EdgeInsets _padding = EdgeInsets.only(
    left: 30,
    right: 6,
    top: 12,
    bottom: 24,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _padding.left,
      _padding.top,
      size.width - _padding.right,
      size.height - _padding.bottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final rawMax = bars.fold<num>(
      0,
      (previous, bar) => math.max(previous, bar.value),
    );
    final axisMax = _axisMax(rawMax.toDouble(), unit);

    final gridPaint = Paint()
      ..color = palette.line.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const rows = 4;
    for (var index = 0; index <= rows; index++) {
      final ratio = index / rows;
      final y = plot.bottom - plot.height * ratio;
      _drawDashed(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        gridPaint,
      );
      _drawChartText(
        canvas,
        _formatTick(axisMax * ratio),
        Offset(plot.left - 8, y),
        palette.muted,
        9.5,
        alignRight: true,
        centerVertically: true,
      );
    }

    if (bars.isEmpty) {
      _drawChartText(
        canvas,
        'Chưa đủ dữ liệu',
        plot.center,
        palette.muted,
        12,
        alignCenter: true,
        centerVertically: true,
      );
      return;
    }

    final slot = plot.width / bars.length;
    final barWidth = math.min(maxBarWidth, slot * 0.62);
    for (var index = 0; index < bars.length; index++) {
      final bar = bars[index];
      final centerX = plot.left + slot * (index + 0.5);
      final barHeight = axisMax == 0
          ? 0.0
          : plot.height * (bar.value / axisMax);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          plot.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final color =
          bar.color ??
          (index == 0 && firstBarColor != null ? firstBarColor! : barColor);
      canvas.drawRRect(rect, Paint()..color = color);
      _drawChartText(
        canvas,
        bar.label,
        Offset(centerX, plot.bottom + 7),
        palette.muted,
        10,
        alignCenter: true,
      );
    }
  }

  double _axisMax(double value, String unit) {
    if (unit == '%') {
      if (value <= 10) return 10;
      return (value / 10).ceilToDouble() * 10;
    }
    if (value <= 4) return math.max(1, value.ceilToDouble());
    final magnitude = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    for (final factor in <double>[1, 1.5, 2, 2.5, 3, 4, 5, 7.5, 10]) {
      if (magnitude * factor >= value) return magnitude * factor;
    }
    return magnitude * 10;
  }

  String _formatTick(double value) => value >= 10
      ? value.round().toString()
      : value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 3.0;
    const gap = 5.0;
    var x = from.dx;
    while (x < to.dx) {
      canvas.drawLine(
        Offset(x, from.dy),
        Offset(math.min(x + dash, to.dx), to.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.bars != bars || !identical(oldDelegate.palette, palette);
}

/// Một chuỗi dữ liệu của biểu đồ cột nhóm (`<Bar>` lặp lại trong recharts).
@immutable
class BarSeries {
  const BarSeries({
    required this.name,
    required this.values,
    required this.color,
  });

  final String name;
  final List<num> values;
  final Color color;
}

/// Biểu đồ cột nhóm — dùng cho phần "Nhiều bộ số trên cùng màn hình".
class GroupedBarsChart extends StatelessWidget {
  const GroupedBarsChart({
    required this.labels,
    required this.series,
    this.height = 240,
    this.unit = '',
    super.key,
  });

  final List<String> labels;
  final List<BarSeries> series;
  final double height;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final palette = PaletteScope.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _GroupedBarsPainter(
          labels: labels,
          series: series,
          palette: palette,
          unit: unit,
        ),
      ),
    );
  }
}

class _GroupedBarsPainter extends CustomPainter {
  _GroupedBarsPainter({
    required this.labels,
    required this.series,
    required this.palette,
    required this.unit,
  });

  final List<String> labels;
  final List<BarSeries> series;
  final AppPalette palette;
  final String unit;

  static const EdgeInsets _padding = EdgeInsets.only(
    left: 32,
    right: 8,
    top: 14,
    bottom: 26,
  );
  static const double _barGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _padding.left,
      _padding.top,
      size.width - _padding.right,
      size.height - _padding.bottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final rawMax = series
        .expand((item) => item.values)
        .fold<num>(0, (previous, value) => math.max(previous, value));
    final axisMax = unit == '%'
        ? (rawMax <= 10 ? 10.0 : (rawMax / 10).ceilToDouble() * 10)
        : math.max(1, rawMax.ceilToDouble());

    final gridPaint = Paint()
      ..color = palette.line.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const rows = 4;
    for (var index = 0; index <= rows; index++) {
      final ratio = index / rows;
      final y = plot.bottom - plot.height * ratio;
      var x = plot.left;
      while (x < plot.right) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, plot.right), y),
          gridPaint,
        );
        x += 8;
      }
      _drawChartText(
        canvas,
        '${(axisMax * ratio).round()}$unit',
        Offset(plot.left - 8, y),
        palette.muted,
        10,
        alignRight: true,
        centerVertically: true,
      );
    }

    if (labels.isEmpty || series.isEmpty) return;

    final slot = plot.width / labels.length;
    final available = slot * 0.68;
    final barWidth = math.max(
      6.0,
      (available - _barGap * (series.length - 1)) / series.length,
    );
    final groupWidth = barWidth * series.length + _barGap * (series.length - 1);

    for (var groupIndex = 0; groupIndex < labels.length; groupIndex++) {
      final groupLeft = plot.left + slot * (groupIndex + 0.5) - groupWidth / 2;
      for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
        final values = series[seriesIndex].values;
        final value = groupIndex < values.length ? values[groupIndex] : 0;
        final barHeight = plot.height * (value / axisMax);
        final left = groupLeft + seriesIndex * (barWidth + _barGap);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, plot.bottom - barHeight, barWidth, barHeight),
            topLeft: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          Paint()..color = series[seriesIndex].color,
        );
      }
      _drawChartText(
        canvas,
        labels[groupIndex],
        Offset(plot.left + slot * (groupIndex + 0.5), plot.bottom + 8),
        palette.muted,
        11,
        alignCenter: true,
      );
    }
  }

  @override
  bool shouldRepaint(_GroupedBarsPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.series != series ||
      !identical(oldDelegate.palette, palette);
}
