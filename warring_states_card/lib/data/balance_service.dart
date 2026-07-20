import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 联机对战余额服务 — 调用后端 API
class BalanceService {
  static const String _baseUrl =
      'https://app-server-production-39d1.up.railway.app';

  /// 从服务端获取余额
  static Future<({int gems, int gold, int balanceVersion})?> getBalance(
      String odID) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/balance/get/$odID');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body);
      return (
        gems: body['gems'] as int,
        gold: body['gold'] as int,
        balanceVersion: body['balanceVersion'] as int,
      );
    } catch (e) {
      debugPrint('BalanceService.getBalance error: $e');
      return null;
    }
  }

  static Future<bool> spendGold(String id, int amount,
      {String detail = ''}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/balance/spend-gold'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'odID': id, 'amount': amount, 'detail': detail}),
      );
      final body = jsonDecode(resp.body);
      return body['success'] == true;
    } catch (e) {
      debugPrint('BalanceService.spendGold error: $e');
      return false;
    }
  }

  static Future<bool> addGold(String id, int amount,
      {String detail = ''}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/balance/add-gold'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'odID': id, 'amount': amount, 'detail': detail}),
      );
      final body = jsonDecode(resp.body);
      return body['success'] == true;
    } catch (e) {
      debugPrint('BalanceService.addGold error: $e');
      return false;
    }
  }

  static Future<bool> spendGems(String id, int amount,
      {String detail = ''}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/balance/spend-gems'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'odID': id, 'amount': amount, 'detail': detail}),
      );
      final body = jsonDecode(resp.body);
      return body['success'] == true;
    } catch (e) {
      debugPrint('BalanceService.spendGems error: $e');
      return false;
    }
  }

  /// Upload Apple IAP receipt for server-side verification & gem crediting.
  /// Backend verifies receipt with Apple, grants gems based on productId,
  /// and returns the new balance. Idempotent per transactionId.
  /// POST /api/balance/verify-iap
  /// Expected server response: { success: true, gems: number }
  static Future<({bool success, int gems})?> verifyIAPReceipt({
    required String playerId,
    required String token,
    required String receipt,
    required String productId,
    String? transactionId,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/balance/verify-iap'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'odID': playerId,
          'receipt': receipt,
          'productId': productId,
          if (transactionId != null) 'transactionId': transactionId,
        }),
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body);
      if (body['success'] != true) return null;
      return (success: true, gems: body['gems'] as int);
    } catch (e) {
      debugPrint('BalanceService.verifyIAPReceipt error: $e');
      return null;
    }
  }

  static Future<bool> addGems(String id, int amount,
      {String detail = '', String? receiptId}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/balance/add-gems'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'odID': id,
          'amount': amount,
          'detail': detail,
          if (receiptId != null) 'receiptId': receiptId,
        }),
      );
      final body = jsonDecode(resp.body);
      return body['success'] == true;
    } catch (e) {
      debugPrint('BalanceService.addGems error: $e');
      return false;
    }
  }
}
