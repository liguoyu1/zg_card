// Web 专属实现：通过 dart:js_interop 调用 web/index.html 中暴露的 Adsterra 全局钩子。
// 此文件仅通过 conditional import 在 Web 平台编译，原生平台不会包含。
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'ad_service.dart';

class AdsterraWebAdService implements AdService {
  AdsterraWebAdService();

  @override
  bool get isInitialized => _hasGlobal('__adOpenSmartLink');

  @override
  Future<bool> initialize() async => isInitialized;

  /// 检查全局是否挂载了指定钩子函数。
  bool _hasGlobal(String name) {
    try {
      return globalContext.has(name);
    } catch (_) {
      return false;
    }
  }

  /// 调用全局钩子函数，传递零个参数，返回结果（或 null）。
  JSAny? _callGlobal(String name) {
    final fn = globalContext[name] as JSFunction?;
    if (fn == null) return null;
    return fn.callAsFunction(globalContext);
  }

  @override
  Future<bool> showRewardedAd({required String placementId}) async {
    // 翻倍金币激励位：打开 Adsterra 智能链接（zone 30760816）。
    // 智能链接无标准「观看完成」回调，业界做法为「成功打开即视为已观看」，
    // 并施加最短展示时长保护，避免误触秒关。
    if (!_hasGlobal('__adOpenSmartLink')) return false;
    final opened = (_callGlobal('__adOpenSmartLink') as JSBoolean?)?.toDart ?? false;
    if (!opened) return false;
    // 最短展示时长保护（5 秒），保证广告有效曝光。
    await Future<void>.delayed(const Duration(seconds: 5));
    return true;
  }

  @override
  Future<void> showInterstitialAd({required String placementId}) async {
    // 插屏位：Popunder 全局脚本已移除（避免劫持任何点击跳广告），
    // 此钩子受控打开 Smart Link，仅在游戏内主动调用时触发。
    if (_hasGlobal('__adTriggerInterstitial')) {
      _callGlobal('__adTriggerInterstitial');
    }
    // 给予广告新开页与渲染的缓冲时间。
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> showBannerAd({required String placementId, required bool show}) async {
    // 卡牌页横幅现由内嵌的 HtmlElementView（ad_banner_slot_web.dart）渲染，
    // 不再依赖全局钩子，此方法保留以维持 AdService 接口一致。
    return;
  }

  @override
  void dispose() {}
}

/// 平台工厂函数：Web 下返回 Adsterra 实现。
AdService createPlatformAdService() => AdsterraWebAdService();