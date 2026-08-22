import 'package:web/web.dart' as web;

/// Web 端：读取 Xsolla return_url 自动追加的 status 参数，并立刻从地址栏清除
String? consumeXsollaReturnStatus() {
  final uri = Uri.base;
  final status = uri.queryParameters['status'];
  if (status == null) return null;
  web.window.history.replaceState(null, uri.replace(queryParameters: {}).toString());
  return status;
}