import 'package:flutter/material.dart';

/// 战国风统一主题色
class AppTheme {
  AppTheme._();

  // ──────── 底色 ────────
  static const Color bgDark = Color(0xFF2C1810);
  static const Color agedWood = Color(0xFF3D2B1F);
  static const Color cardBack = Color(0xFF4A3728);

  // ──────── 文字/装饰 ────────
  static const Color parchment = Color(0xFFE8D5B7);
  static const Color goldAccent = Color(0xFFB8860B);

  // ──────── 七学派色 ────────
  static const Color bingjia = Color(0xFFC0392B);
  static const Color fajia = Color(0xFF2E86C1);
  static const Color rujia = Color(0xFF27AE60);
  static const Color daojia = Color(0xFF8E44AD);
  static const Color mojia = Color(0xFFD35400);
  static const Color yinyangjia = Color(0xFF1ABC9C);
  static const Color zonghengjia = Color(0xFFF39C12);
  static const Color neutral = Colors.grey;

  // ──────── 稀有度色 ────────
  static const Color rarityCommon = Color(0xFFE8D5B7);
  static const Color rarityRare = Color(0xFF4A7C59);
  static const Color rarityEpic = Color(0xFF8B4513);
  static const Color rarityLegendary = Color(0xFFC59538);

  // ──────── 字体 ────────
  static const String fontFamily = 'NotoSansSC';

  // ──────── 间距 ────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

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
