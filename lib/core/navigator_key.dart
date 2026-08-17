/// 全局 NavigatorKey —— 供无 BuildContext 的模块（如广告服务）推送覆盖层路由。
///
/// 仅在需要「脱离当前 Widget 树弹出全屏广告」的场景使用（当前为 Android 插屏）。
library;

import 'package:flutter/material.dart';

/// 根路由导航 Key。在 [WarringStatesApp] 的 MaterialApp.router 上注册。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
