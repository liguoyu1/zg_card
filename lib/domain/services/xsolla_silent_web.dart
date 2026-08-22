// Xsolla 静默登录 Web 实现：利用 Xsolla SSO cookie。
// 浏览器已有 login.xsolla.com 登录会话时，GET /jwt/sso 直接返回用户 JWT（无用户交互）。
// 使用 package:web 的 HttpRequest（基于 fetch，wasm 兼容，替代已弃用的 dart:html）。
import 'dart:convert';

import 'package:web/web.dart' as web;

/// 在浏览器当前会话中静默换取 Xsolla 用户 JWT。
/// 返回 null = 无有效 Xsolla 会话（用户未在 Xsolla 登录过 / cookie 过期）。
Future<String?> xsollaSilentJwt({
  required String projectId,
  String redirectUri = '',
}) async {
  try {
    // 对齐 @xsolla/login-sdk checkUserAuthSSO 参数集：
    // hn = ["projectId","fullLocale","callbackUrl","payload","with_logout"]；
    // wn() 将 callbackUrl 映射为 query 参数 login_url
    final params = <String, String>{
      'projectId': projectId,
    };
    if (redirectUri.isNotEmpty) params['login_url'] = redirectUri;
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final url = 'https://login.xsolla.com/api/jwt/sso?$query';
    final req = await web.HttpRequest.request(
      url,
      withCredentials: true,
      requestHeaders: {'Accept': 'application/json'},
    );
    if (req.status == 200) {
      final body = jsonDecode(req.responseText ?? '') as Map<String, dynamic>;
      // 兼容 {token, data:{token}} 结构
      final token = body['token'] as String?;
      if (token != null && token.isNotEmpty) return token;
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        final t2 = data['token'] as String?;
        if (t2 != null && t2.isNotEmpty) return t2;
      }
    }
  } catch (_) {}
  return null;
}