import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../domain/services/balance_sync_service.dart';

/// 联机对战余额服务 — 调用后端 API
class BalanceService {
  static const String _baseUrl = ApiConfig.baseUrl;

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
  static Future<({bool success, bool alreadyProcessed, int gems, int gained, String? error})?> verifyIAPReceipt({
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
      final body = jsonDecode(resp.body);
      if (resp.statusCode != 200 || body['success'] != true) {
        final err = (body is Map && body['error'] is String) ? body['error'] as String : 'HTTP ${resp.statusCode}';
        debugPrint('BalanceService.verifyIAPReceipt failed: $err');
        return (success: false, alreadyProcessed: false, gems: 0, gained: 0, error: err);
      }
      return (success: true, alreadyProcessed: body['alreadyProcessed'] == true, gems: body['gems'] as int, gained: (body['gained'] as int?) ?? 0, error: null);
    } catch (e) {
      debugPrint('BalanceService.verifyIAPReceipt error: $e');
      return (success: false, alreadyProcessed: false, gems: 0, gained: 0, error: e.toString());
    }
  }

  /// 拉取交易流水（默认最近 3 天；0 表示全部历史）
  static Future<List<Map<String, dynamic>>> getTransactions(String odID,
      {int days = 3}) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/api/balance/transactions/$odID?days=$days'));
      if (resp.statusCode != 200) return [];
      final body = jsonDecode(resp.body);
      if (body is! List) return [];
      return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('BalanceService.getTransactions error: $e');
      return [];
    }
  }

  /// 查询该玩家在 [afterMs] 之后是否有 Xsolla 入账记录（webhook 校验+发钻成功的直接结果）
  static Future<bool> checkXsollaCredited(String odID, int afterMs) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/payment/recent/$odID?after=$afterMs');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return false;
      final body = jsonDecode(resp.body);
      return body['credited'] == true;
    } catch (e) {
      debugPrint('BalanceService.checkXsollaCredited error: $e');
      return false;
    }
  }

  /// 上报本地余额到服务端对账：服务端只入账正差（本地多于服务端），
  /// 负差忽略，保证最终一致且不丢账。
  static Future<void> syncBalance(String playerId, String token,
      {required int gems, required int gold}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/balance/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'odID': playerId, 'gems': gems, 'gold': gold}),
      );
    } catch (e) {
      debugPrint('BalanceService.syncBalance error: $e');
    }
  }

  /// 上传完整存档；返回 (ok, updatedAt)：ok=false 表示失败，
  /// updatedAt 是服务端保存后的时间戳（毫秒），用于云端版本对齐（0=云端已清空）
  static Future<({bool ok, int updatedAt})> uploadSave(
      String playerId, String token, String saveJson) async {
    try {
      final resp = await http.put(
        Uri.parse('$_baseUrl/api/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'odID': playerId, 'save': jsonDecode(saveJson)}),
      );
      if (resp.statusCode != 200) return (ok: false, updatedAt: 0);
      final body = jsonDecode(resp.body);
      final ts = body is Map ? body['updatedAt'] : null;
      return (
        ok: true,
        updatedAt: ts == null
            ? 0
            : DateTime.tryParse(ts.toString())?.millisecondsSinceEpoch ?? 0,
      );
    } catch (e) {
      debugPrint('BalanceService.uploadSave error: $e');
      return (ok: false, updatedAt: 0);
    }
  }

  /// 拉取远端完整存档（null = 无存档）；返回存档 JSON 与服务端更新时间
  /// 拉取远端完整存档。
  /// 返回 null = 网络/服务端/解析失败（调用方不得据此覆盖任何数据）；
  /// ok=false 且 json 为空 = 该账号在云端没有存档；
  /// ok=true 且 json 非空 = 云端有存档。
  static Future<({bool ok, String json, String updatedAt})?> downloadSave(
      String playerId, String token) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/save'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body);
      if (body['success'] != true) return null;
      if (body['save'] == null) {
        return (ok: true, json: '', updatedAt: '');
      }
      return (
        ok: true,
        json: jsonEncode(body['save']),
        updatedAt: body['updatedAt']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('BalanceService.downloadSave error: $e');
      return null;
    }
  }

  /// 钻石→金币兑换（服务端单事务），返回权威余额
  static Future<({bool ok, int gems, int gold, String? error})?>
      exchangeGemsToGold(String playerId, String token,
          {required int gemsCost, required int goldReward}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/balance/exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'gemsCost': gemsCost, 'goldReward': goldReward}),
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode != 200 || body['success'] != true) {
        return (
          ok: false,
          gems: 0,
          gold: 0,
          error: (body is Map && body['error'] is String)
              ? body['error'] as String
              : 'HTTP ${resp.statusCode}',
        );
      }
      return (
        ok: true,
        gems: body['gems'] is int ? body['gems'] as int : 0,
        gold: body['gold'] is int ? body['gold'] as int : 0,
        error: null,
      );
    } catch (e) {
      debugPrint('BalanceService.exchangeGemsToGold error: $e');
      return null;
    }
  }

  /// 服务端购买卡/英雄（单事务扣款+入档），返回权威状态
  /// currency: 'gold' 扣金币；'gem' 扣钻石
  static Future<({bool ok, int gold, int gems, List<String> unlockedCards,
      List<String> unlockedHeroes, String? error})?>
      purchasePlayerAsset(String playerId, String token,
          {required String kind, required String assetId, required int cost,
          String currency = 'gold'}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/shop/buy-${kind == 'hero' ? 'hero' : 'card'}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'assetId': assetId, 'cost': cost, 'currency': currency}),
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode != 200 || body['success'] != true) {
        return (
          ok: false,
          gold: 0,
          gems: 0,
          unlockedCards: const <String>[],
          unlockedHeroes: const <String>[],
          error: (body is Map && body['error'] is String)
              ? body['error'] as String
              : 'HTTP ${resp.statusCode}',
        );
      }
      return (
        ok: true,
        gold: body['gold'] is int ? body['gold'] as int : int.tryParse(body['gold'].toString()) ?? 0,
        gems: body['gems'] is int ? body['gems'] as int : int.tryParse(body['gems'].toString()) ?? 0,
        unlockedCards: List<String>.from(body['unlockedCards'] ?? const []),
        unlockedHeroes: List<String>.from(body['unlockedHeroes'] ?? const []),
        error: null,
      );
    } catch (e) {
      debugPrint('BalanceService.purchasePlayerAsset error: $e');
      return null;
    }
  }

  /// 轻量查询资产版本（updatedAt 毫秒）；0 = 云端无档；null = 查询失败
  static Future<int?> fetchRemoteVersion(String playerId, String token) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/save/version'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body);
      final v = body['updatedAt'];
      if (v == null) return 0;
      return DateTime.tryParse(v.toString())?.millisecondsSinceEpoch ?? -1;
    } catch (e) {
      debugPrint('BalanceService.fetchRemoteVersion error: $e');
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

  /// 自动游客登录，确保有服务端账号 ID。返回 null 表示失败。
  static Future<String?> ensureSession([String name = '玩家']) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/auth/guest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body);
      final id = body['player']?['id'] as String?;
      final token = body['token'] as String?;
      if (id != null && token != null) {
        BalanceSyncService.setSession(id, token, playerName: name);
        return id;
      }
      return null;
    } catch (e) {
      debugPrint('BalanceService.ensureSession error: $e');
      return null;
    }
  }

  /// 上报对局结果（排行榜数据源）。失败静默，不阻塞对局结算。
  /// isPk=false 时仅记录金币（人机局），不计胜场榜。
  static Future<void> recordOnlineMatch({
    required String odID,
    required String heroId,
    required String heroClass,
    String opponentHero = '',
    required bool won,
    int goldEarned = 0,
    bool isPk = false,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/match/record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'odID': odID,
          'heroId': heroId,
          'heroClass': heroClass,
          'opponentHero': opponentHero,
          'won': won,
          'goldEarned': goldEarned,
          'isPk': isPk,
        }),
      );
    } catch (e) {
      debugPrint('BalanceService.recordOnlineMatch error: $e');
    }
  }

  /// 获取排行榜榜单（触发上一周期结算）。
  static Future<Map<String, dynamic>?> fetchRankings({
    required String metric,
    required String period,
    String? myId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/rankings?metric=$metric&period=$period'
          '${myId != null ? '&odID=$myId' : ''}');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('BalanceService.fetchRankings error: $e');
      return null;
    }
  }
}
