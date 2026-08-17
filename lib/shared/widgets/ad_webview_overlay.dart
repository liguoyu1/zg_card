import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

/// Android 插屏广告覆盖层 —— 全屏加载 Adsterra Popunder HTML。
///
/// 仅在 Android 平台由 AdService 推送此路由；iOS/Web 不引用此文件。
class AdWebViewOverlay extends StatefulWidget {
  const AdWebViewOverlay({super.key, required this.htmlAsset});

  /// assets/ad 下的 Popunder HTML 资源路径（如 'assets/ad/adsterra_popunder.html'）
  final String htmlAsset;

  @override
  State<AdWebViewOverlay> createState() => _AdWebViewOverlayState();
}

class _AdWebViewOverlayState extends State<AdWebViewOverlay> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      final html = await rootBundle.loadString(widget.htmlAsset);
      if (!mounted) return;
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF2C1810))
        ..loadHtmlString(html);
      setState(() => _controller = controller);
    } catch (_) {
      // 资源加载失败时保持黑底提示，用户可关闭
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1810),
      body: SafeArea(
        child: Stack(
          children: [
            if (_controller != null) WebViewWidget(controller: _controller!),
            // 关闭按钮，悬浮在右上角
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}