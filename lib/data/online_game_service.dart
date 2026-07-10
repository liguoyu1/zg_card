import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 联机对战服务
class OnlineGameService {
  static const String _baseUrl = 'https://app-server-production-39d1.up.railway.app';
  // static const String _baseUrl = 'http://localhost:3000';
  
  String? _authToken;
  String? _odID;
  String? get myId => _odID;

  /// 游客登录
  Future<bool> guestLogin(String odName) async {
    try {
      final response = await _post('/api/auth/guest', {'name': odName});
      if (response['token'] != null) {
        _authToken = response['token'];
        _odID = response['player']?['id'];
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// 获取玩家信息
  Future<PlayerProfile?> getPlayerProfile(String odID) async {
    try {
      final response = await _get('/api/player/$odID');
      return PlayerProfile.fromJson(response);
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }

  /// 加入匹配队列
  Future<bool> joinMatchQueue({
    required String odID,
    required String odName,
    required String odHeroId,
    required int rating,
  }) async {
    try {
      final response = await _post('/api/match/join', {
        'odID': odID,
        'odName': odName,
        'odHeroId': odHeroId,
        'rating': rating,
      });
      return response['status'] == 'queued' || response['success'] == true;
    } catch (e) {
      debugPrint('Join queue error: $e');
      return false;
    }
  }

  /// 检查匹配状态
  Future<MatchResult?> checkMatchStatus({
    required String odID,
    required String odHeroId,
    required int rating,
  }) async {
    try {
      final response = await _post('/api/match/check', {
        'odID': odID,
        'odHeroId': odHeroId,
        'rating': rating,
      });
      
      if (response['matched'] == true) {
        return MatchResult(
          matchId: response['roomId'],
          opponentId: response['opponent']?['odID'],
          opponentName: response['opponent']?['odName'],
          opponentHeroId: response['opponent']?['odHeroId'],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Check status error: $e');
      return null;
    }
  }

  /// 离开匹配队列
  Future<void> leaveMatchQueue(String odID) async {
    try {
      await _post('/api/match/leave', {'odID': odID});
    } catch (e) {
      debugPrint('Leave queue error: $e');
    }
  }

  /// 获取排行榜
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    try {
      final response = await _getList('/api/leaderboard?limit=$limit');
      return response
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Get leaderboard error: $e');
      return [];
    }
  }

  /// 获取玩家排名
  Future<int> getPlayerRank(String odID) async {
    try {
      final response = await _get('/api/rank/$odID');
      return response['rank'] ?? -1;
    } catch (e) {
      debugPrint('Get rank error: $e');
      return -1;
    }
  }

  /// 提交游戏动作
  Future<int?> submitAction(String matchId, String odID, String type, {Map<String, dynamic>? data}) async {
    // seq 由客户端递增传递
    final seq = _actionSeqs[odID] ?? 0;
    try {
      await _post('/api/game/submit-action', {
        'matchId': matchId,
        'odID': odID,
        'seq': seq,
        'action': { 'type': type, 'odID': odID, if (data != null) 'data': data },
      });
      _actionSeqs[odID] = seq + 1;
      return seq;
    } catch (e) {
      debugPrint('submitAction error: $e');
      return null;
    }
  }
  final Map<String, int> _actionSeqs = {};

  /// 轮询对手动作
  Future<Map<String, dynamic>> pollActions(String matchId, {int after = 0}) async {
    try {
      return await _post('/api/game/poll-actions', { 'matchId': matchId, 'after': after });
    } catch (e) {
      debugPrint('pollActions error: $e');
      return { 'actions': [], 'room': null };
    }
  }

  Future<void> updateStats({
    required String odID,
    required bool won,
    required int opponentRating,
  }) async {
    try {
      await _post('/api/player/update-stats', {
        'odID': odID,
        'won': won,
        'opponentRating': opponentRating,
      });
    } catch (e) {
      debugPrint('Update stats error: $e');
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
}

/// 匹配结果
class MatchResult {

  MatchResult({
    required this.matchId,
    this.opponentId,
    this.opponentName,
    this.opponentHeroId,
  });
  final String matchId;
  final String? opponentId;
  final String? opponentName;
  final String? opponentHeroId;
}

/// 玩家档案
class PlayerProfile {

  PlayerProfile({
    required this.odID,
    required this.odName,
    required this.rating,
    required this.rank,
    required this.totalMatches,
    required this.winCount,
    required this.winRate,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    odID: json['odID'] ?? '',
    odName: json['odName'] ?? '',
    rating: json['rating'] ?? 1000,
    rank: json['rank'] ?? 'bronze',
    totalMatches: json['totalMatches'] ?? 0,
    winCount: json['winCount'] ?? 0,
    winRate: (json['winRate'] ?? 0).toDouble(),
  );
  final String odID;
  final String odName;
  final int rating;
  final String rank;
  final int totalMatches;
  final int winCount;
  final double winRate;
}

/// 排行榜条目
class LeaderboardEntry {

  LeaderboardEntry({
    required this.rank,
    required this.odID,
    required this.odName,
    required this.rating,
    required this.rankName,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    rank: json['rank'] ?? 0,
    odID: json['odID'] ?? '',
    odName: json['odName'] ?? '',
    rating: json['rating'] ?? 0,
    rankName: json['rankName'] ?? '',
  );
  final int rank;
  final String odID;
  final String odName;
  final int rating;
  final String rankName;
}

/// WebSocket实时连接服务
class WebSocketService {
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// 发送游戏动作
  void sendAction(String matchId, String odID, GameAction action) {
    // TODO: 实现WebSocket发送
    debugPrint('Sending action: ${action.toJson()}');
  }

  void dispose() {
    _messageController.close();
  }
}

/// 游戏动作
class GameAction {

  GameAction({
    required this.type,
    required this.odID,
    this.data,
  });
  final String type;
  final String odID;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {
    'type': type,
    'odID': odID,
    if (data != null) 'data': data,
  };
}