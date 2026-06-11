import '../models/quest.dart';
import '../models/models.dart';
import '../../data/persistence/save_manager.dart';

/// 成就服务 — 检查条件 + 发放奖励
class AchievementService {
  static final AchievementService I = AchievementService._();

  AchievementService._();

  /// 所有成就定义
  static final List<Achievement> allAchievements = [
    _ach('ach_first_win', '初出茅庐', '赢得第1场对战', 50, null, _stat('winCount', 1)),
    _ach('ach_50_wins', '常胜将军', '赢得50场对战', 200, '常胜将军', _stat('winCount', 50)),
    _ach('ach_100_wins', '百战勇士', '赢得100场对战', 500, '百战勇士', _stat('winCount', 100)),
    _ach('ach_collect_30', '收藏家I', '收集30张卡牌', 100, null, _stat('cardsCollected', 30)),
    _ach('ach_collect_60', '收藏家II', '收集60张卡牌', 200, null, _stat('cardsCollected', 60)),
    _ach('ach_collect_100', '收藏家III', '收集100张卡牌', 500, null, _stat('cardsCollected', 100)),
    _ach('ach_adventure', '冒险家', '通关第1章冒险', 100, null, _stat('chaptersCleared', 1)),
    _ach('ach_adventure_all', '无畏探索', '通关全部冒险章节', 300, '无畏探索', _stat('chaptersCleared', 3)),
    _ach('ach_fusion', '融合大师', '融合10次卡牌', 200, null, _stat('fusionCount', 10)),
    _ach('ach_damage', '武运昌隆', '累计造成5000点伤害', 300, '武运昌隆', _stat('totalDamage', 5000)),
  ];

  /// 简化成就构造函数
  static Achievement _ach(String id, String title, String desc, int gold, String? titleReward, bool Function(Map<String, int>) cond) {
    return Achievement(id: id, title: title, description: desc, goldReward: gold, titleReward: titleReward, condition: cond);
  }

  static bool Function(Map<String, int>) _stat(String key, int threshold) {
    return (stats) => (stats[key] ?? 0) >= threshold;
  }

  /// 检查所有成就，返回新解锁的成就列表（含奖励）
  Future<List<Achievement>> checkAchievements({
    required List<String> alreadyAchieved,
    required Map<String, int> stats,
  }) async {
    final unlocked = <Achievement>[];

    for (final ach in allAchievements) {
      if (alreadyAchieved.contains(ach.id)) continue;
      if (ach.condition(stats)) {
        unlocked.add(ach);

        // 发放奖励到 PlayerData
        final data = await SaveManager.loadPlayerData();
        if (data != null) {
          await SaveManager.savePlayerData(data.copyWith(
            gold: data.gold + ach.goldReward,
            achievedMedals: [...data.achievedMedals, ach.id],
          ));
        }
      }
    }

    return unlocked;
  }
}
