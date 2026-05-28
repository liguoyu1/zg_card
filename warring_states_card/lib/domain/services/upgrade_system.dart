import '../models/models.dart';

/// 升级条件类型
enum UpgradeCondition {
  killMinion,       // 消灭敌方随从
  keepInHand,       // 在手牌保留回合数
  triggerBattlecry, // 触发战吼次数
  damageDealt,      // 累计造成伤害
}

/// 对局内卡牌升级系统
class UpgradeSystem {
  /// 最大升级等级
  static const int maxLevel = 3;
  
  /// 升级效果类型
  static const Map<UpgradeCondition, Map<String, dynamic>> upgradeEffects = {
    UpgradeCondition.killMinion: {
      'trigger': '消灭敌方随从',
      'count': 3,
      'effect': {'attack': 1},
    },
    UpgradeCondition.keepInHand: {
      'trigger': '在手牌保留2回合',
      'count': 2,
      'effect': {'health': 1},
    },
    UpgradeCondition.triggerBattlecry: {
      'trigger': '触发战吼3次',
      'count': 3,
      'effect': {'newKeyword': true},
    },
    UpgradeCondition.damageDealt: {
      'trigger': '累计造成5点伤害',
      'count': 5,
      'effect': {'attack': 1, 'health': 1},
    },
  };
  
  /// 卡牌升级状态
  final Map<String, UpgradeState> cardUpgradeStates = {};
  
  /// 获取卡牌升级状态
  UpgradeState? getUpgradeState(String cardId) {
    return cardUpgradeStates[cardId];
  }
  
  /// 触发升级条件
  void triggerCondition(String cardId, UpgradeCondition condition, int currentLevel) {
    if (currentLevel >= maxLevel) return;
    
    final state = cardUpgradeStates[cardId] ?? UpgradeState(cardId: cardId);
    final newCounts = Map<UpgradeCondition, int>.from(state.conditionCounts);
    newCounts[condition] = (newCounts[condition] ?? 0) + 1;
    
    final effect = upgradeEffects[condition]!;
    final requiredCount = effect['count'] as int;
    
    if (newCounts[condition]! >= requiredCount) {
      cardUpgradeStates[cardId] = state.copyWith(
        level: currentLevel + 1,
        conditionCounts: newCounts,
      );
    } else {
      cardUpgradeStates[cardId] = state.copyWith(conditionCounts: newCounts);
    }
  }
  
  /// 获取升级后的卡牌
  Card? upgradeCard(Card card) {
    final state = cardUpgradeStates[card.id];
    if (state == null || state.level == 0) return card;
    
    final upgrades = <String, dynamic>{};
    for (final entry in state.conditionCounts.entries) {
      if (entry.value > 0) {
        final effect = upgradeEffects[entry.key]!;
        upgrades.addAll(effect['effect'] as Map<String, dynamic>);
      }
    }
    
    int attackBonus = 0;
    int healthBonus = 0;
    List<Keyword> newKeywords = [];
    
    if (upgrades.containsKey('attack')) {
      attackBonus = (upgrades['attack'] as int) * state.level;
    }
    if (upgrades.containsKey('health')) {
      healthBonus = (upgrades['health'] as int) * state.level;
    }
    if (upgrades.containsKey('newKeyword') && upgrades['newKeyword'] == true) {
      newKeywords = [Keyword.battlecry]; // 简化：升级获得战吼
    }
    
    return card.copyWith(
      attack: card.attack + attackBonus,
      health: card.health + healthBonus,
      keywords: [...card.keywords, ...newKeywords],
    );
  }
}

/// 卡牌升级状态
class UpgradeState {
  final String cardId;
  final int level;
  final Map<UpgradeCondition, int> conditionCounts;
  
  UpgradeState({
    required this.cardId,
    this.level = 0,
    Map<UpgradeCondition, int>? conditionCounts,
  }) : conditionCounts = conditionCounts ?? {};
  
  UpgradeState copyWith({
    String? cardId,
    int? level,
    Map<UpgradeCondition, int>? conditionCounts,
  }) {
    return UpgradeState(
      cardId: cardId ?? this.cardId,
      level: level ?? this.level,
      conditionCounts: conditionCounts ?? this.conditionCounts,
    );
  }
}