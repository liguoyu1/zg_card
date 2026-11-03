/// 广告服务工厂：按运行平台返回对应实现。
///
/// - Web (H5)：Poki Games SDK 实现（commercialBreak / rewardedBreak）。
/// - iOS / Android：不投放广告，返回空实现 [NoOpAdService]。
///
/// 通过条件导入解析 `createPlatformAdService()`：
///   - `dart.library.js_interop`（Web）   → ad_service_web.dart   （Poki）
///   - 其他平台（Android/iOS）               → ad_service_native.dart（NoOp）
library;

import 'ad_service.dart';

import 'ad_service_native.dart'
    if (dart.library.js_interop) 'ad_service_web.dart';

/// 获取当前平台适用的广告服务实例（单例）。
AdService getAdService() => _instance;
final AdService _instance = createPlatformAdService();
