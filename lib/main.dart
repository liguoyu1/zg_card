import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;

import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/audio.dart';
import 'core/theme/app_theme.dart';
import 'data/persistence/save_manager.dart';
import 'domain/services/battle_pass_service.dart';
import 'domain/services/balance_sync_service.dart';
import 'domain/services/purchase_service.dart';
import 'domain/services/quest_manager.dart';
import 'l10n/locale_service.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 使用 path 策略（而非默认 hash 策略），使 /collection 等深层链接
  // 直接被 go_router 识别，否则 /collection 会被当作根路径 / 处理。
  usePathUrlStrategy();

  await SaveManager.init();
  SaveManager.onPlayerDataSaved = (_) => BalanceSyncService.schedule();
  SaveManager.onCollectionSaved = (_) => BalanceSyncService.schedule();
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale_code') ?? 'en';
  await LocaleService.I.init(localeCode: savedLocale);

  // 先 runApp 显示界面，再后台初始化其他
  runApp(const ProviderScope(child: WarringStatesApp()));

  // ── 后台异步初始化（不阻塞首帧） ──
  // 注意：新手 20 张赠送与本周试用已移至 HomeScreen._init，
  // 仅在「注册登录用户」首次进入时触发；游客不送卡、不弹试用。

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
  }
}

class WarringStatesApp extends StatefulWidget {
  const WarringStatesApp({super.key});

  @override
  State<WarringStatesApp> createState() => _WarringStatesAppState();
}

class _WarringStatesAppState extends State<WarringStatesApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocaleService.I.localeVersion.addListener(_onLocaleChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BalanceSyncService.refreshNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocaleService.I.localeVersion.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Locale _locale() {
    final code = LocaleService.I.localeCode;
    if (code == 'zh_TW') return const Locale('zh', 'TW');
    return Locale(code);
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '\u6218\u56FD\u5361\u724C',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoOverscrollBehavior(),
      theme: WarringStatesTheme.dark,
      routerConfig: AppRouter.router(refreshListenable: LocaleService.I.localeVersion),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: _locale(),
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
        Locale('zh', 'TW'),
        Locale('fr', ''),
        Locale('de', ''),
        Locale('ja', ''),
        Locale('ru', ''),
        Locale('es', ''),
        Locale('fil', ''),
        Locale('ms', ''),
        Locale('th', ''),
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
