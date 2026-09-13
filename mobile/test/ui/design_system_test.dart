import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/ui/theme.dart';
import 'package:xsmb_manager/src/ui/widgets.dart';

/// Khoá bảng màu và các component của giao diện mới (bám token của trang tham
/// chiếu **xosothongminh.tech**): ai đổi màu/bo góc vô ý sẽ fail ngay tại đây.
Widget host(AppPalette palette, Widget child) => PaletteScope(
  palette: palette,
  child: MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  test('bảng màu dùng đúng token của trang tham chiếu', () {
    expect(AppPalette.light.bg, const Color(0xFFF8FAFC)); // slate-50
    expect(AppPalette.light.line, const Color(0xFFE2E8F0)); // slate-200
    expect(AppPalette.light.gold, const Color(0xFFEA580C)); // orange-600
    expect(AppPalette.light.goldBright, const Color(0xFFC2410C)); // orange-700
    expect(AppPalette.light.goldSoft, const Color(0xFFFFEDD5)); // orange-100
    expect(AppPalette.light.amber, const Color(0xFFF6D35A));
    expect(AppPalette.light.warm, const Color(0xFFFB923C));
    expect(AppPalette.light.navy, const Color(0xFF031027)); // navy-950
    expect(AppPalette.light.onNavy, const Color(0xFFF8FAFC));

    expect(AppPalette.dark.bg, const Color(0xFF031027));
    expect(AppPalette.dark.gold, const Color(0xFFFB923C)); // orange-400

    // Thẻ "vuông" hơn bản cũ (16px) nhưng vẫn đủ mềm cho màn hình cảm ứng.
    expect(AppPalette.radius, lessThanOrEqualTo(12));
    expect(AppPalette.radiusSm, lessThan(AppPalette.radius));
    expect(AppPalette.contentMaxWidth, greaterThan(0));
  });

  test('theme dựng từ bảng màu dùng đúng nền, màu nhấn và đường kẻ', () {
    final theme = buildAppTheme(AppPalette.light);
    expect(theme.scaffoldBackgroundColor, AppPalette.light.bg);
    expect(theme.colorScheme.primary, AppPalette.light.gold);
    expect(theme.colorScheme.onPrimary, AppPalette.light.onGold);
    expect(theme.dividerTheme.color, AppPalette.light.line);
  });

  testWidgets('HeroBand hiện nhãn, tiêu đề, hành động và thẻ phụ', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppPalette.light,
        HeroBand(
          eyebrow: 'Dữ liệu & thống kê',
          title: 'Hôm nay số nào đáng chú ý nhất?',
          description: 'Thống kê từ dữ liệu lịch sử 90 kỳ gần nhất.',
          actions: <Widget>[
            AppButton(label: 'Xem bộ tính số', onPressed: () {}),
          ],
          aside: const StatTile(
            label: 'Kỳ gần nhất',
            value: '12/09/2026',
            note: 'Miền Bắc',
            onNavy: true,
          ),
        ),
      ),
    );

    expect(find.text('DỮ LIỆU & THỐNG KÊ'), findsOneWidget);
    expect(find.text('Hôm nay số nào đáng chú ý nhất?'), findsOneWidget);
    expect(find.text('Xem bộ tính số'), findsOneWidget);
    expect(find.text('12/09/2026'), findsOneWidget);
    expect(find.text('Miền Bắc'), findsOneWidget);
  });

  testWidgets('SignalCard hiện số, nhãn và điểm dữ liệu trên thanh 0–100', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppPalette.light,
        const SignalCard(
          number: '04',
          tag: 'Số nóng',
          score: 87,
          note: '51 lần trong 30 kỳ · 1 kỳ chưa xuất hiện',
        ),
      ),
    );

    expect(find.text('04'), findsOneWidget);
    expect(find.text('Số nóng'), findsOneWidget);
    expect(find.text('Điểm dữ liệu'), findsOneWidget);
    expect(find.text('87/100'), findsOneWidget);
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      closeTo(0.87, 0.0001),
    );
  });

  testWidgets('ScoreBar kẹp điểm ngoài khoảng 0–100', (tester) async {
    await tester.pumpWidget(host(AppPalette.light, const ScoreBar(score: 240)));
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      1.0,
    );

    await tester.pumpWidget(host(AppPalette.light, const ScoreBar(score: -5)));
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      0.0,
    );
  });

  testWidgets('StatusChip và NumberPill hiện nhãn dạng viên tròn', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppPalette.light,
        const Column(
          children: <Widget>[
            StatusChip(label: 'Số nóng', tone: PillTone.gold),
            NumberPill(number: '04', tone: PillTone.hot, width: 48),
          ],
        ),
      ),
    );

    expect(find.text('Số nóng'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
  });
}
