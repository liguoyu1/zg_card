import 'package:flutter/material.dart';

/// 战国风统一设计令牌
class AppTheme {
  AppTheme._();

  // ──────── 底色 ────────
  static const Color bg = Color(0xFF1A0F0A);
  static const Color bgDark = Color(0xFF2C1810);
  static const Color bgMedium = Color(0xFF3D2B1F);
  static const Color bgLight = Color(0xFF4A3728);

  // ──────── 文字 ────────
  static const Color textPrimary = Color(0xFFE8D5B7); // parchment
  static const Color textSecondary = Color(0xFFC4A882);
  static const Color textMuted = Color(0xFF8B7355);
  static const Color goldAccent = Color(0xFFB8860B);
  static const Color goldBright = Color(0xFFD4A017);

  // ──────── 边框 ────────
  static const Color borderGold = Color(0xFFB8860B);
  static const Color borderLight = Color(0xFF6B5B3E);
  static const Color borderDark = Color(0xFF3D2B1F);

  // ──────── 功能色 ────────
  static const Color healthRed = Color(0xFFC0392B);
  static const Color armorOrange = Color(0xFFD35400);
  static const Color manaBlue = Color(0xFF2E86C1);
  static const Color damageOrange = Color(0xFFE67E22);
  static const Color healGreen = Color(0xFF27AE60);

  // ──────── 旧名别名（向后兼容） ────────
  static const Color parchment = textPrimary;
  static Color agedWood = bgMedium;
  static Color cardBack = bgLight;
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
  static const Color rarityRare = Color(0xFF4A7C59);
  static const Color rarityEpic = Color(0xFF8B4513);
  static const Color rarityLegendary = Color(0xFFC59538);

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
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgMedium, bgDark, bg],
    ),
  );

  static BoxDecoration get boardDecoration => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [bgMedium, bgDark, bg],
    ),
  );

  static BoxDecoration goldBorder() => BoxDecoration(
    border: Border.all(color: borderGold, width: 1),
    borderRadius: BorderRadius.circular(radiusMd),
  );

  static BoxDecoration panelDecoration() => BoxDecoration(
    color: bgMedium.withAlpha(180),
    border: Border.all(color: borderLight.withAlpha(100), width: 1),
    borderRadius: BorderRadius.circular(radiusMd),
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

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // 颜色方案
    colorScheme: const ColorScheme.dark(
      primary: AppTheme.goldAccent,
      secondary: AppTheme.textSecondary,
      surface: AppTheme.bgMedium,
      error: AppTheme.healthRed,
      onPrimary: AppTheme.bg,
      onSecondary: AppTheme.bg,
      onSurface: AppTheme.textPrimary,
    ),

    // 全局背景
    scaffoldBackgroundColor: AppTheme.bg,

    // 文本主题
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      labelSmall: TextStyle(fontSize: 10, color: AppTheme.textMuted),
    ),

    // AppBar 风格
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.bgDark,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    ),

    // 卡片
    cardTheme: CardThemeData(
      color: AppTheme.bgMedium,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderLight, width: 0.5),
      ),
    ),

    // 按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.bgLight,
        foregroundColor: AppTheme.textPrimary,
        disabledBackgroundColor: AppTheme.bgLight.withAlpha(100),
        disabledForegroundColor: AppTheme.textMuted,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: const BorderSide(color: AppTheme.borderLight, width: 1),
        ),
        textStyle: const TextStyle(
          fontSize: AppTheme.fontSizeMd,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // 图标按钮
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
      ),
    ),

    // 底部导航
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppTheme.bgDark,
      selectedItemColor: AppTheme.goldAccent,
      unselectedItemColor: AppTheme.textMuted,
      elevation: 4,
    ),

    // 输入框
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.bgMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.borderLight.withAlpha(100)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      hintStyle: TextStyle(color: AppTheme.textMuted.withAlpha(150)),
    ),

    // 对话
    dialogTheme: DialogThemeData(
      backgroundColor: AppTheme.bgMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
    ),

    // 分割线
    dividerColor: AppTheme.borderLight.withAlpha(80),
    dividerTheme: DividerThemeData(
      color: AppTheme.borderLight.withAlpha(80),
      thickness: 1,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTheme.bgMedium,
      contentTextStyle: const TextStyle(color: AppTheme.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // 浮动按钮
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppTheme.goldAccent,
      foregroundColor: AppTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),

    // PopupMenu
    popupMenuTheme: PopupMenuThemeData(
      color: AppTheme.bgMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
    ),
  );
}
