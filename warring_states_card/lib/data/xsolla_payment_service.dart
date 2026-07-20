import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Xsolla 支付服务 — 创建令牌 → 浏览器打开 PayStation → webhook 回调加钻
class XsollaPaymentService {
  XsollaPaymentService._();
  static final XsollaPaymentService _instance = XsollaPaymentService._();
  static XsollaPaymentService get I => _instance;

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
}
