import 'package:web/web.dart' as web;

/// Web：同标签页导航，不清空登录页状态
void assignPage(String url) {
  web.window.location.assign(url);
}