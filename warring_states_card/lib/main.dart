import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/audio/audio.dart';
import 'domain/services/ad_service.dart';
import 'domain/services/google_ad_service.dart';
import 'domain/services/purchase_service.dart';
import 'domain/services/quest_manager.dart';
import 'domain/services/battle_pass_service.dart';
import 'domain/services/card_pool.dart';
import 'data/persistence/save_manager.dart';
import 'l10n/locale_service.dart';

/// 全局广告服务引用
AdService adService = NoOpAdService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存档目录
  await SaveManager.init();

  // 种子初始卡牌（新玩家自动获得初始卡）
  await CardPool.seedStarterCards();

  // 预初始化音频（非阻塞）
  try {
    await AudioManager.instance.init();
  } catch (_) {}

  // 初始化广告 SDK
  try {
    final ads = GoogleAdService();
    final ok = await ads.initialize();
    if (ok) adService = ads;
  } catch (_) {}

  // 初始化 RevenueCat
  try {
    await PurchaseService.I.initialize();
    await PurchaseService.I.loadProducts();
  } catch (_) {}

  // 初始化 QuestManager + BattlePass
  try {
    await QuestManager.I.init();
    await BattlePassService.I.init();
  } catch (_) {}

  // 初始化国际化
  try {
    await LocaleService.I.init();
  } catch (_) {}

  runApp(const ProviderScope(child: WarringStatesApp()));
}

class WarringStatesApp extends StatelessWidget {
  const WarringStatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '\u6218\u56FD\u5361\u724C',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoOverscrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5E6D3),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
      home: const SplashScreen(),
    );
  }
}

/// 全局禁用 overscroll 拉伸
class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
