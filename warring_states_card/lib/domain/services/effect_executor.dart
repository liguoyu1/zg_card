import '../models/models.dart';
import 'effects.dart';
import 'game_rules.dart';
import 'upgrade_system.dart';

/// 效果执行器 - 负责解析和执行卡牌效果
class EffectExecutor {
  /// 执行卡牌的战吼效果
  GameState executeBattlecry(
    GameState state,
    String playerId,
    Card card,
    String? targetId,
  ) {
    if (!card.hasBattlecry) return state;
    
    // 根据卡牌ID查找对应效果
    final effect = _getBattlecryEffect(card.id);
    if (effect != null) {
      return effect.execute(state, playerId, targetId);
    }
    
    return state;
  }
  
  /// 执行亡语效果
  GameState executeDeathrattle(
    GameState state,
    String playerId,
    Card card,
  ) {
    if (!card.hasDeathrattle) return state;
    
    final effect = _getDeathrattleEffect(card.id);
    if (effect != null) {
      return effect.execute(state, playerId, null);
    }
    
    return state;
  }
  
  /// 执行战吼效果
  GameState executeInspire(
    GameState state,
    String playerId,
    Card card,
  ) {
    if (!card.hasInspire) return state;
    
    final effect = _getInspireEffect(card.id);
    if (effect != null) {
      return effect.execute(state, playerId, null);
    }
    
    return state;
  }
  
  /// 触发激励效果
  GameState triggerInspire(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    var currentState = state;
    
    for (final card in player.board) {
      if (card.hasInspire) {
        currentState = executeInspire(currentState, playerId, card);
      }
    }
    
    return currentState;
  }
  
  /// 处理随从死亡
  GameState handleDeath(GameState state, String playerId, Card deadCard) {
    var currentState = state;
    
    // 更新升级状态
    currentState = _updateUpgradeProgress(currentState, playerId, deadCard);
    
    // 触发亡语
    if (deadCard.hasDeathrattle) {
      currentState = executeDeathrattle(currentState, playerId, deadCard);
    }
    
    return currentState;
  }
  
  /// 更新升级进度
  GameState _updateUpgradeProgress(
    GameState state,
    String playerId,
    Card card,
  ) {
    // 简化处理：记录消灭次数等
    // 实际游戏中需要维护更复杂的状态
    return state;
  }
  
  /// 根据卡牌ID获取战吼效果
  CardEffect? _getBattlecryEffect(String cardId) {
    final effects = _battlecryEffects;
    return effects[cardId];
  }
  
  /// 根据卡牌ID获取亡语效果
  CardEffect? _getDeathrattleEffect(String cardId) {
    final effects = _deathrattleEffects;
    return effects[cardId];
  }
  
  /// 根据卡牌ID获取激励效果
  CardEffect? _getInspireEffect(String cardId) {
    final effects = _inspireEffects;
    return effects[cardId];
  }
  
  /// 战吼效果映射
  static final Map<String, CardEffect> _battlecryEffects = {
    'B001': const DamageEffect(1, targetHero: true), // 魏武卒
    'B002': const BuffEffect(attackBonus: 1, healthBonus: 1, toSelf: true), // 庞涓
    'B003': const DrawCardsEffect(1), // 孙膑
    'B004': const DamageEffect(2), // 吴起
    'B005': const HealEffect(2), // 乐毅
    'B006': const SummonEffect(Card(
      id: 'temp',
      name: '步兵',
      type: CardType.minion,
      cost: 0,
      attack: 1,
      health: 1,
      description: '',
      owner: CardOwner.bingjia,
      rarity: Rarity.common,
    )), // 田单
    'F001': const GainArmorEffect(2), // 商鞅
    'F002': const BuffEffect(attackBonus: 2, toSelf: true), // 李斯
    'F003': const DrawCardsEffect(2), // 韩非
    'F004': const DamageEffect(1, targetHero: true), // 申不害
    'F005': const BuffEffect(healthBonus: 2, toSelf: true), // 慎到
    'R001': const HealEffect(2), // 儒生
    'R002': const DrawCardsEffect(1), // 孟子
    'R003': const BuffEffect(attackBonus: 1, healthBonus: 2, toSelf: true), // 荀子
    'R004': const BuffEffect(healthBonus: 2, toSelf: true), // 颜回
    'R005': const DrawCardsEffect(2), // 子思
    'R006': const HealEffect(3), // 曾子
    'R007': const BuffEffect(attackBonus: 1, toSelf: true), // 子路
    'R008': const ComboEffect([
      DrawCardsEffect(3),
      HealEffect(4),
    ]), // 孔子
    'D001': const BuffEffect(attackBonus: 1, toSelf: true), // 隐士
    'D002': const DrawCardsEffect(2), // 杨朱
    'D003': const HealEffect(5), // 南华真人
    'D004': const BuffEffect(attackBonus: 2, healthBonus: 2, toSelf: true), // 列子
    'D005': const GainArmorEffect(5), // 庄子
    'M001': const DamageEffect(1), // 墨者
    'M002': const BuffEffect(attackBonus: 2, toSelf: true), // 巨子
    'M003': const SummonEffect(Card(
      id: 'temp',
      name: '机关兽',
      type: CardType.minion,
      cost: 0,
      attack: 1,
      health: 1,
      description: '',
      owner: CardOwner.mojia,
      rarity: Rarity.common,
    )), // 公输班
    'M004': const DrawCardsEffect(1), // 禽滑厘
    'M005': const BuffEffect(attackBonus: 1, healthBonus: 1, toSelf: true), // 孟胜
    'M006': const DamageEffect(2), // 苦获
    'M007': const HealEffect(2), // 相里勤
    'M008': const ComboEffect([ // 墨子
      SummonEffect(Card(
        id: 'temp',
        name: '机关兽',
        type: CardType.minion,
        cost: 0,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.mojia,
        rarity: Rarity.common,
      )),
      SummonEffect(Card(
        id: 'temp2',
        name: '机关兽',
        type: CardType.minion,
        cost: 0,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.mojia,
        rarity: Rarity.common,
      )),
    ]),
    'Y001': const BuffEffect(attackBonus: 1, toSelf: true), // 阴阳学徒
    'Y002': const BuffEffect(attackBonus: 2, healthBonus: 2, toSelf: true), // 邹衍
    'Y003': const HealEffect(3), // 甘德
    'Y004': const DrawCardsEffect(2), // 魏伯阳
    'Y005': const TransformEffect(Card(
      id: 'temp',
      name: '羊',
      type: CardType.minion,
      cost: 0,
      attack: 0,
      health: 1,
      description: '变成绵羊',
      owner: CardOwner.yinyangjia,
      rarity: Rarity.rare,
    )), // 驺衍
    'Z001': const DamageEffect(1, targetHero: true), // 纵横家学徒
    'Z002': const BuffEffect(attackBonus: 1, healthBonus: 1, toSelf: true), // 庞煖
    'Z003': const DrawCardsEffect(1), // 苏秦
    'Z004': const BuffEffect(attackBonus: 2, toSelf: true), // 张仪
    'Z005': const BuffEffect(healthBonus: 2, toSelf: true), // 公孙衍
    'Z006': const DamageEffect(2, targetHero: true), // 陈轸
    'Z007': const DamageEffect(2), // 惠施
    'Z008': const ComboEffect([ // 苏秦+张仪组合
      BuffEffect(attackBonus: 1, healthBonus: 1, toSelf: true),
      DrawCardsEffect(1),
    ]), // 苏秦
    'Z009': const ComboEffect([ // 苏秦+张仪组合
      BuffEffect(attackBonus: 1, healthBonus: 1, toSelf: true),
      DrawCardsEffect(1),
    ]), // 张仪
  };
  
  /// 亡语效果映射
  static final Map<String, CardEffect> _deathrattleEffects = {
    'N001': const SummonEffect(Card(
      id: 'temp',
      name: '民兵',
      type: CardType.minion,
      cost: 0,
      attack: 1,
      health: 1,
      description: '',
      owner: CardOwner.neutral,
      rarity: Rarity.common,
    )),
    'N002': const DrawCardsEffect(1),
    'N003': const DamageEffect(1, targetHero: true),
    'N004': const HealEffect(2),
    'N005': const SummonEffect(Card(
      id: 'temp',
      name: '1/1士兵',
      type: CardType.minion,
      cost: 0,
      attack: 1,
      health: 1,
      description: '',
      owner: CardOwner.neutral,
      rarity: Rarity.common,
    )),
    'N006': const SummonEffect(Card(
      id: 'temp',
      name: '2/2士兵',
      type: CardType.minion,
      cost: 0,
      attack: 2,
      health: 2,
      description: '',
      owner: CardOwner.neutral,
      rarity: Rarity.common,
    )),
  };
  
  /// 激励效果映射
  static final Map<String, CardEffect> _inspireEffects = {
    'B010': const BuffEffect(attackBonus: 1, healthBonus: 1, toSelf: true), // 孙膑
    'F006': const BuffEffect(attackBonus: 2, toSelf: true), // 商鞅
    'R009': const HealEffect(2), // 子思
    'D006': const BuffEffect(healthBonus: 2, toSelf: true), // 杨朱
    'M009': const DamageEffect(1, targetHero: true), // 墨子
    'Y006': const BuffEffect(attackBonus: 2, toSelf: true), // 邹衍
    'Z010': const DamageEffect(2, targetHero: true), // 苏秦
  };
  
  /// 执行连锁效果
  GameState executeChain(
    GameState state,
    String playerId,
    Card triggeringCard,
    ChainType chainType,
    List<String>? targetIds,
  ) {
    var currentState = state;
    
    switch (chainType) {
      case ChainType.battlecry:
        currentState = executeBattlecry(
          currentState,
          playerId,
          triggeringCard,
          targetIds?.firstOrNull,
        );
        break;
      case ChainType.deathrattle:
        currentState = executeDeathrattle(currentState, playerId, triggeringCard);
        break;
      case ChainType.inspire:
        currentState = executeInspire(currentState, playerId, triggeringCard);
        break;
    }
    
    return currentState;
  }
  
  /// 检查并执行连锁
  GameState processChainTrigger(
    GameState state,
    String playerId,
    Card triggeredCard,
    ChainType chainType,
  ) {
    var currentState = state;
    
    // 执行本卡的效果
    currentState = executeChain(currentState, playerId, triggeredCard, chainType, null);
    
    return currentState;
  }
}

/// 连锁类型
enum ChainType {
  battlecry,  // 战吼
  deathrattle, // 亡语
  inspire,    // 激励
}

/// 连锁触发器
class ChainTrigger {
  /// 检测连锁条件
  static bool checkTrigger(
    GameState state,
    String playerId,
    Card card,
    ChainTriggerType triggerType,
  ) {
    switch (triggerType) {
      case ChainTriggerType.onPlay:
        return true; // 打出时必定触发
      case ChainTriggerType.onDeath:
        return true; // 死亡时必定触发
      case ChainTriggerType.onInspire:
        return state.turnNumber > 0; // 激励需要至少过了一个回合
      case ChainTriggerType.onDamage:
        return true; // 受伤时触发
      case ChainTriggerType.onHeal:
        return true; // 治疗时触发
      case ChainTriggerType.onDraw:
        return true; // 抽牌时触发
    }
  }
  
  /// 处理触发效果后的连锁
  static List<Card> getChainTargets(
    GameState state,
    String playerId,
    Card card,
    ChainTriggerType triggerType,
  ) {
    final targets = <Card>[];
    final player = state.getCurrentPlayer(playerId);
    
    switch (triggerType) {
      case ChainTriggerType.onPlay:
        // 战吼目标
        if (card.type == CardType.spell) {
          return []; // 法术无目标
        }
        // 检查是否有敌方随从
        if (state.opponent.board.isNotEmpty) {
          targets.add(state.opponent.board.first);
        }
        break;
      case ChainTriggerType.onDeath:
        // 亡语目标为自己
        targets.add(card);
        break;
      case ChainTriggerType.onInspire:
        // 激励目标为自身
        targets.add(card);
        break;
      case ChainTriggerType.onDamage:
        // 受伤目标为自身
        targets.add(card);
        break;
      case ChainTriggerType.onHeal:
        // 治疗目标为英雄
        break;
      case ChainTriggerType.onDraw:
        // 抽牌目标为抽到的牌
        break;
    }
    
    return targets;
  }
}

/// 连锁触发类型
enum ChainTriggerType {
  onPlay,       // 打出时
  onDeath,      // 死亡时
  onInspire,    // 激励时
  onDamage,     // 受伤时
  onHeal,       // 治疗时
  onDraw,       // 抽牌时
}