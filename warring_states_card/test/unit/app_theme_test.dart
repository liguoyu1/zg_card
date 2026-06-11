import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('Core colors are non-null', () {
      expect(AppTheme.bgDark, isNot(null));
      expect(AppTheme.parchment, isNot(null));
      expect(AppTheme.goldAccent, isNot(null));
      expect(AppTheme.agedWood, isNot(null));
      expect(AppTheme.cardBack, isNot(null));
    });

    test('School colors return correct values', () {
      expect(AppTheme.schoolColor('bingjia'), equals(AppTheme.bingjia));
      expect(AppTheme.schoolColor('fajia'), equals(AppTheme.fajia));
      expect(AppTheme.schoolColor('rujia'), equals(AppTheme.rujia));
      expect(AppTheme.schoolColor('daojia'), equals(AppTheme.daojia));
      expect(AppTheme.schoolColor('mojia'), equals(AppTheme.mojia));
      expect(AppTheme.schoolColor('yinyangjia'), equals(AppTheme.yinyangjia));
      expect(AppTheme.schoolColor('zonghengjia'), equals(AppTheme.zonghengjia));
    });

    test('Unknown school returns neutral', () {
      expect(AppTheme.schoolColor('unknown'), equals(AppTheme.neutral));
    });

    test('All spacing values are positive', () {
      expect(AppTheme.spacingXs, greaterThan(0));
      expect(AppTheme.spacingSm, greaterThan(0));
      expect(AppTheme.spacingMd, greaterThan(0));
      expect(AppTheme.spacingLg, greaterThan(0));
      expect(AppTheme.spacingXl, greaterThan(0));
    });

    test('Rarity colors are unique', () {
      expect(AppTheme.rarityCommon, isNot(equals(AppTheme.rarityLegendary)));
    });
  });
}
