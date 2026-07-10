
/// 训练模式管理器
class TrainingManager {
  final Map<String, TrainingProgress> _progress = {};
  
  /// 获取训练进度
  TrainingProgress getProgress(String trainingId) {
    return _progress[trainingId] ?? TrainingProgress(
      trainingId: trainingId,
      status: TrainingStatus.locked,
    );
  }
  
  /// 完成训练
  void completeTraining(String trainingId, int score, TrainingMedal? medal) {
    final current = getProgress(trainingId);
    _progress[trainingId] = TrainingProgress(
      trainingId: trainingId,
      status: TrainingStatus.completed,
      bestScore: score > current.bestScore ? score : current.bestScore,
      attempts: current.attempts + 1,
      medal: medal,
      completedAt: DateTime.now(),
    );
  }
  
  /// 获取所有已解锁训练
  List<TrainingMission> getUnlockedTrainings() {
    return allTrainings.where((t) {
      final progress = getProgress(t.id);
      // 已解锁条件：前置训练已完成
      if (t.prerequisite == null) return true;
      return getProgress(t.prerequisite!).status == TrainingStatus.completed;
    }).toList();
  }
  
  /// 所有训练关卡
  static const List<TrainingMission> allTrainings = [
    TrainingMission(
      id: 'basic_play',
      name: '基础出牌',
      description: '学习出牌的基本机制',
      targetScore: 100,
      rewards: ['基础新秀勋章'],
    ),
    TrainingMission(
      id: 'attack_teaching',
      name: '攻击教学',
      description: '学习攻击目标选择，理解嘲讽和潜行',
      targetScore: 100,
      prerequisite: 'basic_play',
      rewards: ['攻击新秀勋章'],
    ),
    TrainingMission(
      id: 'skill_usage',
      name: '技能使用',
      description: '学习英雄技能的释放',
      targetScore: 100,
      prerequisite: 'basic_play',
      rewards: ['技能新秀勋章'],
    ),
    TrainingMission(
      id: 'battlecry',
      name: '战吼详解',
      description: '了解战吼效果的触发和最佳时机',
      targetScore: 100,
      prerequisite: 'attack_teaching',
      rewards: ['战吼学者勋章'],
    ),
    TrainingMission(
      id: 'deathrattle',
      name: '亡语技巧',
      description: '学习亡语的利用和价值评估',
      targetScore: 100,
      prerequisite: 'attack_teaching',
      rewards: ['亡语学者勋章'],
    ),
    TrainingMission(
      id: 'spell_mastery',
      name: '法术教学',
      description: '掌握法术的使用技巧',
      targetScore: 100,
      prerequisite: 'skill_usage',
      rewards: ['法术学者勋章'],
    ),
    TrainingMission(
      id: 'combo_skills',
      name: '组合技能',
      description: '学习组合激活条件与效果',
      targetScore: 100,
      prerequisite: 'spell_mastery',
      rewards: ['组合学者勋章'],
    ),
    TrainingMission(
      id: 'class_strategy',
      name: '职业攻略',
      description: '了解各职业特点和策略',
      targetScore: 100,
      prerequisite: 'battlecry',
      rewards: ['职业学者勋章'],
    ),
    TrainingMission(
      id: 'deck_building',
      name: '卡组构建',
      description: '学习卡组搭配思路',
      targetScore: 100,
      prerequisite: 'class_strategy',
      rewards: ['构筑学者勋章'],
    ),
    TrainingMission(
      id: 'battle_tactics',
      name: '对战策略',
      description: '学习回合决策和节奏把控',
      targetScore: 100,
      prerequisite: 'deck_building',
      rewards: ['战术学者勋章', '全能学者勋章'],
    ),
  ];
}

/// 训练关卡
class TrainingMission {
  
  const TrainingMission({
    required this.id,
    required this.name,
    required this.description,
    required this.targetScore,
    this.prerequisite,
    required this.rewards,
  });
  final String id;
  final String name;
  final String description;
  final int targetScore;
  final String? prerequisite;
  final List<String> rewards;
}

/// 训练进度
class TrainingProgress {
  
  TrainingProgress({
    required this.trainingId,
    required this.status,
    this.bestScore = 0,
    this.attempts = 0,
    this.medal,
    this.completedAt,
  });
  final String trainingId;
  final TrainingStatus status;
  final int bestScore;
  final int attempts;
  final TrainingMedal? medal;
  final DateTime? completedAt;
}

enum TrainingStatus { locked, unlocked, inProgress, completed }

/// 学习勋章
class TrainingMedal {
  
  const TrainingMedal({
    required this.id,
    required this.name,
    required this.level,
    this.iconAsset = '',
    this.description = '',
  });
  final String id;
  final String name;
  final MedalLevel level;
  final String iconAsset;
  final String description;
  
  /// 所有勋章定义
  static const List<TrainingMedal> allMedals = [
    // 铜勋章
    TrainingMedal(id: 'basic_bronze', name: '出牌新秀', level: MedalLevel.bronze),
    TrainingMedal(id: 'attack_bronze', name: '攻击新秀', level: MedalLevel.bronze),
    TrainingMedal(id: 'skill_bronze', name: '技能新秀', level: MedalLevel.bronze),
    // 银勋章
    TrainingMedal(id: 'battlecry_silver', name: '战吼达人', level: MedalLevel.silver),
    TrainingMedal(id: 'deathrattle_silver', name: '亡语达人', level: MedalLevel.silver),
    TrainingMedal(id: 'spell_silver', name: '法术达人', level: MedalLevel.silver),
    // 金勋章
    TrainingMedal(id: 'battlecry_gold', name: '战吼大师', level: MedalLevel.gold),
    TrainingMedal(id: 'deathrattle_gold', name: '亡语大师', level: MedalLevel.gold),
    TrainingMedal(id: 'combo_gold', name: '组合大师', level: MedalLevel.gold),
    // 特殊勋章
    TrainingMedal(id: 'all_round_scholar', name: '全能学者', level: MedalLevel.special),
  ];
}

enum MedalLevel { bronze, silver, gold, special }