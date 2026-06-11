/// 任务类型
enum QuestType {
  winMatches,
  playSchoolCards,
  dealDamage,
  useHeroPower,
  bossKill,
  drawCards,
  fusionPerformed,
}

/// 任务事件类型
enum QuestEventType {
  matchWin,
  cardPlayed,
  damageDealt,
  heroPowerUsed,
  cardsDrawn,
  fusionPerformed,
  bossKilled,
}

/// 任务事件（从游戏逻辑上报）
class QuestEvent {
  final QuestEventType type;
  final int value;
  final String? cardSchool;
  final String? cardId;

  const QuestEvent({
    required this.type,
    this.value = 1,
    this.cardSchool,
    this.cardId,
  });
}

/// 每日任务
class DailyQuest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final int target;
  final int goldReward;
  final int dustReward;
  int progress;
  bool completed;
  bool claimed;

  DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    this.goldReward = 20,
    this.dustReward = 0,
    this.progress = 0,
    this.completed = false,
    this.claimed = false,
  });

  double get progressPercent => (progress / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'target': target,
    'goldReward': goldReward,
    'dustReward': dustReward,
    'progress': progress,
    'completed': completed,
    'claimed': claimed,
  };

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
    id: json['id'],
    type: QuestType.values.firstWhere((t) => t.name == json['type']),
    title: json['title'],
    description: json['description'],
    target: json['target'],
    goldReward: json['goldReward'] ?? 20,
    dustReward: json['dustReward'] ?? 0,
    progress: json['progress'] ?? 0,
    completed: json['completed'] ?? false,
    claimed: json['claimed'] ?? false,
  );
}

/// 成就定义
class Achievement {
  final String id;
  final String title;
  final String description;
  final int goldReward;
  final String? titleReward;  // 称号
  final bool Function(Map<String, int> stats) condition; // 条件检查

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.goldReward = 0,
    this.titleReward,
    required this.condition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Achievement && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Battle Pass
class BattlePass {
  int level;
  int xp;
  bool premium;
  Set<int> claimedFreeRewards;
  Set<int> claimedPremiumRewards;

  BattlePass({
    this.level = 1,
    this.xp = 0,
    this.premium = false,
    Set<int>? claimedFreeRewards,
    Set<int>? claimedPremiumRewards,
  })  : claimedFreeRewards = claimedFreeRewards ?? {},
        claimedPremiumRewards = claimedPremiumRewards ?? {};

  int get xpToNext => 200 + (level - 1) * 50;

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'premium': premium,
    'claimedFreeRewards': claimedFreeRewards.toList(),
    'claimedPremiumRewards': claimedPremiumRewards.toList(),
  };

  factory BattlePass.fromJson(Map<String, dynamic> json) => BattlePass(
    level: json['level'] ?? 1,
    xp: json['xp'] ?? 0,
    premium: json['premium'] ?? false,
    claimedFreeRewards: Set<int>.from(json['claimedFreeRewards'] ?? []),
    claimedPremiumRewards: Set<int>.from(json['claimedPremiumRewards'] ?? []),
  );
}
