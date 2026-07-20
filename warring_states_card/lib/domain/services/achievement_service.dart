import '../../data/persistence/save_manager.dart';
import '../models/quest.dart';

/// 成就服务 — 检查条件 + 发放奖励
class AchievementService {

  AchievementService._();
  static final AchievementService I = AchievementService._();

  /// 所有成就定义
  static final List<Achievement> allAchievements = [
    // === 对战成就 ===
    _ach('ach_first_win', '初出茅庐', '赢得第1场对战', 50, null, _stat('winCount', 1)),
    _ach('ach_10_wins', '小试牛刀', '赢得10场对战', 100, null, _stat('winCount', 10)),
    _ach('ach_50_wins', '常胜将军', '赢得50场对战', 200, '常胜将军', _stat('winCount', 50)),
    _ach('ach_100_wins', '百战勇士', '赢得100场对战', 500, '百战勇士', _stat('winCount', 100)),
    _ach('ach_200_wins', '千人斩', '赢得200场对战', 800, '千人斩', _stat('winCount', 200)),
    _ach('ach_500_wins', '战神下凡', '赢得500场对战', 1500, '战神', _stat('winCount', 500)),

    // === 对战次数 ===
    _ach('ach_50_matches', '初入江湖', '进行50场对战', 100, null, _stat('totalMatches', 50)),
    _ach('ach_200_matches', '身经百战', '进行200场对战', 300, null, _stat('totalMatches', 200)),
    _ach('ach_500_matches', '沙场老兵', '进行500场对战', 600, null, _stat('totalMatches', 500)),

    // === 胜率 ===
    _ach('ach_winrate_60', '常客', '胜率达到60%', 150, null, _statRate('winRate', 0.6)),
    _ach('ach_winrate_70', '高手', '胜率达到70%', 300, null, _statRate('winRate', 0.7)),

    // === 收藏成就 ===
    _ach('ach_collect_30', '收藏家I', '收集30张卡牌', 100, null, _stat('cardsCollected', 30)),
    _ach('ach_collect_60', '收藏家II', '收集60张卡牌', 200, null, _stat('cardsCollected', 60)),
    _ach('ach_collect_100', '收藏家III', '收集100张卡牌', 500, null, _stat('cardsCollected', 100)),
    _ach('ach_collect_150', '收藏家IV', '收集150张卡牌', 800, '大收藏家', _stat('cardsCollected', 150)),

    // === 冒险成就 ===
    _ach('ach_adventure_1', '冒险家', '通关第1章冒险', 100, null, _stat('chaptersCleared', 1)),
    _ach('ach_adventure_2', '探险家', '通关第2章冒险', 150, null, _stat('chaptersCleared', 2)),
    _ach('ach_adventure_all', '无畏探索', '通关全部冒险章节', 300, '无畏探索', _stat('chaptersCleared', 3)),

    // === 伤害成就 ===
    _ach('ach_damage_1k', '武运昌隆', '累计造成1000点伤害', 100, null, _stat('totalDamage', 1000)),
    _ach('ach_damage_5k', '万夫莫敌', '累计造成5000点伤害', 300, '万夫莫敌', _stat('totalDamage', 5000)),
    _ach('ach_damage_10k', '破军', '累计造成10000点伤害', 600, '破军', _stat('totalDamage', 10000)),
    _ach('ach_damage_20k', '无双', '累计造成20000点伤害', 1000, '无双', _stat('totalDamage', 20000)),

    // === 金币成就 ===
    _ach('ach_gold_1k', '小有积蓄', '累计获得1000金币', 100, null, _stat('totalGoldEarned', 1000)),
    _ach('ach_gold_5k', '富甲一方', '累计获得5000金币', 300, null, _stat('totalGoldEarned', 5000)),
    _ach('ach_gold_10k', '金玉满堂', '累计获得10000金币', 600, '富商', _stat('totalGoldEarned', 10000)),

    // === 连胜成就 ===
    _ach('ach_streak_5', '势如破竹', '达成5连胜', 200, null, _stat('maxWinStreak', 5)),
    _ach('ach_streak_10', '锐不可当', '达成10连胜', 500, '常胜', _stat('maxWinStreak', 10)),
    _ach('ach_streak_20', '不败神话', '达成20连胜', 1000, '不败', _stat('maxWinStreak', 20)),

    // === 英雄专属成就 ===
    _ach('ach_hero_wins_10', '英雄之路', '用任意英雄赢得10场', 100, null, _stat('heroAnyWins', 10)),
    _ach('ach_hero_sunbin_50', '兵圣传人', '孙膑赢得50场', 400, '兵圣传人', _stat('heroWins_H_B001', 50)),
    _ach('ach_hero_wuqi_50', '兵家亚圣', '吴起赢得50场', 400, '兵家亚圣', _stat('heroWins_H_B002', 50)),
    _ach('ach_hero_lianpo_50', '老将骁勇', '廉颇赢得50场', 400, '老将骁勇', _stat('heroWins_H_B003', 50)),
    _ach('ach_hero_suqing_50', '合纵名士', '苏秦赢得50场', 400, '合纵名士', _stat('heroWins_H_Z001', 50)),
    _ach('ach_hero_zhangyi_50', '连横策士', '张仪赢得50场', 400, '连横策士', _stat('heroWins_H_Z002', 50)),
    _ach('ach_hero_guiguzi_50', '鬼谷传人', '鬼谷子赢得50场', 400, '鬼谷传人', _stat('heroWins_H_Z003', 50)),
  ];

  /// 简化成就构造函数
  static Achievement _ach(String id, String title, String desc, int gold, String? titleReward, bool Function(Map<String, int>) cond) {
    final ach = Achievement(id: id, title: title, description: desc, goldReward: gold, titleReward: titleReward, condition: cond);
    _progressInfos[id] = _extractProgressInfo(id, cond);
    return ach;
  }

  /// 进度元信息（UI 显示用）
  static final Map<String, ProgressInfo> _progressInfos = {};

  /// 获取某成就的进度信息
  static ProgressInfo? progressInfo(String achId) => _progressInfos[achId];

  /// 从闭包提取 stat key + threshold（仅供 UI 展示）
  static ProgressInfo _extractProgressInfo(String id, bool Function(Map<String, int>) cond) {
    // 硬编码映射：achId → (statKey, threshold)
    const map = {
      'ach_first_win':       ('winCount', 1, false),
      'ach_10_wins':         ('winCount', 10, false),
      'ach_50_wins':         ('winCount', 50, false),
      'ach_100_wins':        ('winCount', 100, false),
      'ach_200_wins':        ('winCount', 200, false),
      'ach_500_wins':        ('winCount', 500, false),
      'ach_50_matches':      ('totalMatches', 50, false),
      'ach_200_matches':     ('totalMatches', 200, false),
      'ach_500_matches':     ('totalMatches', 500, false),
      'ach_winrate_60':      ('winRate', 60, true),
      'ach_winrate_70':      ('winRate', 70, true),
      'ach_collect_30':      ('cardsCollected', 30, false),
      'ach_collect_60':      ('cardsCollected', 60, false),
      'ach_collect_100':     ('cardsCollected', 100, false),
      'ach_collect_150':     ('cardsCollected', 150, false),
      'ach_adventure_1':     ('chaptersCleared', 1, false),
      'ach_adventure_2':     ('chaptersCleared', 2, false),
      'ach_adventure_all':   ('chaptersCleared', 3, false),
      'ach_damage_1k':       ('totalDamage', 1000, false),
      'ach_damage_5k':       ('totalDamage', 5000, false),
      'ach_damage_10k':      ('totalDamage', 10000, false),
      'ach_damage_20k':      ('totalDamage', 20000, false),
      'ach_gold_1k':         ('totalGoldEarned', 1000, false),
      'ach_gold_5k':         ('totalGoldEarned', 5000, false),
      'ach_gold_10k':        ('totalGoldEarned', 10000, false),
      'ach_streak_5':        ('maxWinStreak', 5, false),
      'ach_streak_10':       ('maxWinStreak', 10, false),
      'ach_streak_20':       ('maxWinStreak', 20, false),
      'ach_hero_wins_10':   ('heroAnyWins', 10, false),
      'ach_hero_sunbin_50': ('heroWins_H_B001', 50, false),
      'ach_hero_wuqi_50':   ('heroWins_H_B002', 50, false),
      'ach_hero_lianpo_50': ('heroWins_H_B003', 50, false),
      'ach_hero_suqing_50': ('heroWins_H_Z001', 50, false),
      'ach_hero_zhangyi_50':('heroWins_H_Z002', 50, false),
      'ach_hero_guiguzi_50':('heroWins_H_Z003', 50, false),
    };
    final entry = map[id] ?? ('', 0, false);
    return ProgressInfo(entry.$1, entry.$2, entry.$3);
  }

  static bool Function(Map<String, int>) _stat(String key, int threshold) {
    return (stats) => (stats[key] ?? 0) >= threshold;
  }

  static bool Function(Map<String, int>) _statRate(String key, double rateThreshold) {
    return (stats) {
      final total = stats['totalMatches'] ?? 0;
      if (total < 20) return false; // 样本不足
      final wins = stats['winCount'] ?? 0;
      return total > 0 && (wins / total) >= rateThreshold;
    };
  }

  /// 构建通用统计数据
  static Map<String, int> buildStats(PlayerData data, Collection collection, List<MatchRecord> history) {
    final s = <String, int>{};
    s['winCount'] = data.winCount;
    s['totalMatches'] = data.totalMatches;
    s['cardsCollected'] = collection.totalCards;
    // 从存档中加载额外统计
    s.addAll(data.stats);

    // 计算胜率
    if (data.totalMatches > 0) {
      s['winRate'] = (data.winCount * 100 ~/ data.totalMatches);
    }

    // 计算各英雄胜场（仅游戏里真实存在的英雄）
    for (final hero in ['H_B001', 'H_B002', 'H_B003', 'H_F001', 'H_F002', 'H_F003', 'H_R001', 'H_R002', 'H_R003', 'H_D001', 'H_D002', 'H_D003', 'H_M001', 'H_M002', 'H_M003', 'H_Y001', 'H_Y002', 'H_Y003', 'H_Z001', 'H_Z002', 'H_Z003']) {
      final heroWins = history.where((r) => r.isWin && r.playerHero == hero).length;
      if (heroWins > 0) s['heroWins_$hero'] = heroWins;
    }
    // 任意英雄胜场（取最大值）
    final heroWins = data.stats['heroAnyWins'] ?? 0;
    if (heroWins > 0) s['heroAnyWins'] = heroWins;

    return s;
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

  /// === 玩家画像 ===
  /// 基于成就和统计数据生成文本画像
  static String generateProfile(
    PlayerData data,
    List<Achievement> achievements,
    List<MatchRecord> history,
  ) {
    final buf = StringBuffer();

    // 称号（取最高titleReward）
    final titles = achievements.where((a) => a.titleReward != null && data.achievedMedals.contains(a.id)).map((a) => a.titleReward!).toList();
    buf.write('【');
    if (titles.isNotEmpty) {
      buf.write(titles.last); // 最高级的称号
    } else {
      buf.write('无名之辈');
    }
    buf.writeln('】');

    // 基础统计
    buf.writeln('对战 ${data.totalMatches} 场 | 胜 ${data.winCount} 场 | 胜率 ${data.winRate.toStringAsFixed(1)}%');

    // 解锁成就数
    final unlockedCount = data.achievedMedals.length;
    buf.write('成就 $unlockedCount/${allAchievements.length}');
    if (data.level > 1) {
      buf.write(' | 等级 ${data.level}');
    }
    buf.writeln();

    // 最近表现
    final recent = history.where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    if (recent.length >= 5) {
      final recentWins = recent.where((r) => r.isWin).length;
      final recentRate = recentWins / recent.length;
      buf.writeln('近7天 ${recent.length} 场 | 胜率 ${(recentRate * 100).toStringAsFixed(0)}%');
    }

    // 偏好英雄
    final heroCounts = <String, int>{};
    for (final r in history) {
      heroCounts.update(r.playerHero, (v) => v + 1, ifAbsent: () => 1);
    }
    if (heroCounts.isNotEmpty) {
      final topHero = heroCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      // 通过hero id映射到名字，简单处理
      buf.writeln('常用英雄: ${_heroName(topHero.key)} (${topHero.value}场)');
    }

    // 连胜记录
    if (data.stats['maxWinStreak'] != null && data.stats['maxWinStreak']! >= 3) {
      buf.writeln('最高连胜: ${data.stats['maxWinStreak']} 场');
    }

    // 总伤害
    if (data.stats['totalDamage'] != null && data.stats['totalDamage']! >= 1000) {
      buf.writeln('累计伤害: ${data.stats['totalDamage']}');
    }

    return buf.toString();
  }

  static String _heroName(String id) {
    const names = {
      'H_B001': '孙膑',
      'H_B002': '吴起',
      'H_B003': '廉颇',
      'H_F001': '商鞅',
      'H_F002': '韩非',
      'H_F003': '申不害',
      'H_R001': '孔子',
      'H_R002': '孟子',
      'H_R003': '荀子',
      'H_D001': '老子',
      'H_D002': '庄子',
      'H_D003': '列子',
      'H_M001': '墨子',
      'H_M002': '公输班',
      'H_M003': '禽滑厘',
      'H_Y001': '邹衍',
      'H_Y002': '甘德',
      'H_Y003': '石申',
      'H_Z001': '苏秦',
      'H_Z002': '张仪',
      'H_Z003': '鬼谷子',
    };
    return names[id] ?? id;
  }
}

/// 成就进度元信息（UI 专用）
class ProgressInfo { // true=百分比显示
  const ProgressInfo(this.statKey, this.threshold, this.isRate);
  final String statKey;
  final int threshold;
  final bool isRate;
}
