/// 广告服务工厂：按运行平台返回对应实现。
///
/// - Web (H5)：[AdService] 的 Adsterra Web 实现（智能链接 / Popunder / 原生横幅）。
/// - Android：Adsterra 实现（url_launcher 打开智能链接 + WebView 全屏插屏）。
/// - iOS：不投放广告，返回空实现 [NoOpAdService]。
///
/// 通过条件导入解析 `createPlatformAdService()`：
///   - `dart.library.js_interop`（Web）   → ad_service_web.dart   （Adsterra）
///   - 其他平台（Android/iOS）               → ad_service_native.dart（Android=Adsterra / iOS=NoOp）
library;

import 'ad_service.dart';

import 'ad_service_native.dart'
    if (dart.library.js_interop) 'ad_service_web.dart';

/// 获取当前平台适用的广告服务实例（单例）。
AdService getAdService() => _instance;
final AdService _instance = createPlatformAdService();
