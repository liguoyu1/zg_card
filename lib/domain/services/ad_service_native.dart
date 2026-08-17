// 原生平台（Android / iOS）默认实现。
//
// 通过 conditional import 在非 Web 平台编译。
// - Android：接入 Adsterra（智能链接 + WebView 插屏）。
// - iOS：不投放广告，使用 NoOpAdService（零广告）。
library;

import 'dart:io';

import 'ad_service.dart';
import 'ad_service_android.dart';

/// 平台工厂函数：原生下按系统分发。
AdService createPlatformAdService() {
  if (Platform.isAndroid) {
    return AdsterraAndroidAdService();
  }
  // iOS 及未知平台：不接广告。
  return NoOpAdService();
}
