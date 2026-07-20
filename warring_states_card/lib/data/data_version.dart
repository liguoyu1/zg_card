/// 全局数据版本号 — 当玩家数据（金币/卡牌/英雄/收藏）变化时递增。
/// 各页面监听此 notifier 实现跨 tab 实时同步。
library;
import 'package:flutter/foundation.dart';

final dataVersionNotifier = ValueNotifier(0);

void bumpDataVersion() {
  dataVersionNotifier.value++;
}
