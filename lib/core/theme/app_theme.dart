import 'package:flutter/material.dart';

/// 战国风统一设计令牌
class AppTheme {
  AppTheme._();

  // ──────── 底色 ────────
  static const Color bg = Color(0xFF0E0B09); // 漆黑
  static const Color bgDark = Color(0xFF17120F);
  static const Color bgMedium = Color(0xFF221B16); // 面板
  static const Color bgLight = Color(0xFF2F261F); // 抬升面板

  // ──────── 文字 ────────
  static const Color textPrimary = Color(0xFFF1E6D2); // parchment
  static const Color textSecondary = Color(0xFFBFAE93);
  static const Color textMuted = Color(0xFF85776A);
  static const Color goldAccent = Color(0xFFD9A441); // 青铜金
  static const Color goldBright = Color(0xFFF2C46B);

  // ──────── 边框 ────────
  static const Color borderGold = Color(0xFFB98A3E);
  static const Color borderLight = Color(0xFF4A3F33);
  static const Color borderDark = Color(0xFF2A221C);

  // ──────── 功能色 ────────
  static const Color healthRed = Color(0xFFD9483B); // 朱砂
  static const Color armorOrange = Color(0xFFD35400);
  static const Color manaBlue = Color(0xFF3D8FD6);
  static const Color damageOrange = Color(0xFFE67E22);
  static const Color healGreen = Color(0xFF4FB477);

  static const Color cinnabar = Color(0xFFC8372D); // 朱砂主 CTA
  static const Color jade = Color(0xFF5FB3A1);

  // ──────── 动效 ────────
  static const Duration durFast = Duration(milliseconds: 140);
  static const Duration durMed = Duration(milliseconds: 260);
  static const Curve curveOut = Curves.easeOutCubic;

  /// 主按钮金属渐变（青铜）
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFF2C46B), Color(0xFFD9A441), Color(0xFFA9752A)],
  );
  /// 朱砂渐变（战斗/危险主行动）
  static const LinearGradient cinnabarGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFE5594B), Color(0xFFC8372D), Color(0xFF8E2118)],
  );
  /// 面板：上亮下暗的漆面
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF2A221C), Color(0xFF1C1612)],
  );

  // ──────── 旧名别名（向后兼容） ────────
  static const Color parchment = textPrimary;
  static const Color agedWood = bgMedium;
  static const Color cardBack = bgLight;
  static const double spacingXs = spaceXs;
  static const double spacingSm = spaceSm;
  static const double spacingMd = spaceMd;
  static const double spacingLg = spaceLg;
  static const double spacingXl = spaceXl;

  // ──────── 七学派色 ────────
  static const Color bingjia = Color(0xFFC0392B);
  static const Color fajia = Color(0xFF2E86C1);
  static const Color rujia = Color(0xFF27AE60);
  static const Color daojia = Color(0xFF8E44AD);
  static const Color mojia = Color(0xFFD35400);
  static const Color yinyangjia = Color(0xFF1ABC9C);
  static const Color zonghengjia = Color(0xFFF39C12);
  static const Color neutral = Color(0xFF95A5A6);

  // ──────── 稀有度色 ────────
  static const Color rarityCommon = Color(0xFFE8D5B7);
  static const Color rarityRare = Color(0xFF4A9BE0);
  static const Color rarityEpic = Color(0xFFA66BE0);
  static const Color rarityLegendary = Color(0xFFF0A93B);

  // ──────── 文字样式 ────────
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeMd = 14;
  static const double fontSizeLg = 16;
  static const double fontSizeXl = 20;
  static const double fontSizeXxl = 24;
  static const double fontSizeDisplay = 32;

  static const FontWeight weightNormal = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightBlack = FontWeight.w900;

  // ──────── 间距 ────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // ──────── 圆角 ────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // ──────── 字号映射 ────────
  static const String fontFamily = 'NotoSansSC';

  /// 预定义 TextStyle 集合
  static TextStyle get textDisplay => const TextStyle(
    fontSize: fontSizeDisplay,
    fontWeight: weightBold,
    color: textPrimary,
  );

  static TextStyle get textHeadline => const TextStyle(
    fontSize: fontSizeXxl,
    fontWeight: weightBold,
    color: textPrimary,
  );

  static TextStyle get textTitle => const TextStyle(
    fontSize: fontSizeXl,
    fontWeight: weightBold,
    color: textPrimary,
  );

  static TextStyle get textSubtitle => const TextStyle(
    fontSize: fontSizeLg,
    fontWeight: weightMedium,
    color: textPrimary,
  );

  static TextStyle get textBody => const TextStyle(
    fontSize: fontSizeMd,
    fontWeight: weightNormal,
    color: textPrimary,
  );

  static TextStyle get textCaption => const TextStyle(
    fontSize: fontSizeSm,
    fontWeight: weightNormal,
    color: textSecondary,
  );

  static TextStyle get textGold => const TextStyle(
    fontSize: fontSizeLg,
    fontWeight: weightBold,
    color: goldBright,
  );

  // ──────── 装饰器快捷值 ────────
  static BoxDecoration get bgDecoration => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0, -0.9),
      radius: 1.4,
      colors: [Color(0xFF2B2018), bgDark, bg],
      stops: [0, 0.45, 1],
    ),
  );

  static BoxDecoration get boardDecoration => const BoxDecoration(
    gradient: RadialGradient(
      radius: 1.1,
      colors: [Color(0xFF3A2C1F), Color(0xFF221A14), bg],
      stops: [0, 0.55, 1],
    ),
  );

  static BoxDecoration goldBorder() => BoxDecoration(
    border: Border.all(color: borderGold),
    borderRadius: BorderRadius.circular(radiusMd),
  );

  static BoxDecoration panelDecoration() => BoxDecoration(
    gradient: panelGradient,
    border: Border.all(color: borderLight.withAlpha(140)),
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))],
  );

  static BoxDecoration glassDecoration() => BoxDecoration(
    color: bgMedium.withAlpha(120),
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: borderLight.withAlpha(60)),
  );

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withAlpha(80),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static BoxShadow glowShadow(Color color) => BoxShadow(
    color: color.withAlpha(60),
    blurRadius: 12,
    spreadRadius: 2,
  );

  /// 获取学派颜色
  static Color schoolColor(String owner) {
    switch (owner) {
      case 'bingjia': return bingjia;
      case 'fajia': return fajia;
      case 'rujia': return rujia;
      case 'daojia': return daojia;
      case 'mojia': return mojia;
      case 'yinyangjia': return yinyangjia;
      case 'zonghengjia': return zonghengjia;
      default: return neutral;
    }
  }
}

/// 暗色战国主题 ThemeData
class WarringStatesTheme {
  WarringStatesTheme._();

  static final ThemeData dark = _build();

  static ThemeData _build() {
    const r12 = BorderRadius.all(Radius.circular(AppTheme.radiusLg));
    const r10 = BorderRadius.all(Radius.circular(10));
    final pressed = WidgetStateProperty.resolveWith<Color?>(
        (s) => s.contains(WidgetState.pressed) ? Colors.white.withAlpha(24) : null);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.goldAccent,
        onPrimary: Color(0xFF1A1206),
        secondary: AppTheme.cinnabar,
        onSecondary: Colors.white,
        tertiary: AppTheme.jade,
        surface: AppTheme.bgMedium,
        surfaceContainerHighest: AppTheme.bgLight,
        onSurface: AppTheme.textPrimary,
        onSurfaceVariant: AppTheme.textSecondary,
        outline: AppTheme.borderLight,
        error: AppTheme.healthRed,
      ),
      scaffoldBackgroundColor: AppTheme.bg,
      canvasColor: AppTheme.bgDark,

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 1),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: AppTheme.textPrimary, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.45),
        bodySmall: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: 0.5),
        labelSmall: TextStyle(fontSize: 10, color: AppTheme.textMuted),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.bgDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: Color(0x40D9A441))),
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 1.5),
      ),

      cardTheme: const CardThemeData(
        color: AppTheme.bgMedium,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: AppTheme.borderLight)),
      ),

      // 主按钮：青铜金实心
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.goldAccent,
          foregroundColor: const Color(0xFF1A1206),
          disabledBackgroundColor: AppTheme.bgLight,
          disabledForegroundColor: AppTheme.textMuted,
          elevation: 0,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: r12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ).copyWith(overlayColor: pressed),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.cinnabar,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 46),
          shape: const RoundedRectangleBorder(borderRadius: r12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.goldBright,
          side: const BorderSide(color: AppTheme.borderGold),
          minimumSize: const Size(64, 44),
          shape: const RoundedRectangleBorder(borderRadius: r12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.goldBright,
          shape: const RoundedRectangleBorder(borderRadius: r10),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppTheme.textPrimary),
      ),

      // 筛选胶囊：未选中描边、选中金底
      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.bgMedium,
        selectedColor: AppTheme.goldAccent,
        disabledColor: AppTheme.bgDark,
        checkmarkColor: const Color(0xFF1A1206),
        side: const BorderSide(color: AppTheme.borderLight),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Color(0xFF1A1206), fontSize: 13, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        showCheckmark: false,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppTheme.goldBright,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: AppTheme.goldAccent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Color(0x33B98A3E),
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        unselectedLabelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppTheme.bgDark,
        selectedItemColor: AppTheme.goldBright,
        unselectedItemColor: AppTheme.textMuted,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF120E0B),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.goldAccent.withAlpha(46),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 11.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? AppTheme.goldBright : AppTheme.textMuted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? AppTheme.goldBright : AppTheme.textMuted,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF120E0B),
        indicatorColor: AppTheme.goldAccent.withAlpha(46),
        selectedIconTheme: const IconThemeData(color: AppTheme.goldBright),
        unselectedIconTheme: const IconThemeData(color: AppTheme.textMuted),
        selectedLabelTextStyle: const TextStyle(color: AppTheme.goldBright, fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelTextStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTheme.goldAccent,
        linearTrackColor: Color(0xFF2E2620),
        circularTrackColor: Color(0xFF2E2620),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppTheme.goldAccent,
        textColor: AppTheme.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: r12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.bgMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: AppTheme.borderLight)),
        enabledBorder: const OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: AppTheme.borderLight)),
        focusedBorder: const OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: AppTheme.goldAccent, width: 1.5)),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: TextStyle(color: AppTheme.textMuted.withAlpha(180)),
        prefixIconColor: AppTheme.textMuted,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF231C17),
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0x80B98A3E)),
        ),
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        contentTextStyle: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1C1612),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppTheme.borderLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),

      dividerColor: AppTheme.borderLight.withAlpha(110),
      dividerTheme: DividerThemeData(color: AppTheme.borderLight.withAlpha(110), thickness: 1, space: 1),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A221C),
        contentTextStyle: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        actionTextColor: AppTheme.goldBright,
        shape: RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: Color(0x66B98A3E))),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: Color(0xF02A221C), borderRadius: r10),
        textStyle: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppTheme.goldAccent,
        foregroundColor: Color(0xFF1A1206),
        shape: RoundedRectangleBorder(borderRadius: r12),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF231C17),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: AppTheme.borderLight)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTheme.goldBright : AppTheme.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTheme.goldAccent.withAlpha(110) : AppTheme.bgLight),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppTheme.goldAccent.withAlpha(90)),
        radius: const Radius.circular(8),
      ),

      // 页面切换：淡入+轻微上浮（Web 默认是无动画硬切）
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}
