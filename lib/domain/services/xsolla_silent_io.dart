// Xsolla 静默登录非 Web 占位（移动端/桌面无 Xsolla SSO cookie 机制）
Future<String?> xsollaSilentJwt({
  required String projectId,
  required String clientId,
  String redirectUri = '',
}) async {
  return null;
}