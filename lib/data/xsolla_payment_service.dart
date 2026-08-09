import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'xsolla_return.dart';

/// Xsolla 支付服务 — 创建令牌 → 浏览器打开 PayStation → webhook 回调加钻
class XsollaPaymentService {
  XsollaPaymentService._();
  static final XsollaPaymentService _instance = XsollaPaymentService._();
  static XsollaPaymentService get I => _instance;

  /// web 从支付页跳回后待展示的支付状态（successful/canceled/...）
  static String? pendingReturnStatus;

  static const String _baseUrl =
      'https://app-server-production-39d1.up.railway.app';

  /// 创建支付令牌并打开 PayStation
  /// [playerId] / [token] = 用户身份 & JWT
  /// [sku] = gem_60 / gem_300 / ...
  /// 返回 true 表示支付页面已打开
  Future<bool> purchase(String playerId, String token, {required String sku}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/payment/create-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'odID': playerId, 'sku': sku}),
      );

      if (resp.statusCode != 200) return false;

      final data = jsonDecode(resp.body);
      final url = data['url'] as String?;
      if (url == null) return false;

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 取走支付返回状态（仅 web；取出即清除地址栏参数）
  static String? takeReturnStatus() {
    if (pendingReturnStatus != null) {
      final s = pendingReturnStatus;
      pendingReturnStatus = null;
      return s;
    }
    return consumeXsollaReturnStatus();
  }

  /// 读取支付返回状态（不清除，供首页转发给商店页）
  static String? consumeReturnStatus() => consumeXsollaReturnStatus();
}
