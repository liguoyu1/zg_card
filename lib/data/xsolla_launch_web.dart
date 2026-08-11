import 'dart:html' as html;

/// Web 端：同页跳转 PayStation（避免弹窗拦截；支付完成后 Xsolla 跳回游戏）
Future<bool> launchXsolla(String url) async {
  html.window.location.assign(url);
  return true;
}
