import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';

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

  List<Hero> getAvailableHeroes() {
    return getAllHeroes();
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
      // ==================== 第1章：战国风云 (10关) ====================
      AdventureChapter(id: 'chapter_1', name: '战国风云',
        description: '从春秋战国开始，统一天下之路', missions: [
        AdventureMission(id: '1-1', name: '初出茅庐', description: '跟随孙膑学习基础战术',
          difficulty: Difficulty.easy, enemyHero: 'H_B001', rewardGold: 30, rewardCards: ['C_N001']),
        AdventureMission(id: '1-2', name: '围魏救赵', description: '面对庞涓的围攻，灵活应对',
          difficulty: Difficulty.easy, enemyHero: 'H_B002', prerequisite: '1-1', rewardGold: 30, rewardCards: ['C_N002']),
        AdventureMission(id: '1-3', name: '商鞅变法', description: '面对秦国的变法新军',
          difficulty: Difficulty.normal, enemyHero: 'H_F001', prerequisite: '1-2', rewardGold: 50, rewardCards: ['C_F001']),
        AdventureMission(id: '1-4', name: '稷下学宫', description: '与儒家诸子论战',
          difficulty: Difficulty.normal, enemyHero: 'H_R001', prerequisite: '1-3', rewardGold: 50, rewardCards: ['C_R001']),
        AdventureMission(id: '1-5', name: '合纵连横', description: '击败六国宰相苏秦',
          difficulty: Difficulty.hard, enemyHero: 'H_Z001', prerequisite: '1-4', rewardGold: 100, rewardCards: ['C_Z001'], isBoss: true),
        AdventureMission(id: '1-6', name: '老马识途', description: '跟随老子领悟道法自然',
          difficulty: Difficulty.easy, enemyHero: 'H_D001', prerequisite: '1-5', rewardGold: 30, rewardCards: ['C_D001']),
        AdventureMission(id: '1-7', name: '仁义之师', description: '以仁义之道对阵孟子',
          difficulty: Difficulty.normal, enemyHero: 'H_R002', prerequisite: '1-6', rewardGold: 50, rewardCards: ['C_R002']),
        AdventureMission(id: '1-8', name: '墨守成规', description: '攻破墨家的坚固防守',
          difficulty: Difficulty.normal, enemyHero: 'H_M001', prerequisite: '1-7', rewardGold: 50, rewardCards: ['C_M001']),
        AdventureMission(id: '1-9', name: '五雷天心', description: '面对阴阳家的五行法术',
          difficulty: Difficulty.normal, enemyHero: 'H_Y001', prerequisite: '1-8', rewardGold: 50, rewardCards: ['C_Y001']),
        AdventureMission(id: '1-10', name: '孙庞斗智', description: '孙膑设下减灶之计，切勿轻敌',
          difficulty: Difficulty.hard, enemyHero: 'H_B001', prerequisite: '1-9', rewardGold: 120, rewardCards: ['C_B008'], isBoss: true),
      ]),
      // ==================== 第2章：诸子百家 (10关) ====================
      AdventureChapter(id: 'chapter_2', name: '诸子百家',
        description: '百家争鸣，思想碰撞', missions: [
        AdventureMission(id: '2-1', name: '老子问道', description: '与老子论道，领悟无为之道',
          difficulty: Difficulty.normal, enemyHero: 'H_D001', prerequisite: '1-10', rewardGold: 50, rewardCards: ['C_D002']),
        AdventureMission(id: '2-2', name: '法家三术', description: '面对韩非的势术法',
          difficulty: Difficulty.hard, enemyHero: 'H_F002', prerequisite: '2-1', rewardGold: 80, rewardCards: ['C_F002']),
        AdventureMission(id: '2-3', name: '墨家非攻', description: '强行攻破墨家的机关城防',
          difficulty: Difficulty.hard, enemyHero: 'H_M001', prerequisite: '2-2', rewardGold: 80, rewardCards: ['C_M002']),
        AdventureMission(id: '2-4', name: '百家争鸣', description: '击败百家宗师荀子',
          difficulty: Difficulty.extreme, enemyHero: 'H_R003', prerequisite: '2-3', rewardGold: 150, rewardCards: ['C_R010'], isBoss: true),
        AdventureMission(id: '2-5', name: '庖丁解牛', description: '与庄周论逍遥',
          difficulty: Difficulty.normal, enemyHero: 'H_D002', prerequisite: '2-4', rewardGold: 50, rewardCards: ['C_D003']),
        AdventureMission(id: '2-6', name: '阴阳五行', description: '破解邹衍的五行阵法',
          difficulty: Difficulty.normal, enemyHero: 'H_Y001', prerequisite: '2-5', rewardGold: 50, rewardCards: ['C_Y002']),
        AdventureMission(id: '2-7', name: '法不容情', description: '面对商鞅的严刑峻法',
          difficulty: Difficulty.hard, enemyHero: 'H_F001', prerequisite: '2-6', rewardGold: 80, rewardCards: ['C_F003']),
        AdventureMission(id: '2-8', name: '纵横捭阖', description: '破解张仪的连横之术',
          difficulty: Difficulty.normal, enemyHero: 'H_Z002', prerequisite: '2-7', rewardGold: 50, rewardCards: ['C_Z002']),
        AdventureMission(id: '2-9', name: '兼爱非攻', description: '攻破禽滑厘的守城工事',
          difficulty: Difficulty.hard, enemyHero: 'H_M003', prerequisite: '2-8', rewardGold: 80, rewardCards: ['C_M003']),
        AdventureMission(id: '2-10', name: '天志明鬼', description: '击败阴阳宗师邹衍',
          difficulty: Difficulty.extreme, enemyHero: 'H_Y001', prerequisite: '2-9', rewardGold: 180, rewardCards: ['C_Y008'], isBoss: true),
      ]),
      // ==================== 第3章：天下一统 (10关) ====================
      AdventureChapter(id: 'chapter_3', name: '天下一统',
        description: '最终决战，一统天下', missions: [
        AdventureMission(id: '3-1', name: '秦赵长平', description: '面对老将廉颇的坚守',
          difficulty: Difficulty.hard, enemyHero: 'H_B003', prerequisite: '2-10', rewardGold: 80, rewardCards: ['C_B003']),
        AdventureMission(id: '3-2', name: '荆轲刺秦', description: '面对天下第一刺客',
          difficulty: Difficulty.extreme, enemyHero: 'H_Y002', prerequisite: '3-1', rewardGold: 120, rewardCards: ['C_N015']),
        AdventureMission(id: '3-3', name: '王翦灭楚', description: '智斗赵之名将李牧',
          difficulty: Difficulty.hard, enemyHero: 'H_B003', prerequisite: '3-2', rewardGold: 80, rewardCards: ['C_B012']),
        AdventureMission(id: '3-4', name: '韩非入秦', description: '面对韩非的法家之道',
          difficulty: Difficulty.hard, enemyHero: 'H_F002', prerequisite: '3-3', rewardGold: 80, rewardCards: ['C_F009']),
        AdventureMission(id: '3-5', name: '百家归宗', description: '鬼谷子集百家之大成',
          difficulty: Difficulty.extreme, enemyHero: 'H_Z003', prerequisite: '3-4', rewardGold: 150, rewardCards: ['C_Z012'], isBoss: true),
        AdventureMission(id: '3-6', name: '焚书坑儒', description: '面对李悝的重法轻儒',
          difficulty: Difficulty.hard, enemyHero: 'H_F003', prerequisite: '3-5', rewardGold: 80, rewardCards: ['C_F005']),
        AdventureMission(id: '3-7', name: '张仪连横', description: '破解张仪的连横计谋',
          difficulty: Difficulty.extreme, enemyHero: 'H_Z002', prerequisite: '3-6', rewardGold: 120, rewardCards: ['C_Z009']),
        AdventureMission(id: '3-8', name: '北击匈奴', description: '效仿李牧北击匈奴',
          difficulty: Difficulty.hard, enemyHero: 'H_B003', prerequisite: '3-7', rewardGold: 80, rewardCards: ['C_B010']),
        AdventureMission(id: '3-9', name: '始皇统一', description: '直面秦始皇的百万雄师',
          difficulty: Difficulty.extreme, enemyHero: 'H_Z003', prerequisite: '3-8', rewardGold: 200, rewardCards: ['C_N028']),
        AdventureMission(id: '3-final', name: '终极决战', description: '击败最强状态下的秦始皇',
          difficulty: Difficulty.extreme, enemyHero: 'H_Z003', prerequisite: '3-9', rewardGold: 500, rewardCards: ['C_N028', 'C_N025'], isBoss: true, isFinal: true),
      ]),
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
  /// AI 预设核心卡组（不足 30 张时自动补充学派卡）
  final List<String> enemyDeck;
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
    this.enemyDeck = const [],
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