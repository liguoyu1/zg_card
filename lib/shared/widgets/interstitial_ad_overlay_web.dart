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

const String _adOverlayViewType = 'adsterra-interstitial-slot';
// Adsterra Smart Link（zone 30760816）—— 受控打开，嵌入 iframe 展示广告本体。
const String _smartLinkUrl =
    'https://www.effectivecpmnetwork.com/qdzpxwfv03?key=cc95de1535368d9915ee72892dac5164';

bool _adOverlayRegistered = false;

void _ensureAdOverlayRegistered() {
  if (_adOverlayRegistered) return;
  _adOverlayRegistered = true;
  ui_web.platformViewRegistry.registerViewFactory(
    _adOverlayViewType,
    (int viewId) {
      final wrapper = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.overflow = 'hidden'
        ..style.background = '#1A1A2E';
      final frame = web.HTMLIFrameElement()
        ..src = _smartLinkUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allow = 'fullscreen; autoplay; encrypted-media'
        ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-popups allow-forms');
      wrapper.append(frame);
      return wrapper;
    },
  );
}

/// 应用内插屏广告覆盖层。作为 Dialog 内容使用，右上角带关闭按钮。
class InterstitialAdOverlay extends StatelessWidget {
  const InterstitialAdOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    _ensureAdOverlayRegistered();
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Stack(
          children: [
            // 广告区：iframe 内嵌 Adsterra 广告，点击不影响主页面
            const Positioned.fill(child: HtmlElementView(viewType: _adOverlayViewType)),
            // 右上角关闭按钮：始终可见，用户可随时退出
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
