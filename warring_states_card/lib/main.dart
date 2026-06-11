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

/// 全局广告服务引用
AdService adService = NoOpAdService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ProviderScope(child: WarringStatesApp()));
}

class WarringStatesApp extends StatelessWidget {
  const WarringStatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '\u6218\u56FD\u5361\u724C',
      debugShowCheckedModeBanner: false,
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
