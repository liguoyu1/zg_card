// 当前所在 Tab 索引的共享作用域。
//
// ResponsiveShell 用 IndexedStack 同时挂载全部 4 个 Tab，屏内组件（主页公告栏）
// 需要知道自己是否处于当前可见 Tab，只能靠这个作用域下发的索引判断。
library;

import 'package:flutter/widgets.dart';

class TabScope extends InheritedWidget {
  const TabScope({super.key, required this.activeIndex, required super.child});

  /// 当前选中 Tab 索引（0=主页 1=卡牌 2=成就 3=商店）。
  final int activeIndex;

  static int? activeIndexOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabScope>()?.activeIndex;

  @override
  bool updateShouldNotify(TabScope old) => old.activeIndex != activeIndex;
}
