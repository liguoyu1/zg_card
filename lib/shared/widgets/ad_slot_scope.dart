// 广告加载可见性判定 —— 纯加载层逻辑，不影响任何页面布局。
//
// 问题根因（广告本身）：ResponsiveShell 用 IndexedStack 同时挂载全部 4 个 Tab，
// 每个 Tab 内的 AdBannerSlot 都注入同一个 Adsterra 脚本并创建相同 id 的容器，
// 相互争抢同 zone + 离屏/隐藏容器不渲染，导致只有首页能加载出广告。
// 修复：通过 AdSlotScope 让同一时刻只有"当前可见页"的插槽真正挂载广告 DOM，
// 其余插槽渲染等尺寸占位。页面各自原有广告位位置保持不变。
import 'package:flutter/widgets.dart';

/// 广告可见性作用域，由 ResponsiveShell 注入，AdBannerSlot 据此判断自己是否是
/// 当前应挂载真实广告的唯一插槽。本类只影响广告何时挂载，不改变布局树结构。
class AdSlotScope extends InheritedWidget {
  const AdSlotScope({
    super.key,
    required this.isSubRoute,
    required this.activeIndex,
    required this.canShow,
    this.tabIndex,
    required super.child,
  });

  /// 是否处于子路由页（非 4 大 Tab）。
  final bool isSubRoute;
  /// 当前选中 Tab 索引（仅 Tab 页有意义）。
  final int activeIndex;
  /// 本插槽所属 Tab 索引（子路由页为 null）。
  final int? tabIndex;
  /// 主开关：false 时任何情况下都不显示广告。
  final bool canShow;

  static AdSlotScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdSlotScope>();

  @override
  bool updateShouldNotify(AdSlotScope old) =>
      old.activeIndex != activeIndex ||
      old.isSubRoute != isSubRoute ||
      old.tabIndex != tabIndex ||
      old.canShow != canShow;
}

/// 计算给定插槽是否应加载广告。未处于作用域内时默认显示（兼容直接使用场景）。
bool adSlotVisible(BuildContext context) {
  final scope = AdSlotScope.maybeOf(context);
  if (scope == null) return true;
  if (!scope.canShow) return false;
  // 被上级 opaque 路由覆盖时 TickerMode 被关闭 => 被遮挡页面的广告不挂载。
  if (!TickerMode.valuesOf(context).enabled) return false;
  if (scope.isSubRoute) return true;
  return scope.tabIndex == scope.activeIndex;
}
