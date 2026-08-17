// 原生（Android/iOS）占位：Adsterra 为 Web 广告位，原生端不渲染横幅。
library;

import 'package:flutter/widgets.dart';

/// 卡牌页内嵌横幅插槽（原生版，空实现占位）。
class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}