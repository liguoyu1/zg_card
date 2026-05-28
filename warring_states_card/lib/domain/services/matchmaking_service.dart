import 'package:warring_states_card/domain/services/elo_system.dart';

/// 天梯匹配服务
class MatchmakingService {
  final List<PlayerMatchInfo> _queue = [];
  DateTime? _queueStartTime;

  /// 加入匹配队列
  Future<MatchResult?> joinQueue(PlayerMatchInfo player) async {
    _queue.add(player);
    
    // 尝试匹配
    for (int i = 0; i < _queue.length; i++) {
      final opponent = _queue[i];
      if (opponent.id == player.id) continue;
      
      // 检查ELO差距
      if (!ELOSystem.canMatch(player.rating, opponent.rating)) continue;
      
      // 检查职业限制（如果有）
      if (player.excludeHeroId != null && opponent.heroId == player.excludeHeroId) continue;
      
      // 匹配成功
      _queue.remove(player);
      _queue.remove(opponent);
      
      return MatchResult(
        player1: player,
        player2: opponent,
        matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
        matchedAt: DateTime.now(),
      );
    }
    
    return null; // 未匹配到，等待
  }

  /// 离开匹配队列
  void leaveQueue(String playerId) {
    _queue.removeWhere((p) => p.id == playerId);
  }

  /// 获取队列状态
  int get queueLength => _queue.length;
  
  /// 获取预计等待时间（秒）
  int get estimatedWaitTime {
    if (_queueStartTime == null) return 0;
    return DateTime.now().difference(_queueStartTime!).inSeconds;
  }
}

/// 玩家匹配信息
class PlayerMatchInfo {
  final String id;
  final String name;
  final String heroId;
  final int rating;
  final String? deckId;
  final String? excludeHeroId; // 排除的对手英雄ID
  
  PlayerMatchInfo({
    required this.id,
    required this.name,
    required this.heroId,
    required this.rating,
    this.deckId,
    this.excludeHeroId,
  });
}

/// 匹配结果
class MatchResult {
  final PlayerMatchInfo player1;
  final PlayerMatchInfo player2;
  final String matchId;
  final DateTime matchedAt;
  
  MatchResult({
    required this.player1,
    required this.player2,
    required this.matchId,
    required this.matchedAt,
  });
  
  bool isPlayer(String playerId) => player1.id == playerId || player2.id == playerId;
  PlayerMatchInfo getOpponent(String playerId) => player1.id == playerId ? player2 : player1;
}

/// 段位显示数据
class RankDisplayData {
  final String rankKey;
  final String displayName;
  final int rating;
  final int minRating;
  final int maxRating;
  final double progress; // 当前段位进度 0-1
  
  RankDisplayData({
    required this.rankKey,
    required this.displayName,
    required this.rating,
    required this.minRating,
    required this.maxRating,
    required this.progress,
  });
  
  factory RankDisplayData.fromRating(int rating) {
    final rankKey = ELOSystem.getRank(rating);
    final displayName = ELOSystem.getRankDisplayName(rankKey);
    
    // 找到段位上下限
    int minRating = 0;
    int maxRating = 200;
    
    final thresholds = ELOSystem.rankThresholds.entries.toList();
    for (int i = 0; i < thresholds.length; i++) {
      if (thresholds[i].key == rankKey) {
        minRating = thresholds[i].value;
        maxRating = i + 1 < thresholds.length ? thresholds[i + 1].value : 5000;
        break;
      }
    }
    
    final progress = (rating - minRating) / (maxRating - minRating);
    
    return RankDisplayData(
      rankKey: rankKey,
      displayName: displayName,
      rating: rating,
      minRating: minRating,
      maxRating: maxRating,
      progress: progress.clamp(0.0, 1.0),
    );
  }
}