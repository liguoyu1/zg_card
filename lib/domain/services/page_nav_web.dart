import 'dart:html' as html;

/// Web：同标签页导航，不清空登录页状态
void assignPage(String url) {
  html.window.location.assign(url);
}