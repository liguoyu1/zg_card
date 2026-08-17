// Android 专属实现：通过 url_launcher 打开 Adsterra 智能链接（翻倍金币）。
//
// 注意：本文件在 Android 与 iOS 下都会被编译（都是原生平台，dart:io 可用），
// 但仅在 Android 运行时由 ad_service_native.dart 实际实例化。iOS 走 NoOpAdService。
library;

import 'package:url_launcher/url_launcher.dart';

import 'ad_service.dart';

/// Adsterra 智能链接（zone 30760816）——「翻倍金币」点击后打开。
const String _smartLinkUrl =
    'https://www.effectivecpmnetwork.com/qdzpxwfv03?key=cc95de1535368d9915ee72892dac5164';

class AdsterraAndroidAdService implements AdService {
  AdsterraAndroidAdService();

  @override
  bool get isInitialized => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> showRewardedAd({required String placementId}) async {
    // 翻倍金币：直接用浏览器/外部打开 Adsterra 智能链接（与 Web 版一致）。
    final uri = Uri.parse(_smartLinkUrl);
    bool opened;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // 外部打开失败时降级为内置浏览器
      try {
        opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) return false;
    // 最短展示时长保护（5 秒），保证广告有效曝光。
    await Future<void>.delayed(const Duration(seconds: 5));
    return true;
  }

  @override
  Future<void> showInterstitialAd({required String placementId}) async {
    // Android 插屏暂时禁用：
    // Adsterra Popunder 通过 WebView 加载没有可靠的完成/关闭回调，
    // 定时自动关闭不可靠，故先不投放插屏广告。
    return;
  }

  @override
  Future<void> showBannerAd({required String placementId, required bool show}) async {
    // Android 横幅暂时不支持（Adsterra 横幅为 Web 广告位，暂无 WebView 承载方案）。
    return;
  }

  @override
  void dispose() {}
}
