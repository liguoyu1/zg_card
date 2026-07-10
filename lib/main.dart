import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/audio.dart';
import 'core/theme/app_theme.dart';
import 'data/persistence/save_manager.dart';
import 'domain/services/ad_service.dart';
import 'domain/services/battle_pass_service.dart';
import 'domain/services/card_pool.dart';
import 'domain/services/google_ad_service.dart';
import 'domain/services/pangle_ad_service.dart';
import 'domain/services/purchase_service.dart';
import 'domain/services/quest_manager.dart';
import 'l10n/locale_service.dart';
import 'routing/app_router.dart';

/// 全局广告服务引用
AdService adService = NoOpAdService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅初始化必要的持久化层（毫秒级），其余后台异步加载
  await SaveManager.init();
  await LocaleService.I.init();

  // 先 runApp 显示界面，再后台初始化其他
  runApp(const ProviderScope(child: WarringStatesApp()));

  // ── 后台异步初始化（不阻塞首帧） ──
  CardPool.seedStarterCards();

  if (!kIsWeb) {
    try {
      AudioManager.instance.init();
    } catch (_) {}
    PurchaseService.I.initialize().then((_) {
      PurchaseService.I.loadProducts();
    }).catchError((_) {});
    try {
      QuestManager.I.init();
    } catch (_) {}
    try {
      BattlePassService.I.init();
    } catch (_) {}
    _initAds();
  }
}

bool _isChina() => Platform.localeName.startsWith('zh_');

Future<void> _initAds() async {
  try {
    late final AdService ads;
    if (_isChina()) {
      ads = PangleAdService();
    } else {
      ads = GoogleAdService();
    }
    final ok = await ads.initialize();
    if (ok) adService = ads;
  } catch (_) {}
}

class WarringStatesApp extends StatelessWidget {
  const WarringStatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '\u6218\u56FD\u5361\u724C',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoOverscrollBehavior(),
      theme: WarringStatesTheme.dark,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
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