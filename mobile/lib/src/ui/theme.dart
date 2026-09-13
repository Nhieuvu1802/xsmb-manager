import 'package:flutter/material.dart';

/// Bảng màu lấy từ trang tham chiếu **xosothongminh.tech** (Tailwind v4):
/// nền `slate-50`, thẻ trắng viền `slate-200`, chữ `slate-900/600`, màu thương
/// hiệu là **cam** (`orange-600 #EA580C`), dải hero `navy-950 #031027` và thang
/// nhiệt `#F6D35A → #FB923C`. Dark mode bám theo biến thể `dark:` của site
/// (`bg-navy-950`, `border-slate-800`, chữ `orange-200`).
@immutable
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.bgSoft,
    required this.panel,
    required this.panelRaised,
    required this.panelSoft,
    required this.line,
    required this.lineSoft,
    required this.text,
    required this.muted,
    required this.mutedBright,
    required this.gold,
    required this.goldBright,
    required this.goldSoft,
    required this.onGold,
    required this.coral,
    required this.coralSoft,
    required this.blue,
    required this.blueSoft,
    required this.green,
    required this.sidebar,
    required this.navy,
    required this.navySoft,
    required this.navyLine,
    required this.navyPanel,
    required this.onNavy,
    required this.onNavySoft,
    required this.amber,
    required this.warm,
    required this.isDark,
  });

  final Color bg;
  final Color bgSoft;
  final Color panel;
  final Color panelRaised;
  final Color panelSoft;
  final Color line;
  final Color lineSoft;
  final Color text;
  final Color muted;
  final Color mutedBright;
  final Color gold;
  final Color goldBright;
  final Color goldSoft;

  /// Chữ trên nền [gold] — site dùng `bg-orange-600 text-white`.
  final Color onGold;

  final Color coral;
  final Color coralSoft;
  final Color blue;
  final Color blueSoft;
  final Color green;
  final Color sidebar;

  /// Dải hero tối kiểu site (`bg-navy-950` + gradient `#07152E → #0B224A`).
  final Color navy;
  final Color navySoft;
  final Color navyLine;

  /// Thẻ mờ trên nền hero (`bg-white/10`).
  final Color navyPanel;
  final Color onNavy;
  final Color onNavySoft;

  /// Thang nhiệt cho bản đồ 00–99 (`#F6D35A` nóng, `#FB923C` ấm).
  final Color amber;
  final Color warm;

  final bool isDark;

  /// Bo góc thẻ: site dùng `rounded-lg` (8px) và `rounded-md` (6px); app giữ
  /// 12/8 cho cân đối màn hình cảm ứng nhưng vẫn "vuông" hơn bản cũ (16px).
  static const double radius = 12;
  static const double radiusSm = 8;
  static const double radiusPill = 999;
  static const double sidebarWidth = 244;

  /// Bề rộng tối đa của vùng nội dung (`page-shell` của site).
  static const double contentMaxWidth = 1180;

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF031027),
    bgSoft: Color(0xFF07152E),
    panel: Color(0xFF0A1D38),
    panelRaised: Color(0xFF0E2445),
    panelSoft: Color(0xFF0B2248),
    line: Color(0xFF1E293B),
    lineSoft: Color(0x2E94A3B8),
    text: Color(0xFFF8FAFC),
    muted: Color(0xFF94A3B8),
    mutedBright: Color(0xFFCBD5E1),
    gold: Color(0xFFFB923C),
    goldBright: Color(0xFFFED7AA),
    goldSoft: Color(0x24FB923C),
    onGold: Color(0xFF1B1204),
    coral: Color(0xFFFB7185),
    coralSoft: Color(0x24FB7185),
    blue: Color(0xFF93C5FD),
    blueSoft: Color(0x2493C5FD),
    green: Color(0xFF34D399),
    sidebar: Color(0xFF07152E),
    navy: Color(0xFF031027),
    navySoft: Color(0xFF0B2248),
    navyLine: Color(0x26FFFFFF),
    navyPanel: Color(0x1AFFFFFF),
    onNavy: Color(0xFFF8FAFC),
    onNavySoft: Color(0xFFFED7AA),
    amber: Color(0xFFF6D35A),
    warm: Color(0xFFFB923C),
    isDark: true,
  );

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF8FAFC),
    bgSoft: Color(0xFFF1F5F9),
    panel: Color(0xFFFFFFFF),
    panelRaised: Color(0xFFFFFFFF),
    panelSoft: Color(0xFFF8FAFC),
    line: Color(0xFFE2E8F0),
    lineSoft: Color(0xFFEEF2F7),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    mutedBright: Color(0xFF475569),
    gold: Color(0xFFEA580C),
    goldBright: Color(0xFFC2410C),
    goldSoft: Color(0xFFFFEDD5),
    onGold: Color(0xFFFFFFFF),
    coral: Color(0xFFE11D48),
    coralSoft: Color(0xFFFFE4E6),
    blue: Color(0xFF1D4ED8),
    blueSoft: Color(0xFFE0E7FF),
    green: Color(0xFF059669),
    sidebar: Color(0xFFFFFFFF),
    navy: Color(0xFF031027),
    navySoft: Color(0xFF0B224A),
    navyLine: Color(0x26FFFFFF),
    navyPanel: Color(0x1AFFFFFF),
    onNavy: Color(0xFFF8FAFC),
    onNavySoft: Color(0xFFFDBA74),
    amber: Color(0xFFF6D35A),
    warm: Color(0xFFFB923C),
    isDark: false,
  );
}

/// Cung cấp bảng màu cho toàn bộ cây widget (thay cho `data-theme` của CSS).
class PaletteScope extends InheritedWidget {
  const PaletteScope({required this.palette, required super.child, super.key});

  final AppPalette palette;

  static AppPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaletteScope>()?.palette ??
      AppPalette.dark;

  @override
  bool updateShouldNotify(PaletteScope oldWidget) =>
      !identical(oldWidget.palette, palette);
}

ThemeData buildAppTheme(AppPalette palette) {
  final base = palette.isDark ? ThemeData.dark() : ThemeData.light();
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.gold,
        brightness: palette.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface: palette.panel,
        primary: palette.gold,
        onPrimary: palette.onGold,
        secondary: palette.coral,
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    dividerColor: palette.line,
    dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
    splashColor: palette.goldSoft,
    highlightColor: palette.goldSoft,
    textTheme: base.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
    cardTheme: CardThemeData(
      color: palette.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radius),
        side: BorderSide(color: palette.line),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.panel,
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: palette.line)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.panelRaised,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        side: BorderSide(color: palette.line),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.panel,
      selectedItemColor: palette.gold,
      unselectedItemColor: palette.muted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.gold,
      inactiveTrackColor: palette.goldSoft,
      thumbColor: palette.gold,
      overlayColor: palette.goldSoft,
      valueIndicatorColor: palette.gold,
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.gold,
      linearTrackColor: palette.goldSoft,
      circularTrackColor: palette.goldSoft,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.onGold
            : palette.panel,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? palette.gold : palette.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.panelRaised),
        side: WidgetStatePropertyAll(BorderSide(color: palette.line)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.text,
      contentTextStyle: TextStyle(
        color: palette.panel,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.panel,
      labelStyle: TextStyle(color: palette.muted),
      hintStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusSm + 2),
        borderSide: BorderSide(color: palette.gold, width: 1.5),
      ),
    ),
  );
}
