// Web 专属：卡牌页内嵌 Adsterra 原生横幅（zone 30760823）。
//
// 通过 HtmlElementView 将 Adsterra 的 DOM 广告容器嵌入 Flutter 卡牌列表末尾，
// 使其随页面滚动，比例由外层 AspectRatio(3:1) 控制。
library;

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

const String _adBannerViewType = 'adsterra-banner-slot';

// Adsterra 原生横幅（zone 30760823）的注入脚本与容器 id。
const String _nativeBannerScript =
    'https://pl30861322.effectivecpmnetwork.com/2cbc3e5f4588b232019879b4813fbe28/invoke.js';
const String _nativeBannerContainerId = 'container-2cbc3e5f4588b232019879b4813fbe28';

bool _registered = false;

void _ensureRegistered() {
  if (_registered) return;
  _registered = true;
  // 每次创建视图时返回一个新的 div，并把 Adsterra 原生横幅脚本注入其中。
  ui_web.platformViewRegistry.registerViewFactory(
    _adBannerViewType,
    (int viewId) {
      final wrapper = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.background = 'rgba(0,0,0,0.35)'
        ..style.overflow = 'hidden';
      final container = web.HTMLDivElement()
        ..id = _nativeBannerContainerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.margin = '0 auto';
      wrapper.append(container);
      // 注入 Adsterra 原生横幅脚本（每次新视图都会重新拉取并渲染）。
      final script = web.HTMLScriptElement()
        ..async = true
        ..type = 'text/javascript'
        ..src = _nativeBannerScript;
      wrapper.append(script);
      return wrapper;
    },
  );
}

/// 卡牌页内嵌横幅插槽（Web 版，真实广告）。
class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    _ensureRegistered();
    return const HtmlElementView(viewType: _adBannerViewType);
  }
}