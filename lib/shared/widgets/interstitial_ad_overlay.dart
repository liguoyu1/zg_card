// 应用内插屏广告覆盖层 —— 条件导入：Web 弹真实 Adsterra 广告（含关闭按钮），
// iOS/Android 原生端为零广告占位。调用方一律弹 Dialog，关闭按钮始终存在。
export 'interstitial_ad_overlay_native.dart'
    if (dart.library.js_interop) 'interstitial_ad_overlay_web.dart';
