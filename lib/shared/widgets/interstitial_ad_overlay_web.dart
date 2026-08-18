// 应用内插屏广告覆盖层 —— 受控弹出 + 明确的关闭按钮。
//
// 与全局 Popunder/Social Bar 不同，这里绝不在后台劫持任何点击：
// 仅当游戏内（如结算）主动调用时才弹出，且右上角始终提供关闭按钮，
// 用户不点击广告也可随时退出，绝不「点哪里都跳转」。
//
// 平台策略：
//  - Web：HtmlElementView 内嵌 Adsterra 广告（Smart Link zone 30760816），
//    iframe 内点击不影响主游戏页面。
//  - iOS/Android：不弹真实广告，仅显示占位 + 关闭按钮（原生端零广告）。
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

// Adsterra Smart Link（zone 30760816）—— 受控打开，嵌入 iframe 展示广告本体。
const String _smartLinkUrl =
    'https://www.effectivecpmnetwork.com/qdzpxwfv03?key=cc95de1535368d9915ee72892dac5164';

// 每个覆盖层实例注册独立的 viewType，把 DOM 关闭按钮绑定到本实例的 Navigator，
// 避免全局共享回调在多插屏同时弹出时互相覆盖（关闭错弹/悬空引用）。
int _overlayCount = 0;

void _registerOverlay(String viewType, VoidCallback onClose) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final wrapper = web.HTMLDivElement()
        ..style.cssText = 'position:relative;width:100%;height:100%;'
            'overflow:hidden;background:#1A1A2E;';
      final frame = web.HTMLIFrameElement()
        ..src = _smartLinkUrl
        ..style.cssText =
            'position:absolute;inset:0;width:100%;height:100%;border:none;'
        ..allow = 'fullscreen; autoplay; encrypted-media'
        // 不加 allow-same-origin：第三方广告脚本保持独立 origin，避免被攻破后
        // 获得主站同源权限（可读写宿主 DOM/Cookie）。Smart Link 通常无需同源。
        ..setAttribute('sandbox',
            'allow-scripts allow-popups allow-popups-to-escape-sandbox allow-forms');
      // 右上角关闭按钮：DOM 层，永远盖在 iframe 之上，可点。
      final close = web.HTMLDivElement()
        ..textContent = '✕'
        ..style.cssText =
            'position:absolute;top:8px;right:8px;width:40px;height:40px;'
            'border-radius:50%;background:rgba(0,0,0,0.62);color:#ffffff;'
            'font-size:24px;line-height:40px;text-align:center;'
            'cursor:pointer;z-index:99999;user-select:none;';
      close.addEventListener('click', ((web.Event _) {
        onClose();
      }).toJS);
      wrapper.append(frame);
      wrapper.append(close);
      return wrapper;
    },
  );
}

/// 应用内插屏广告覆盖层。作为 Dialog 内容使用，右上角带关闭按钮。
class InterstitialAdOverlay extends StatefulWidget {
  const InterstitialAdOverlay({super.key});

  @override
  State<InterstitialAdOverlay> createState() => _InterstitialAdOverlayState();
}

class _InterstitialAdOverlayState extends State<InterstitialAdOverlay> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    // 每实例注册独立 factory：DOM 关闭按钮点击时只关本 Dialog。
    _viewType = 'adsterra-interstitial-${_overlayCount++}';
    _registerOverlay(_viewType, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
