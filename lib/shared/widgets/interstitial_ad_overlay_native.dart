// Android：结算插屏 = 全屏 WebView 加载 Adsterra Smart Link（含关闭按钮）。
// iOS：零广告策略，不弹任何内容。
//
// 与 Web 版一致：受控弹出（仅结算时），右上角/遮罩始终可关闭，绝不劫持任意点击。
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Adsterra Smart Link（zone 30760816）—— 整页广告，WebView 内加载。
const String _smartLinkUrl =
    'https://www.effectivecpmnetwork.com/qdzpxwfv03?key=cc95de1535368d9915ee72892dac5164';

class InterstitialAdOverlay extends StatelessWidget {
  const InterstitialAdOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // iOS（及未知非 Android 原生）：零广告。
    if (kIsWeb || !Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    // Android：WebView 加载 Smart Link 广告，带关闭按钮。
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..setBackgroundColor(const Color(0xFF1A1A2E))
                  ..loadRequest(Uri.parse(_smartLinkUrl)),
              ),
            ),
            // 右上角关闭按钮：始终可退出
            Positioned(
              top: 24,
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
