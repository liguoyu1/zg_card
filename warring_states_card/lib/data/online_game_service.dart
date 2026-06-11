import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:warring_states_card/domain/models/models.dart';

/// 联机对战服务
class OnlineGameService {
  static const String _baseUrl = 'https://warring-states-card.up.railway.app';
  // static const String _baseUrl = 'http://localhost:3000';
  
  String? _authToken;
  String? _odID;

  /// 游客登录
  Future<bool> guestLogin(String odName) async {
    try {
      final response = await _post('/api/auth/guest', {'odName': odName});
      if (response['success'] == true) {
        _authToken = response['odToken'];
        _odID = response['odID'];
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
  Future<MatchResult?> joinMatchQueue({
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
      
      if (response['success'] == true && response['matchId'] != null) {
        return MatchResult(
          matchId: response['matchId'],
          opponentId: response['opponent']?['odID'],
          opponentName: response['opponent']?['odName'],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Join queue error: $e');
      return null;
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
          matchId: response['matchId'],
          opponentId: response['opponent']?['odID'],
          opponentName: response['opponent']?['odName'],
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
      final response = await _get('/api/leaderboard?limit=$limit');
      return (response as List)
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

  /// 更新战绩
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
  final String matchId;
  final String? opponentId;
  final String? opponentName;

  MatchResult({
    required this.matchId,
    this.opponentId,
    this.opponentName,
  });
}

/// 玩家档案
class PlayerProfile {
  final String odID;
  final String odName;
  final int rating;
  final String rank;
  final int totalMatches;
  final int winCount;
  final double winRate;

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
}

/// 排行榜条目
class LeaderboardEntry {
  final int rank;
  final String odID;
  final String odName;
  final int rating;
  final String rankName;

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
  final String type;
  final String odID;
  final Map<String, dynamic>? data;

  GameAction({
    required this.type,
    required this.odID,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'odID': odID,
    if (data != null) 'data': data,
  };
}