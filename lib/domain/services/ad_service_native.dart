// 原生平台（Android / iOS）实现：Poki SDK 只在 Web 有效，原生端零广告。
//
// 通过 conditional import 在非 Web 平台编译。
library;

import 'ad_service.dart';

/// 平台工厂函数：原生恒为空实现。
AdService createPlatformAdService() => NoOpAdService();
