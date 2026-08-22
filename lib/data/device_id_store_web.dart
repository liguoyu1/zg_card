import 'package:web/web.dart' as web;

/// Web 端设备ID存储：用 cookie（而非 localStorage）。
/// 隐私/无痕模式下 localStorage 被浏览器拒绝，导致每次刷新都生成新ID；
/// cookie 在无痕模式下同一标签会话内仍会保留，刷新不变。
Future<String?> readStoredDeviceId() async {
  final cookies = web.window.document.cookie;
  if (cookies.isEmpty) return null;
  for (final part in cookies.split(';')) {
    final kv = part.trim();
    if (kv.startsWith('zg_dev_id=')) return kv.substring('zg_dev_id='.length);
  }
  return null;
}

Future<void> writeStoredDeviceId(String id) async {
  // session cookie（不设 Expires/Max-Age），path=/ 全站生效
  web.window.document.cookie = 'zg_dev_id=$id; path=/';
}
