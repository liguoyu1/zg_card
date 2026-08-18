import '../models/models.dart';
import 'effects.dart';
import 'spell_effects.dart';

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

    final effect = deathrattleFor(card.id);
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
  CardEffect? _getBattlecryEffect(String cardId) => _battlecryEffects[cardId];

  /// 根据卡牌ID获取激励效果
  CardEffect? _getInspireEffect(String cardId) => _inspireEffects[cardId];

  /// 公开 API —— 战吼效果
  CardEffect? effectFor(String id) => _battlecryEffects[id];

  /// 公开 API —— 亡语效果（含武器亡语）
  CardEffect? deathrattleFor(String id) =>
      _deathrattleEffects[id] ?? _weaponDeathrattleEffects[id];

  /// 公开 API —— 武器佩戴效果（无战吼关键字的武器）
  CardEffect? weaponEquipEffectFor(String id) => _weaponEquipEffects[id];

  /// 公开 API —— 武器亡语效果
  CardEffect? weaponDeathrattleEffectFor(String id) =>
      _weaponDeathrattleEffects[id];

  /// 执行武器佩戴效果（战吼型武器走战吼；否则戴装备效果）
  /// 注意：学派共振由 SpellSystem 另行处理，此处不触碰英雄归属。
  GameState executeWeaponEquip(
    GameState state,
    String playerId,
    Card weapon, {
    String? targetId,
  }) {
    if (weapon.hasBattlecry) {
      return executeBattlecry(state, playerId, weapon, targetId);
    }
    final effect = weaponEquipEffectFor(weapon.id);
    if (effect != null) {
      return effect.execute(state, playerId, targetId);
    }
    return state;
  }

  /// 随从卡常数（供召唤类效果复用）
  static const Card _xiaoxi = Card(
    id: 't_xiaoxi',
    name: '孝子',
    type: CardType.minion,
    cost: 0,
    attack: 1,
    health: 1,
    maxHealth: 1,
    description: '',
    owner: CardOwner.neutral,
    rarity: Rarity.common,
  );
  static const Card _xiaojiguan = Card(
    id: 't_xiaojiguan',
    name: '小机关兽',
    type: CardType.minion,
    cost: 0,
    attack: 1,
    health: 1,
    maxHealth: 1,
    description: '',
    owner: CardOwner.neutral,
    rarity: Rarity.common,
  );
  static const Card _jiguanJingwei = Card(
    id: 't_jiguanjingwei',
    name: '机关守卫',
    type: CardType.minion,
    cost: 0,
    attack: 3,
    health: 3,
    maxHealth: 3,
    description: '',
    owner: CardOwner.neutral,
    rarity: Rarity.common,
  );

  /// 战吼效果映射（键 = 数据中真实卡牌 id）
  static final Map<String, CardEffect> _battlecryEffects = {
    // —— 中立 ——
    'N002': const DrawOneDeckEffect(), // 斥候：抽一张牌
    'N006': const DrawOneDeckEffect(), // 谋士：抽一张牌
    'N007': const HealEffect(2), // 药师：恢复2点生命
    'N011': const DamageRandomEnemyMinionEffect(1), // 方士：造成1点伤害
    'N012': const HealEffect(3), // 医师：恢复3点生命
    'N014': const SelfBuffEffect(atk: 1, def: 1), // 校尉：获得+1/+1
    'N019': const DrawCardsEffect(2), // 谋主：抽两张牌
    'N021': const BuffAllEffect(atk: 1, def: 1), // 将军
    'N022': const DamageRandomEnemyMinionEffect(2), // 勇士
    'N024': const DrawCardsEffect(3), // 上将军：抽三张牌
    'N025': const DamageRandomEnemyMinionEffect(3), // 战神
    'N026': // 霸王：所有敌方-2/-2
        const BuffAllEffect(atk: -2, def: -2),
    'N027': // 天帝：摧毁所有攻击力<5敌方随从
        DestroyAllEffect(
      condition: (c) => c.attack < 5,
    ),
    'N028': const HealAllFriendlyEffect(10), // 神龙：恢复所有友方10点生命
    // —— 兵家 ——
    'B001': const SelfBuffEffect(atk: 1), // 魏武卒：获得+1攻击力
    'B006': const DamageRandomEnemyMinionEffect(2), // 齐技击士：随机2点伤害
    'B008': const DestroyAllEffect(), // 孙武：摧毁所有敌方随从
    'B009': const BuffAllEffect(atk: 1, def: 1), // 吴起
    'B010': const BuffStrongestEffect(// 孙膑：友方嘲讽+圣盾
        addKeywords: [Keyword.taunt, Keyword.divineShield]),
    'B011': const GainArmorEffect(5), // 廉颇：获得5点护甲
    'B012': const DrawCardsEffect(3), // 李牧：抽三张牌
    // —— 法家 ——
    'F001': const AdjustRandomEnemyEffect(-2, 0), // 执法吏：敌攻-2
    'F004': const SilenceRandomEnemyEffect(), // 律令官：沉默一个随从
    'F005': RandomDestroyEffect(condition: (c) => c.attack <= 2), // 司寇
    'F006': const BuffAllEffect(atk: -1), // 大理：敌攻-1
    'F008': const HandCostReductionEffect(-2), // 商鞅：手牌随从费用-2
    'F009': const DrawCardsEffect(2), // 韩非：抽两张（法术）牌（近似）
    'F010': const BuffStrongestEffect(atk: 2, def: 2), // 李悝
    'F011': const ReturnToHandEffect(), // 申不害：敌方随从回手
    'F012': DestroyAllEffect(
        // 吴起变法：摧毁所有奇数攻敌方随从
        condition: (c) => c.attack.isOdd),
    // —— 儒家 ——
    'R001': const HealEffect(2), // 儒生：恢复2点生命
    'R003': const BuffStrongestEffect(atk: 1, def: 1), // 乐师
    'R004': const SilenceAndFreezeEffect(), // 典狱官：敌无法攻击
    'R006': const DrawCardsEffect(2), // 贤人：抽两张牌
    'R008': const BuffAllEffect(// 孔子：友方圣盾+嘲讽
        addKeywords: [Keyword.divineShield, Keyword.taunt]),
    'R009': const DrawBuffIfMinionEffect(3, 2, 2), // 孟子
    'R010': const BuffAllEffect(atk: 1), // 荀子
    // —— 道家 ——
    'D003': const NoEffect(), // 观星者：发现法术（未实现）
    'D004': const AdjustRandomEnemyEffect(-2, 0), // 符师：敌攻-2
    'D007': const DamageRandomEnemyMinionEffect(2), // 方士：随机2点伤害
    'D008': const HandCostReductionEffect(-3, spellsOnly: true), // 老子
    'D009': const NoEffect(), // 庄子：友方无法成为法术目标（未实现）
    'D010': const BuffStrongestEffect(// 列子：友方风怒+圣盾
        addKeywords: [Keyword.windfury, Keyword.divineShield]),
    'D011': const SilenceRandomEnemyEffect(), // 关尹子：沉默敌方
    // —— 墨家 ——
    'M003': const BuffStrongestEffect(atk: 1, def: 1), // 弟子
    'M005': const GainArmorEffect(2), // 守城工兵：获得2点护甲
    'M007': const NoEffect(), // 工匠大师：发现机械（未实现）
    'M008': const SummonCopiesEffect(_jiguanJingwei, 2), // 墨子：召唤两个3/3
    'M009': const BuffWeaponEffect(2), // 公输班：武器+2攻
    'M010': const BuffStrongestEffect(// 禽滑厘：友方圣盾
        addKeywords: [Keyword.divineShield]),
    'M011': const DrawCardsEffect(2), // 田鸠：抽两张机械牌（近似）
    // —— 阴阳家 ——
    'Y001': const HealEffect(2), // 五行学徒：恢复2点生命
    'Y002': const NoEffect(), // 占卜师：发现法术（未实现）
    'Y004': const AdjustRandomEnemyEffect(-2, 0), // 祭司：敌攻-2
    'Y005': const DrawOneDeckEffect(), // 星象师：抽一张牌（法术减费未实现）
    'Y006': const BuffStrongestEffect(atk: 1, def: 1), // 风水师
    'Y007': const RandomFiveElementEffect(1), // 方术士：随机五行效果
    'Y008': const RandomFiveElementEffect(1), // 邹衍：对所有敌人随机五行（近似）
    'Y009': const NoEffect(), // 甘德：发现三张法术（未实现）
    'Y010': const SpellPowerEffect(1), // 石申：友方法术强度+1
    'Y011': const SilenceRandomEnemyEffect(), // 南公：沉默敌方
    // —— 纵横家 ——
    'Z001': const DrawOneDeckEffect(), // 说客学徒：抽一张牌
    'Z002': const AdjustRandomEnemyEffect(-1, -1), // 说客：敌-1/-1
    'Z004': const DrawOneDeckEffect(), // 使者：抽一张牌（重复抽牌未实现）
    'Z005': const NoEffect(), // 谋士：发现（未实现）
    'Z006': const DrawOneDeckEffect(), // 外交官：抽一张牌
    'Z008': const BuffAllEffect(atk: -1, def: -1), // 苏秦
    'Z009': const DrawCardsEffect(2), // 张仪：抽两张牌
    'Z010': const ReturnToHandEffect(), // 范雎：敌方随从回手
    'Z011': const DrawOneDeckEffect(), // 蔺相如：抽一张牌
    'Z012': const RandomFiveElementEffect(3), // 鬼谷子：随机三个效果（近似）
    // —— 武器（战吼型）—— SpellSystem 负整点也会经由此表
    'BW001': const DamageRandomEnemyMinionEffect(1), // 兵家·吴钩
    'FW001': const SilenceRandomEnemyEffect(), // 法家·律尺
    'RW001': const HealEffect(3), // 儒家·玉圭：恢复3点生命
    'RW002': const BuffAllEffect(atk: 1, def: 1), // 儒家·编钟
    'DW001': const AdjustRandomEnemyEffect(-2, 0), // 道家·拂尘
    'MW001': const DamageRandomEnemyMinionEffect(2), // 墨家·机关弩
    'MW002': const NoEffect(), // 公输尺：发现机械（未实现）
    'NW003':
        RandomDestroyEffect(condition: (c) => c.rarity == Rarity.legendary),
    'YW001': const RandomFiveElementEffect(1), // 阴阳·五行杖
    'YW002': const DrawCardsEffect(2), // 阴阳·占星罗盘
    'ZW002': const BuffStrongestEffect(atk: 2, def: 2), // 纵横书
  };

  /// 亡语效果映射（键 = 真实卡牌 id；含武器亡语）
  static final Map<String, CardEffect> _deathrattleEffects = {
    'N003': const DrawOneDeckEffect(), // 流浪者：抽一张
    'B004': const DamageEnemyHeroEffect(2), // 燕死士：敌方英雄2点伤害
    'F002': const DamageEnemyHeroEffect(1), // 刑徒：敌方英雄1点伤害
    'F007': const DrawOneDeckEffect(), // 法家弟子：抽一张
    'M002': const SummonCopiesEffect(_xiaojiguan, 1), // 机关兽
    'M012': const DamageRandomEnemyMinionEffect(2), // 腹臣：随机2点伤害
    'R007': const BuffStrongestEffect(atk: 2, def: 2), // 夫子
    'R012': const SummonCopiesEffect(_xiaoxi, 2), // 曾子：召唤两个孝子
    'D001': const DrawOneDeckEffect(), // 道童：抽一张
    'D012': const BuffStrongestEffect(atk: 3, def: 3), // 文子
    'Y003': const DamageRandomEnemyMinionEffect(1), // 五行弟子
    'Y012': const BuffStrongestEffect(atk: 3, def: 3), // 安期生
    'Z007': const AoeDamageEffect(1), // 策士：敌方全部1点伤害
    // 武器亡语（BW002 越王剑 也在此）
    'BW002': const DamageEnemyHeroEffect(2),
  };

  /// 武器佩戴效果（无战吼关键字的武器，起手即生效）
  static final Map<String, CardEffect> _weaponEquipEffects = {
    'FW002': const GainArmorEffect(2), // 法家·刑鼎：英雄+2护甲
    'ZW001': const DrawCardsEffect(1), // 纵横·短剑：连击抽1（佩戴即抽）
    'BW002': const NoEffect(), // 越王剑：亡语（挂 break 处理）
    'BW003': const NoEffect(), // 蛇矛：风怒关键字
    'DW002': const NoEffect(), // 太极剑：圣盾关键字
    'NW001': const NoEffect(), // 青铜剑
    'NW002': const NoEffect(), // 长戟
  };

  /// 武器亡语效果映射
  static final Map<String, CardEffect> _weaponDeathrattleEffects = {
    'BW002': const DamageEnemyHeroEffect(2), // 越王剑：对敌方英雄2点伤害
  };

  /// 激励效果映射（当前数据无激励卡，预留为空）
  static final Map<String, CardEffect> _inspireEffects = {};

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
        currentState =
            executeDeathrattle(currentState, playerId, triggeringCard);
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
    currentState =
        executeChain(currentState, playerId, triggeredCard, chainType, null);

    return currentState;
  }
}

/// 连锁类型
enum ChainType {
  battlecry, // 战吼
  deathrattle, // 亡语
  inspire, // 激励
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
  onPlay, // 打出时
  onDeath, // 死亡时
  onInspire, // 激励时
  onDamage, // 受伤时
  onHeal, // 治疗时
  onDraw, // 抽牌时
}
