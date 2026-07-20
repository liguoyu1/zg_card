import 'dart:math';

/// ELO评分系统
class ELOSystem {
  /// 初始积分
  static const int initialRating = 1000;
  
  /// K因子(影响积分变化幅度)
  static const int kFactorNew = 40;   // 新手
  static const int kFactorMid = 32;   // 中级
  static const int kFactorPro = 24;   // 专业
  
  /// 积分差距限制
  static const int maxRatingDiff = 100;
  
  /// 段位阈值
  static const Map<String, int> rankThresholds = {
    'bronze5': 0,
    'bronze4': 200,
    'bronze3': 400,
    'bronze2': 600,
    'bronze1': 800,
    'silver5': 1000,
    'silver4': 1200,
    'silver3': 1400,
    'silver2': 1600,
    'silver1': 1800,
    'gold5': 2000,
    'gold4': 2200,
    'gold3': 2400,
    'gold2': 2600,
    'gold1': 2800,
    'diamond5': 3000,
    'diamond4': 3200,
    'diamond3': 3400,
    'diamond2': 3600,
    'diamond1': 3800,
    'legend': 4000,
  };
  
  /// 计算期望胜率
  static double calculateExpectedScore(int ratingA, int ratingB) {
    return 1 / (1 + pow(10, (ratingB - ratingA) / 400));
  }
  
  /// 计算积分变化
  static int calculateRatingChange({
    required int playerRating,
    required int opponentRating,
    required bool won,
    required int gameCount,
  }) {
    // 确定K因子
    int k;
    if (gameCount < 30) {
      k = kFactorNew;
    } else if (playerRating < 2000) {
      k = kFactorMid;
    } else {
      k = kFactorPro;
    }
    
    final expected = calculateExpectedScore(playerRating, opponentRating);
    final actual = won ? 1.0 : 0.0;
    
    return (k * (actual - expected)).round();
  }
  
  /// 获取段位
  static String getRank(int rating) {
    String currentRank = 'bronze5';
    
    for (final entry in rankThresholds.entries) {
      if (rating >= entry.value) {
        currentRank = entry.key;
      }
    }
    
    return currentRank;
  }
  
  /// 获取段位等级名
  static String getRankDisplayName(String rank) {
    final names = {
      'bronze5': '青铜V', 'bronze4': '青铜IV', 'bronze3': '青铜III', 'bronze2': '青铜II', 'bronze1': '青铜I',
      'silver5': '白银V', 'silver4': '白银IV', 'silver3': '白银III', 'silver2': '白银II', 'silver1': '白银I',
      'gold5': '黄金V', 'gold4': '黄金IV', 'gold3': '黄金III', 'gold2': '黄金II', 'gold1': '黄金I',
      'diamond5': '钻石V', 'diamond4': '钻石IV', 'diamond3': '钻石III', 'diamond2': '钻石II', 'diamond1': '钻石I',
      'legend': '传说',
    };
    return names[rank] ?? rank;
  }
  
  /// 检查是否可以匹配
  static bool canMatch(int ratingA, int ratingB, {int maxDiff = maxRatingDiff}) {
    return (ratingA - ratingB).abs() <= maxDiff;
  }
}

/// 勇者系统
class WarriorSystem {
  /// 连胜加成阈值
  static const int winStreakThreshold = 3;
  
  /// 连败保护阈值
  static const int loseStreakThreshold = 3;
  
  /// 计算勇者加成
  static double getWarriorBonus({
    required int winStreak,
    required int loseStreak,
    required bool isWin,
  }) {
    if (isWin) {
      if (winStreak >= 5) return 1.3;
      if (winStreak >= 4) return 1.2;
      if (winStreak >= 3) return 1.1;
    } else {
      if (loseStreak >= 4) return 0.8;
      if (loseStreak >= 3) return 0.9;
    }
    return 1.0;
  }
  
  /// 计算实际积分变化(考虑勇者加成)
  static int calculateActualChange({
    required int baseChange,
    required int winStreak,
    required int loseStreak,
    required bool isWin,
  }) {
    final bonus = getWarriorBonus(
      winStreak: winStreak,
      loseStreak: loseStreak,
      isWin: isWin,
    );
    return (baseChange * bonus).round();
  }
  
  /// 更新连胜连败记录
  static ({int winStreak, int loseStreak}) updateStreak({
    required int winStreak,
    required int loseStreak,
    required bool won,
  }) {
    if (won) {
      return (winStreak: winStreak + 1, loseStreak: 0);
    } else {
      return (winStreak: 0, loseStreak: loseStreak + 1);
    }
  }
  
  /// 降级后保护场次
  static const int protectionAfterDemotion = 3;
  
  /// 检查是否处于保护状态
  static bool isProtected({
    required int demotionProtectionGames,
    required int loseStreak,
  }) {
    return demotionProtectionGames > 0 || loseStreak >= loseStreakThreshold;
  }
}

/// 段位匹配服务
class MatchmakingService {
  /// 智能匹配：根据连胜/连败调整匹配范围
  static int getAdjustedMatchRange({
    required int winStreak,
    required int loseStreak,
    int baseRange = 100,
  }) {
    int range = baseRange;
    
    // 连胜后匹配更强的对手
    if (winStreak >= 3) {
      range += (winStreak - 2) * 25;
    }
    
    // 连败后匹配更弱的对手
    if (loseStreak >= 3) {
      range += (loseStreak - 2) * 25;
    }
    
    // 最大范围200
    return range.clamp(baseRange, 200);
  }
  
  /// 新手保护
  static bool isNewbieProtection({required int gameCount}) {
    return gameCount < 10;
  }
}