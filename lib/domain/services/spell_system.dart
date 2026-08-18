import '../../data/cards/cards.dart';
import '../models/models.dart';
import 'effect_executor.dart';
import 'effects.dart';
import 'spell_effects.dart';

/// 法术目标类型
enum SpellTargetKind {
  none,
  friendlyMinion,
  enemyMinion,
  anyMinion,
  friendlyRole,
  randomEnemyMinion,
}

/// 法术规则：目标类型 + 出牌条件
class SpellRule {
  const SpellRule({required this.targetKind, this.condition});
  final SpellTargetKind targetKind;

  /// 出牌条件（不满足则无法打出）
  final bool Function(GameState, Player)? condition;

  bool get needsTarget => targetKind != SpellTargetKind.none;

  List<String> targetOptions(GameState s, Player caster) {
    final enemy = s.opponent;
    switch (targetKind) {
      case SpellTargetKind.none:
      case SpellTargetKind.randomEnemyMinion:
        return const [];
      case SpellTargetKind.friendlyMinion:
        return caster.board.map((c) => c.id).toList();
      case SpellTargetKind.enemyMinion:
        return enemy.board.map((c) => c.id).toList();
      case SpellTargetKind.anyMinion:
        return [...caster.board, ...enemy.board].map((c) => c.id).toList();
      case SpellTargetKind.friendlyRole:
        return ['hero_${caster.id}', ...caster.board.map((c) => c.id)];
    }
  }

  bool validTarget(GameState s, Player caster, String? targetId) =>
      targetId != null && targetOptions(s, caster).contains(targetId);
}

/// 出牌条件：存在受伤的友方随从
bool _damagedMinionExists(GameState s, Player p) =>
    p.board.any((c) => c.maxHealth > 0 && c.health < c.maxHealth);

Card _bestMinion(List<Card> board) {
  Card best = board.first;
  for (final c in board) {
    if (c.attack + c.health > best.attack + best.health) best = c;
  }
  return best;
}

/// 法术 / 武器效果注册表与规则
class SpellSystem {
  SpellSystem._();

  static const Card _t1 = Card(
    id: 't1', name: '铁骑', type: CardType.minion, cost: 0,
    attack: 3, health: 3, maxHealth: 3, description: '',
    owner: CardOwner.neutral, rarity: Rarity.common,
  );
  static const Card _t2 = Card(
    id: 't2', name: '法吏', type: CardType.minion, cost: 0,
    attack: 2, health: 2, maxHealth: 2, description: '',
    owner: CardOwner.neutral, rarity: Rarity.common,
  );
  static const Card _t3 = Card(
    id: 't3', name: '孝子', type: CardType.minion, cost: 0,
    attack: 1, health: 1, maxHealth: 1, description: '',
    owner: CardOwner.neutral, rarity: Rarity.common,
  );
  static const Card _t4 = Card(
    id: 't4', name: '援兵', type: CardType.minion, cost: 0,
    attack: 2, health: 2, maxHealth: 2, description: '',
    owner: CardOwner.neutral, rarity: Rarity.common,
  );

  static List<Card> get _allPool => getAllCards();
  static List<Card> get _spellPool =>
      getAllCards().where((c) => c.type == CardType.spell).toList();

  /// 法术牌 id -> 效果
  static final Map<String, CardEffect> _spellEffects = {
    // 兵家
    'B013': const BuffMinionEffect(addKeywords: [Keyword.taunt]),
    'B014': const PendingDeathEffect(),
    'B015': const BuffMinionEffect(atk: 4, def: 4),
    'B016': const SummonCopiesEffect(_t1, 2),
    'B017': const BetrayEffect(),
    'B018': const AoeDamageEffect(2),
    'B019': const BuffStrongestEffect(def: 4, addKeywords: [Keyword.divineShield]),
    'B020': const DestroyHighestAttackEffect(),
    // 法家
    'F013': const SwapStatsEffect(),
    'F014': const AoeDamageEffect(3),
    'F015': const SilenceAndFreezeEffect(),
    'F016': const SummonCopiesEffect(_t2, 3),
    'F017': const AdjacentDestroyEffect(),
    'F018': const ComboEffect([
      BuffMinionEffect(atk: 2, def: 1),
      DrawOneDeckEffect(),
    ]),
    'F019': DestroyAllEffect(condition: _oddCost),
    'F020': const SetAllStatsEffect(3, 3),
    // 儒家
    'R013': const HealAllFriendlyEffect(6),
    'R014': const BuffAllEffect(atk: 1, def: 1),
    'R015': const SilenceAllEffect(),
    'R016': const SummonCopiesEffect(_t3, 3),
    'R017': const SetTargetAttackEffect(1),
    'R018': const DrawBuffIfMinionEffect(3, 2, 2),
    'R019': const DrawOneDeckEffect(),
    'R020': const BuffStrongestEffect(atk: 3, def: 3),
    // 道家
    'D013': const HealTargetEffect(4),
    'D014': const BuffAllEffect(atk: 2, def: 2),
    'D015': const HealAllFriendlyEffect(8),
    'D016': const HeroImmuneEffect(2),
    'D017': const FreezeAllEffect(),
    'D018': const BuffMinionEffect(atk: 2, def: 2, addKeywords: [Keyword.divineShield]),
    'D019': const BuffMinionEffect(atk: 5, def: 5),
    'D020': const SwapStatsEffect(),
    // 墨家
    'M013': const HealTargetEffect(5),
    'M014': const BuffMinionEffect(atk: 3, def: 3, addKeywords: [Keyword.taunt]),
    'M015': const ProtectRoleEffect(),
    'M016': const BuffAllEffect(atk: 2, def: 2),
    'M017': const FreezeAllEffect(),
    'M018': const BuffAllEffect(atk: 1, def: 1, addKeywords: [Keyword.divineShield]),
    'M019': const DamageRandomEnemyMinionEffect(4),
    'M020': const HealAllFriendlyEffect(4),
    // 阴阳家
    'Y013': const BuffMinionEffect(atk: 2, def: 2),
    'Y014': const DestroyAllEffect(side: EffSide.all),
    'Y015': const RandomFiveElementEffect(3),
    'Y016': DiscoverEffect(_spellPool),
    'Y017': const SwapStatsEffect(),
    'Y018': const BuffStrongestEffect(atk: 1, def: 1, side: EffSide.enemy),
    'Y019': const DamageMinionEffect(4),
    'Y020': const BuffMinionEffect(atk: 2, def: 2, addKeywords: [Keyword.poisonous]),
    // 纵横家
    'Z013': const ComboEffect([DrawOneDeckEffect(), GainManaCrystalEffect()]),
    'Z014': const BuffAllEffect(atk: -1, def: -1, side: EffSide.enemy),
    'Z015': const ComboEffect([DamageEnemyHeroEffect(3), DrawOneDeckEffect()]),
    'Z016': DiscoverEffect(_allPool),
    'Z017': const DrawDiscardEffect(),
    'Z018': const BetrayEffect(),
    'Z019': const HeroImmuneEffect(1),
    'Z020': const ReturnToHandEffect(),
    // 中立
    'N029': const ComboEffect([DrawOneDeckEffect(), DrawOneDeckEffect()]),
    'N030': const AoeDamageEffect(1),
    'N031': DiscoverEffect(_allPool),
    'N032': const BuffAllEffect(def: 2),
    'N033': const DamageMinionEffect(4),
    'N034': const DamageEnemyHeroEffect(3),
    'N035': const SummonCopiesEffect(_t4, 2),
    'N036': const ComboEffect([
      DrawOneDeckEffect(), DrawOneDeckEffect(), DrawOneDeckEffect(),
    ]),
    'N037': const AoeDamageEffect(5),
    'N038': const BuffMinionEffect(atk: 3, def: 3, addKeywords: [Keyword.taunt]),
  };

  /// 无需选目标的法术（含随机目标与自动选最强）
  static const Set<String> _autoTargetIds = {
    'B014', 'B016', 'B018', 'B019', 'B020',
    'F014', 'F016', 'F019', 'F020',
    'R013', 'R014', 'R015', 'R016', 'R018', 'R019', 'R020',
    'D014', 'D015', 'D016', 'D017',
    'M016', 'M017', 'M018', 'M019', 'M020',
    'Y014', 'Y015', 'Y016', 'Y017', 'Y018',
    'Z013', 'Z014', 'Z015', 'Z016', 'Z017', 'Z019',
    'N029', 'N030', 'N031', 'N032', 'N034', 'N035', 'N036', 'N037',
  };

  /// 需要选目标的法术规则
  static final Map<String, SpellRule> _targetRules = {
    'B013': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'B015': SpellRule(
      targetKind: SpellTargetKind.friendlyMinion,
      condition: _damagedMinionExists,
    ),
    'B017': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'F013': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'F015': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'F017': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'F018': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'R017': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'D013': const SpellRule(targetKind: SpellTargetKind.friendlyRole),
    'D018': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'D019': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'D020': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'M013': const SpellRule(targetKind: SpellTargetKind.friendlyRole),
    'M014': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'M015': const SpellRule(targetKind: SpellTargetKind.friendlyRole),
    'Y013': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'Y019': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'Y020': const SpellRule(targetKind: SpellTargetKind.friendlyMinion),
    'Z018': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'Z020': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'N033': const SpellRule(targetKind: SpellTargetKind.enemyMinion),
    'N038': const SpellRule(targetKind: SpellTargetKind.anyMinion),
  };

  /// 武器 id -> 佩戴时效果（无战吼关键字的武器）
  static final Map<String, CardEffect> _weaponEquipEffects = {
    'BW001': const DamageRandomEnemyMinionEffect(1),
    'FW001': const SilenceRandomEnemyEffect(),
    'FW002': const GainArmorEffect(2),
    'RW001': const HealSelfHeroEffect(3),
    'RW002': const BuffAllEffect(atk: 1, def: 1),
    'DW001': const AdjustRandomEnemyEffect(-2, 0),
    'MW001': const DamageRandomEnemyMinionEffect(2),
    'MW002': DiscoverEffect(_spellPool),
    'YW001': const RandomFiveElementEffect(1),
    'YW002': const ComboEffect([DrawOneDeckEffect(), DrawOneDeckEffect()]),
    'ZW001': const DrawOneDeckEffect(),
    'ZW002': const BuffStrongestEffect(atk: 2, def: 2),
    'NW003': const RandomDestroyEffect(),
  };

  /// 武器 id -> 学派共振效果（英雄与武器同门且非中立）
  static final Map<String, CardEffect> _weaponResonance = {
    'BW001': const BuffWeaponEffect(1),
    'BW002': const BuffWeaponEffect(1),
    'BW003': const BuffWeaponEffect(1),
    'FW001': const BuffWeaponEffect(1),
    'FW002': const GainArmorEffect(2),
    'RW001': const BuffWeaponEffect(1),
    'RW002': const BuffWeaponEffect(1),
    'DW001': const BuffWeaponEffect(1),
    'DW002': const GainArmorEffect(2),
    'MW001': const BuffWeaponEffect(1),
    'MW002': const BuffWeaponEffect(1),
    'YW001': const BuffWeaponEffect(1),
    'YW002': const GainArmorEffect(2),
    'ZW001': const BuffWeaponEffect(1),
    'ZW002': const BuffWeaponEffect(1),
  };

  static bool _oddCost(Card c) => c.cost.isOdd;

  static CardEffect? effectFor(String id) => _spellEffects[id];

  static SpellRule? ruleFor(String id) {
    if (_autoTargetIds.contains(id)) {
      return SpellRule(targetKind: SpellTargetKind.none, condition: _condFor(id));
    }
    return _targetRules[id];
  }

  static bool Function(GameState, Player)? _condFor(String id) =>
      id == 'B015' ? _damagedMinionExists : null;

  static CardEffect? weaponEffectFor(String id) => _weaponEquipEffects[id];
  static CardEffect? resonanceFor(String id) => _weaponResonance[id];

  /// 法术是否可打出（费用与条件）
  static bool canPlay(GameState state, Player player, Card card) {
    if (player.mana < card.cost) return false;
    final rule = ruleFor(card.id);
    final cond = rule?.condition;
    if (cond != null && !cond(state, player)) return false;
    return true;
  }

  /// 目标选项（UI 高亮）
  static List<String> validTargets(GameState state, Player player, Card card) {
    final rule = ruleFor(card.id);
    if (rule == null || !rule.needsTarget) return const [];
    return rule.targetOptions(state, player);
  }

  /// 执行法术（调用方已扣除费用并校验）
  static GameState executeSpell(GameState state, String playerId, Card card, String? targetId) {
    final effect = effectFor(card.id);
    if (effect == null) return state;
    final caster = state.getCurrentPlayer(playerId);
    final rule = ruleFor(card.id);
    if (rule != null && rule.needsTarget) {
      if (!rule.validTarget(state, caster, targetId)) return state;
    }
    return effect.execute(state, playerId, targetId);
  }

  /// AI 自动选目标
  static String? autoTarget(GameState state, Player caster, Card card) {
    final rule = ruleFor(card.id);
    if (rule == null || !rule.needsTarget) return null;
    switch (rule.targetKind) {
      case SpellTargetKind.friendlyMinion:
        if (caster.board.isEmpty) return null;
        return _bestMinion(caster.board).id;
      case SpellTargetKind.enemyMinion:
        if (state.opponent.board.isEmpty) return null;
        return _bestMinion(state.opponent.board).id;
      case SpellTargetKind.anyMinion:
        final all = [...caster.board, ...state.opponent.board];
        if (all.isEmpty) return null;
        return _bestMinion(all).id;
      case SpellTargetKind.friendlyRole:
        if (caster.board.isNotEmpty && caster.health >= 30) {
          return _bestMinion(caster.board).id;
        }
        return 'hero_${caster.id}';
      case SpellTargetKind.none:
      case SpellTargetKind.randomEnemyMinion:
        return null;
    }
  }

  /// 执行武器佩戴效果（战吼关键字或佩戴效果），并应用学派共振
  static GameState executeWeaponEquip(GameState state, String playerId, Card card) {
    var current = state;
    if (card.hasBattlecry) {
      current = EffectExecutor().executeBattlecry(current, playerId, card, null);
    } else {
      final equip = weaponEffectFor(card.id);
      if (equip != null) current = equip.execute(current, playerId, null);
    }
    final p = current.getCurrentPlayer(playerId);
    if (p.hero.owner != CardOwner.neutral && p.hero.owner == card.owner) {
      final res = resonanceFor(card.id);
      if (res != null) current = res.execute(current, playerId, null);
    }
    return current;
  }
}