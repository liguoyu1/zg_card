import 'package:warring_states_card/domain/models/models.dart';

/// 冒险模式管理器
class AdventureManager {
  final List<AdventureChapter> _chapters = _buildChapters();
  
  List<AdventureChapter> get chapters => _chapters;
  
  AdventureChapter? getChapter(String chapterId) {
    try {
      return _chapters.firstWhere((c) => c.id == chapterId);
    } catch (_) {
      return null;
    }
  }
  
  AdventureMission? getMission(String missionId) {
    for (final chapter in _chapters) {
      try {
        return chapter.missions.firstWhere((m) => m.id == missionId);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
  
  bool isMissionUnlocked(String missionId) {
    final mission = getMission(missionId);
    if (mission == null || mission.prerequisite == null) return true;
    
    final preMission = getMission(mission.prerequisite!);
    return preMission?.status == MissionStatus.cleared;
  }
  
  /// 完成任务
  void completeMission(String missionId, MissionResult result) {
    // 实际实现需要保存到存档
  }
  
  static List<AdventureChapter> _buildChapters() {
    return [
      AdventureChapter(
        id: 'chapter_1',
        name: '战国风云',
        description: '从春秋战国开始，统一天下之路',
        missions: [
          AdventureMission(
            id: '1-1',
            name: '初出茅庐',
            description: '跟随孙膑学习基础战术',
            difficulty: Difficulty.easy,
            enemyHero: 'H_B001',
            rewardGold: 50,
            rewardCards: ['C_N001'],
          ),
          AdventureMission(
            id: '1-2',
            name: '围魏救赵',
            description: '击败庞涓领导的魏军',
            difficulty: Difficulty.easy,
            enemyHero: 'H_B002',
            prerequisite: '1-1',
            rewardGold: 60,
            rewardCards: ['C_N002'],
          ),
          AdventureMission(
            id: '1-3',
            name: '商鞅变法',
            description: '面对秦国的变法大军',
            difficulty: Difficulty.normal,
            enemyHero: 'H_F001',
            prerequisite: '1-2',
            rewardGold: 80,
            rewardCards: ['C_F001'],
          ),
          AdventureMission(
            id: '1-4',
            name: '稷下学宫',
            description: '与儒道法诸子论战',
            difficulty: Difficulty.normal,
            enemyHero: 'H_R001',
            prerequisite: '1-3',
            rewardGold: 100,
            rewardCards: ['C_R001'],
          ),
          AdventureMission(
            id: '1-5',
            name: '合纵连横',
            description: '击败六国宰相苏秦',
            difficulty: Difficulty.hard,
            enemyHero: 'H_Z001',
            prerequisite: '1-4',
            rewardGold: 200,
            rewardCards: ['C_Z001'],
            isBoss: true,
          ),
        ],
      ),
      AdventureChapter(
        id: 'chapter_2',
        name: '诸子百家',
        description: '百家争鸣，思想碰撞',
        missions: [
          AdventureMission(
            id: '2-1',
            name: '老子问道',
            description: '与道家论道',
            difficulty: Difficulty.normal,
            enemyHero: 'H_D001',
            prerequisite: '1-5',
            rewardGold: 100,
            rewardCards: ['C_D001'],
          ),
          AdventureMission(
            id: '2-2',
            name: '法家三术',
            description: '与法家论法',
            difficulty: Difficulty.hard,
            enemyHero: 'H_F002',
            prerequisite: '2-1',
            rewardGold: 120,
            rewardCards: ['C_F002'],
          ),
          AdventureMission(
            id: '2-3',
            name: '墨家非攻',
            description: '与墨家论兼爱',
            difficulty: Difficulty.hard,
            enemyHero: 'H_M001',
            prerequisite: '2-2',
            rewardGold: 150,
            rewardCards: ['C_M001'],
          ),
          AdventureMission(
            id: '2-4',
            name: '百家争鸣',
            description: '击败百家宗师',
            difficulty: Difficulty.extreme,
            enemyHero: 'H_M003',
            prerequisite: '2-3',
            rewardGold: 300,
            rewardCards: ['C_M003'],
            isBoss: true,
          ),
        ],
      ),
      AdventureChapter(
        id: 'chapter_3',
        name: '天下一统',
        description: '最终决战，一统天下',
        missions: [
          AdventureMission(
            id: '3-1',
            name: '秦赵长平',
            description: '决定两国命运的战斗',
            difficulty: Difficulty.hard,
            enemyHero: 'H_B003',
            prerequisite: '2-4',
            rewardGold: 200,
            rewardCards: ['C_B003'],
          ),
          AdventureMission(
            id: '3-2',
            name: '荆轲刺秦',
            description: '面对天下第一刺客',
            difficulty: Difficulty.extreme,
            enemyHero: 'H_Y001',
            prerequisite: '3-1',
            rewardGold: 250,
            rewardCards: ['C_Y001'],
          ),
          AdventureMission(
            id: '3-final',
            name: '终极决战',
            description: '击败秦始皇，一统天下',
            difficulty: Difficulty.extreme,
            enemyHero: 'H_Z003',
            prerequisite: '3-2',
            rewardGold: 500,
            rewardCards: ['C_Z003'],
            isBoss: true,
            isFinal: true,
          ),
        ],
      ),
    ];
  }
}

/// 冒险章节
class AdventureChapter {
  final String id;
  final String name;
  final String description;
  final List<AdventureMission> missions;
  
  const AdventureChapter({
    required this.id,
    required this.name,
    required this.description,
    required this.missions,
  });
  
  int get totalMissions => missions.length;
  int get clearedCount => missions.where((m) => m.status == MissionStatus.cleared).length;
  bool get isCleared => clearedCount == totalMissions;
  double get progress => totalMissions > 0 ? clearedCount / totalMissions : 0;
}

/// 冒险任务
class AdventureMission {
  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final String enemyHero;
  final String? prerequisite;
  final int rewardGold;
  final List<String> rewardCards;
  final bool isBoss;
  final bool isFinal;
  MissionStatus status;
  
  AdventureMission({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.enemyHero,
    this.prerequisite,
    required this.rewardGold,
    required this.rewardCards,
    this.isBoss = false,
    this.isFinal = false,
    this.status = MissionStatus.locked,
  });
}

enum Difficulty { easy, normal, hard, extreme }

enum MissionStatus { locked, available, inProgress, cleared, failed }

/// 任务结果
class MissionResult {
  final bool isVictory;
  final int score;
  final int remainingHealth;
  final int turns;
  final Duration duration;
  final List<String> cardsGained;
  final int goldGained;
  
  MissionResult({
    required this.isVictory,
    this.score = 0,
    this.remainingHealth = 0,
    this.turns = 0,
    this.duration = Duration.zero,
    this.cardsGained = const [],
    this.goldGained = 0,
  });
}