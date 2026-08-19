// 应用入口冒烟测试：直接渲染 WarringStatesApp（MaterialApp.router → HomeScreen）
// 关键点：
//  - main.dart 里 PurchaseService.I.initialize() 会触碰真实 IAP 平台渠道，测试前需替换为假平台。
//  - LocaleService.init 使用 rootBundle.loadString（真实异步 IO），须经 tester.runAsync。
//  - HomeScreen 含持续动画，用有限 pump，不用 pumpAndSettle。
//  - debugDefaultTargetPlatformOverride 是全局 debug 变量，测试体内部 finally 复位。
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import 'package:warring_states_card/main.dart';

/// 假 IAP 平台，避免应用启动时连接真实商店渠道。
class _FakeInAppPurchasePlatform extends InAppPurchasePlatform {
  @override
  Future<bool> isAvailable() async => false;
}

void main() {
  testWidgets('App 启动渲染 HomeScreen（中文）', (tester) async {
    SharedPreferences.setMockInitialValues({'firstRun': 'false', 'ownedCards': '[]'});
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchasePlatform.instance = _FakeInAppPurchasePlatform();
    try {
      await tester.runAsync(() => LocaleService.I.init(localeCode: 'zh'));

      await tester.pumpWidget(const ProviderScope(child: WarringStatesApp()));
      // 让路由跳转 + HomeScreen 首帧渲染
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(WarringStatesApp), findsOneWidget);
      expect(find.text(LocaleService.I.t('home.btn_battle')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}