import 'xsolla_launch_stub.dart'
    if (dart.library.js_interop) 'xsolla_launch_web.dart' as impl;

/// 打开 PayStation：Web 同页跳转（防弹窗拦截），其他平台系统浏览器
Future<bool> launchXsolla(String url) => impl.launchXsolla(url);
