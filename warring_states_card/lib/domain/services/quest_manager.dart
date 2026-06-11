import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../models/quest.dart';
import '../../data/persistence/save_manager.dart';

/// 每日任务管理器
class QuestManager {
  static final QuestManager I = QuestManager._();

  final Random _rng = Random();
  List<DailyQuest> _quests = [];
  DateTime _lastRefreshDate = DateTime.now().subtract(const Duration(days: 1));
  int _refreshCount = 0;

  List<DailyQuest> get quests => List.unmodifiable(_quests);
  DateTime get lastRefreshDate => _lastRefreshDate;
  bool get canRefresh => _refreshCount < 1;

  static const String _saveFile = 'quests.json';

  QuestManager._();

  /// 初始化
  Future<void> init() async {
    final dir = Directory('saves');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('saves/$_saveFile');
    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString());
        _lastRefreshDate = DateTime.parse(json['date']);
        _refreshCount = json['refreshCount'] ?? 0;
        _quests = (json['quests'] as List).map((q) => DailyQuest.fromJson(q)).toList();
      } catch (_) {
        _quests = [];
      }
    }

    _checkDailyReset();
  }

  void _save() {
    final data = {
      'date': _lastRefreshDate.toIso8601String().split('T')[0],
      'refreshCount': _refreshCount,
      'quests': _quests.map((q) => q.toJson()).toList(),
    };
    File('saves/$_saveFile').writeAsString(jsonEncode(data));
  }

  void _checkDailyReset() {
    if (DateTime.now().day != _lastRefreshDate.day) {
      _generateDailyQuests();
      _lastRefreshDate = DateTime.now();
      _refreshCount = 0;
      _save();
    }
  }

  void _generateDailyQuests() {
    final pool = _allQuestTemplates();
    pool.shuffle(_rng);
    _quests = pool.take(3).toList();
  }

  List<DailyQuest> _allQuestTemplates() => [
    DailyQuest(id: 'q_win_3', type: QuestType.winMatches, title: '战无不克', description: '赢得3场对战', target: 3, goldReward: 30),
    DailyQuest(id: 'q_school_10', type: QuestType.playSchoolCards, title: '学派精通', description: '打出10张兵家卡牌', target: 10, goldReward: 20, dustReward: 5),
    DailyQuest(id: 'q_damage_50', type: QuestType.dealDamage, title: '武力展示', description: '造成50点伤害', target: 50, goldReward: 25),
    DailyQuest(id: 'q_hero_5', type: QuestType.useHeroPower, title: '英雄之威', description: '使用5次英雄技能', target: 5, goldReward: 20),
    DailyQuest(id: 'q_boss_1', type: QuestType.bossKill, title: '破阵', description: '击败1个冒险Boss', target: 1, goldReward: 40),
    DailyQuest(id: 'q_draw_20', type: QuestType.drawCards, title: '谋略', description: '抽20张牌', target: 20, goldReward: 15),
    DailyQuest(id: 'q_fusion_2', type: QuestType.fusionPerformed, title: '合纵之术', description: '融合2次卡牌', target: 2, goldReward: 25, dustReward: 10),
  ];

  /// 上报事件 → 更新任务进度
  void reportEvent(QuestEvent event) {
    _checkDailyReset();
    bool changed = false;

    for (final quest in _quests) {
      if (quest.completed || quest.claimed) continue;
      final matched = _matchQuest(quest, event);
      if (matched > 0) {
        quest.progress = (quest.progress + matched).clamp(0, quest.target);
        if (quest.progress >= quest.target) quest.completed = true;
        changed = true;
      }
    }

    if (changed) _save();
  }

  int _matchQuest(DailyQuest quest, QuestEvent event) {
    switch (quest.type) {
      case QuestType.winMatches:
        return event.type == QuestEventType.matchWin ? event.value : 0;
      case QuestType.playSchoolCards:
        if (event.type != QuestEventType.cardPlayed) return 0;
        if (event.cardSchool != null && event.cardSchool != 'bing') return 0;
        return event.value;
      case QuestType.dealDamage:
        return event.type == QuestEventType.damageDealt ? event.value : 0;
      case QuestType.useHeroPower:
        return event.type == QuestEventType.heroPowerUsed ? event.value : 0;
      case QuestType.bossKill:
        return event.type == QuestEventType.bossKilled ? event.value : 0;
      case QuestType.drawCards:
        return event.type == QuestEventType.cardsDrawn ? event.value : 0;
      case QuestType.fusionPerformed:
        return event.type == QuestEventType.fusionPerformed ? event.value : 0;
    }
  }

  /// 领取奖励
  Map<String, int> claimReward(int index) {
    if (index < 0 || index >= _quests.length) return {};
    final quest = _quests[index];
    if (!quest.completed || quest.claimed) return {};

    quest.claimed = true;

    // 持久化更新 PlayerData.gold
    SaveManager.loadPlayerData().then((data) {
      if (data != null) {
        SaveManager.savePlayerData(data.copyWith(gold: data.gold + quest.goldReward));
      }
    });

    _save();
    return {'gold': quest.goldReward, 'dust': quest.dustReward};
  }

  /// 刷新一个任务
  void refreshQuest(int index) {
    if (_refreshCount >= 1) return;
    if (index < 0 || index >= _quests.length) return;

    final pool = _allQuestTemplates()
      ..removeWhere((t) => _quests.any((q) => q.id == t.id));
    pool.shuffle(_rng);

    if (pool.isNotEmpty) {
      _quests[index] = pool.first;
      _refreshCount++;
      _save();
    }
  }
}
