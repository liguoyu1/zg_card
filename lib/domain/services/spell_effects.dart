import 'dart:math';

import '../models/models.dart';
import 'effects.dart';
import 'game_rules.dart';

/// 效果作用方
enum EffSide { self, enemy, all }

Player _playerFor(GameState s, String pid, EffSide side) =>
    side == EffSide.enemy ? s.opponent : s.getCurrentPlayer(pid);

Iterable<EffSide> _sides(EffSide side) =>
    side == EffSide.all ? [EffSide.self, EffSide.enemy] : [side];

int _n() => DateTime.now().microsecondsSinceEpoch;

/// 对单个随从造成伤害（吃法术强度）
class DamageMinionEffect implements CardEffect {
  const DamageMinionEffect(this.damage, {this.side = EffSide.enemy});
  final int damage;
  final EffSide side;
  @override
  String get name => '造成$damage点伤害';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final total = damage + state.getCurrentPlayer(playerId).spellPower;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    if (card.health - total <= 0) {
      final board = List<Card>.from(owner.board)..removeAt(idx);
      return state.updatePlayer(owner.copyWith(board: board));
    }
    final board = List<Card>.from(owner.board);
    board[idx] = card.copyWith(health: card.health - total);
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 对敌方所有随从造成伤害（吃法术强度）
class AoeDamageEffect implements CardEffect {
  const AoeDamageEffect(this.damage);
  final int damage;
  @override
  String get name => '对敌方所有随从造成$damage点伤害';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final total = damage + state.getCurrentPlayer(playerId).spellPower;
    final enemy = state.opponent;
    final board = enemy.board
        .map((c) => c.copyWith(health: c.health - total))
        .where((c) => c.health > 0)
        .toList();
    return state.updatePlayer(enemy.copyWith(board: board));
  }
}

/// 对敌方英雄造成伤害（护甲先吸收，尊重免疫）
class DamageEnemyHeroEffect implements CardEffect {
  const DamageEnemyHeroEffect(this.damage);
  final int damage;
  @override
  String get name => '对敌方英雄造成$damage点伤害';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final opp = state.opponent;
    if (opp.heroImmuneTurns > 0) return state;
    final total = damage + state.getCurrentPlayer(playerId).spellPower;
    var armor = opp.armor;
    var health = opp.health;
    if (armor >= total) {
      armor -= total;
    } else {
      health -= (total - armor);
      armor = 0;
    }
    return state.updatePlayer(opp.copyWith(armor: armor, health: health));
  }
}

/// 对一随机敌方随从造成伤害（无随从则打英雄）
class DamageRandomEnemyMinionEffect implements CardEffect {
  const DamageRandomEnemyMinionEffect(this.damage, {this.spellPower = false});
  final int damage;
  final bool spellPower;
  @override
  String get name => '随机造成$damage点伤害';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final enemy = state.opponent;
    if (enemy.board.isEmpty) {
      return DamageEnemyHeroEffect(damage).execute(state, playerId, null);
    }
    final victim = enemy.board[Random().nextInt(enemy.board.length)];
    return DamageMinionEffect(damage).execute(state, playerId, victim.id);
  }
}

/// 造成伤害，若目标死亡则抽一张牌
class DamageDrawEffect implements CardEffect {
  const DamageDrawEffect(this.damage);
  final int damage;
  @override
  String get name => '造成$damage点伤害，若死亡则抽牌';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final before = state.opponent.board.any((c) => c.id == targetId);
    if (!before) return state;
    final after = DamageMinionEffect(damage).execute(state, playerId, targetId);
    final alive = after.opponent.board.any((c) => c.id == targetId);
    if (alive) return after;
    final player = after.getCurrentPlayer(playerId);
    if (player.deck.isEmpty) return after;
    final deck = List<Card>.from(player.deck);
    final drawn = deck.removeAt(0);
    return after.updatePlayer(player.copyWith(deck: deck, hand: [...player.hand, drawn]));
  }
}

/// 恢复单个指定角色生命
class HealTargetEffect implements CardEffect {
  const HealTargetEffect(this.heal, {this.side = EffSide.self});
  final int heal;
  final EffSide side;
  @override
  String get name => '恢复$heal点生命';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final owner = _playerFor(state, playerId, side);
    if (targetId.startsWith('hero_')) {
      return state.updatePlayer(owner.copyWith(health: min(owner.health + heal, 40)));
    }
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    final cap = card.maxHealth > 0 ? card.maxHealth : card.health + heal;
    final board = List<Card>.from(owner.board);
    board[idx] = card.copyWith(health: min(card.health + heal, cap));
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 恢复友方英雄
class HealSelfHeroEffect implements CardEffect {
  const HealSelfHeroEffect(this.heal);
  final int heal;
  @override
  String get name => '恢复$heal点生命';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    return state.updatePlayer(p.copyWith(health: min(p.health + heal, 40)));
  }
}

/// 恢复所有友方角色（英雄+随从）
class HealAllFriendlyEffect implements CardEffect {
  const HealAllFriendlyEffect(this.heal);
  final int heal;
  @override
  String get name => '恢复所有友方角色$heal点生命';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    final board = p.board
        .map((c) => c.copyWith(health: c.maxHealth > 0 ? min(c.health + heal, c.maxHealth) : c.health))
        .toList();
    return state.updatePlayer(p.copyWith(board: board, health: min(p.health + heal, 40)));
  }
}

/// 对单个随从改变属性（含关键词）
class BuffMinionEffect implements CardEffect {
  const BuffMinionEffect({
    this.atk = 0,
    this.def = 0,
    this.side = EffSide.self,
    this.addKeywords = const <Keyword>[],
  });
  final int atk;
  final int def;
  final EffSide side;
  final List<Keyword> addKeywords;
  @override
  String get name => '+$atk/+$def';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null || targetId.startsWith('hero_')) return state;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    final board = List<Card>.from(owner.board);
    board[idx] = card.copyWith(
      attack: card.attack + atk,
      health: card.health + def,
      maxHealth: card.maxHealth + def,
      keywords: {...card.keywords, ...addKeywords}.toList(),
    );
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 对一方所有随从增加属性
class BuffAllEffect implements CardEffect {
  const BuffAllEffect({
    this.atk = 0,
    this.def = 0,
    this.side = EffSide.self,
    this.addKeywords = const <Keyword>[],
  });
  final int atk;
  final int def;
  final EffSide side;
  final List<Keyword> addKeywords;
  @override
  String get name => '所有随从+$atk/+$def';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    for (final s in _sides(side)) {
      final owner = _playerFor(current, playerId, s);
      final board = owner.board
          .map((c) => c.copyWith(
                attack: c.attack + atk,
                health: c.health + def,
                maxHealth: c.maxHealth + def,
                keywords: {...c.keywords, ...addKeywords}.toList(),
              ))
          .toList();
      current = current.updatePlayer(owner.copyWith(board: board));
    }
    return current;
  }
}

/// 对一方最强随从改变属性
class BuffStrongestEffect implements CardEffect {
  const BuffStrongestEffect({
    this.atk = 0,
    this.def = 0,
    this.side = EffSide.self,
    this.addKeywords = const <Keyword>[],
  });
  final int atk;
  final int def;
  final EffSide side;
  final List<Keyword> addKeywords;
  @override
  String get name => '最强随从+$atk/+$def';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final owner = _playerFor(state, playerId, side);
    if (owner.board.isEmpty) return state;
    Card best = owner.board.first;
    for (final c in owner.board) {
      if (c.attack + c.health > best.attack + best.health) best = c;
    }
    return BuffMinionEffect(atk: atk, def: def, side: side, addKeywords: addKeywords)
        .execute(state, playerId, best.id);
  }
}

/// 对随机敌方随从改变属性
class AdjustRandomEnemyEffect implements CardEffect {
  const AdjustRandomEnemyEffect(this.atk, this.def);
  final int atk;
  final int def;
  @override
  String get name => '随机敌方随从+$atk/+$def';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final enemy = state.opponent;
    if (enemy.board.isEmpty) return state;
    final victim = enemy.board[Random().nextInt(enemy.board.length)];
    return BuffMinionEffect(atk: atk, def: def, side: EffSide.enemy).execute(state, playerId, victim.id);
  }
}

/// 将一方所有随从设为固定属性
class SetAllStatsEffect implements CardEffect {
  const SetAllStatsEffect(this.atk, this.hp, {this.side = EffSide.all});
  final int atk;
  final int hp;
  final EffSide side;
  @override
  String get name => '所有随从变为$atk/$hp';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    for (final s in _sides(side)) {
      final owner = _playerFor(current, playerId, s);
      final board = owner.board.map((c) => c.copyWith(attack: atk, health: hp, maxHealth: hp)).toList();
      current = current.updatePlayer(owner.copyWith(board: board));
    }
    return current;
  }
}

/// 将单个随从攻击设为指定值
class SetTargetAttackEffect implements CardEffect {
  const SetTargetAttackEffect(this.atk, {this.side = EffSide.enemy});
  final int atk;
  final EffSide side;
  @override
  String get name => '攻击力变为$atk';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    final board = List<Card>.from(owner.board);
    board[idx] = card.copyWith(attack: atk);
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 单个随从攻/血互换
class SwapStatsEffect implements CardEffect {
  const SwapStatsEffect({this.side = EffSide.enemy});
  final EffSide side;
  @override
  String get name => '攻击/生命互换';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    final board = List<Card>.from(owner.board);
    board[idx] = card.copyWith(attack: card.health, health: card.attack);
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 沉默单个随从并使其无法攻击
class SilenceAndFreezeEffect implements CardEffect {
  const SilenceAndFreezeEffect({this.side = EffSide.enemy});
  final EffSide side;
  @override
  String get name => '沉默并无法攻击';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    final board = List<Card>.from(owner.board);
    board[idx] = card.copyWith(keywords: const <Keyword>[], isDormant: true);
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 沉默一方所有随从
class SilenceAllEffect implements CardEffect {
  const SilenceAllEffect({this.side = EffSide.enemy});
  final EffSide side;
  @override
  String get name => '沉默所有随从';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    for (final s in _sides(side)) {
      final owner = _playerFor(current, playerId, s);
      final board = owner.board.map((c) => c.copyWith(keywords: const <Keyword>[])).toList();
      current = current.updatePlayer(owner.copyWith(board: board));
    }
    return current;
  }
}

/// 随机沉默一个敌方随从
class SilenceRandomEnemyEffect implements CardEffect {
  const SilenceRandomEnemyEffect();
  @override
  String get name => '沉默一个随从';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final enemy = state.opponent;
    if (enemy.board.isEmpty) return state;
    final victim = enemy.board[Random().nextInt(enemy.board.length)];
    final board = List<Card>.from(enemy.board);
    final idx = board.indexWhere((c) => c.id == victim.id);
    board[idx] = victim.copyWith(keywords: const <Keyword>[]);
    return state.updatePlayer(enemy.copyWith(board: board));
  }
}

/// 使一方所有随从无法攻击一回合
class FreezeAllEffect implements CardEffect {
  const FreezeAllEffect({this.side = EffSide.all});
  final EffSide side;
  @override
  String get name => '全场无法攻击一回合';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    for (final s in _sides(side)) {
      final owner = _playerFor(current, playerId, s);
      final board = owner.board.map((c) => c.copyWith(isDormant: true)).toList();
      current = current.updatePlayer(owner.copyWith(board: board));
    }
    return current;
  }
}

/// 召唤若干指定随从
class SummonCopiesEffect implements CardEffect {
  const SummonCopiesEffect(this.card, this.count);
  final Card card;
  final int count;
  @override
  String get name => '召唤$count个${card.name}';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    for (int i = 0; i < count; i++) {
      final p = current.getCurrentPlayer(playerId);
      if (p.isBoardFull) break;
      final summoned = Card(
        id: 'summon_${_n()}_$i',
        name: card.name,
        type: CardType.minion,
        cost: 0,
        attack: card.attack,
        health: card.health,
        maxHealth: card.health,
        description: '',
        keywords: card.keywords,
        owner: card.owner,
        rarity: card.rarity,
      );
      current = current.updatePlayer(p.copyWith(board: [...p.board, summoned]));
    }
    return current;
  }
}

/// 消灭一个随从
class DestroyMinionEffect implements CardEffect {
  const DestroyMinionEffect({this.side = EffSide.enemy, this.condition});
  final EffSide side;
  final bool Function(Card)? condition;
  @override
  String get name => '消灭一个随从';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = owner.board[idx];
    if (condition != null && !condition!(card)) return state;
    final board = owner.board.where((c) => c.id != targetId).toList();
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 消灭满足条件的一方随从
class DestroyAllEffect implements CardEffect {
  const DestroyAllEffect({this.side = EffSide.enemy, this.condition});
  final EffSide side;
  final bool Function(Card)? condition;
  @override
  String get name => '消灭满足条件的随从';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    for (final s in _sides(side)) {
      final owner = _playerFor(current, playerId, s);
      final cond = condition;
      final board = cond == null ? const <Card>[] : owner.board.where((c) => !cond(c)).toList();
      current = current.updatePlayer(owner.copyWith(board: board));
    }
    return current;
  }
}

/// 消灭攻击力最高的随从
class DestroyHighestAttackEffect implements CardEffect {
  const DestroyHighestAttackEffect({this.side = EffSide.enemy});
  final EffSide side;
  @override
  String get name => '消灭攻击力最高的随从';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final owner = _playerFor(state, playerId, side);
    if (owner.board.isEmpty) return state;
    Card best = owner.board.first;
    for (final c in owner.board) {
      if (c.attack > best.attack) best = c;
    }
    final board = owner.board.where((c) => c.id != best.id).toList();
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 随机消灭一个随从
class RandomDestroyEffect implements CardEffect {
  const RandomDestroyEffect({this.side = EffSide.enemy, this.condition});
  final EffSide side;
  final bool Function(Card)? condition;
  @override
  String get name => '随机消灭一个随从';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final owner = _playerFor(state, playerId, side);
    final cond = condition;
    final candidates = cond == null ? owner.board : owner.board.where(cond).toList();
    if (candidates.isEmpty) return state;
    final card = candidates[Random().nextInt(candidates.length)];
    final board = owner.board.where((c) => c.id != card.id).toList();
    return state.updatePlayer(owner.copyWith(board: board));
  }
}

/// 连坐：消灭目标，相邻随从受2伤
class AdjacentDestroyEffect implements CardEffect {
  const AdjacentDestroyEffect();
  @override
  String get name => '连坐';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final enemy = state.opponent;
    final idx = enemy.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final neighbors = <String>[];
    if (idx > 0) neighbors.add(enemy.board[idx - 1].id);
    if (idx < enemy.board.length - 1) neighbors.add(enemy.board[idx + 1].id);
    final board = <Card>[];
    for (final c in enemy.board) {
      if (c.id == targetId) continue;
      if (neighbors.contains(c.id) && c.health - 2 > 0) {
        board.add(c.copyWith(health: c.health - 2));
      } else if (neighbors.contains(c.id)) {
        continue;
      } else {
        board.add(c);
      }
    }
    return state.updatePlayer(enemy.copyWith(board: board));
  }
}

/// 将一个随从移回手牌
class ReturnToHandEffect implements CardEffect {
  const ReturnToHandEffect({this.side = EffSide.enemy});
  final EffSide side;
  @override
  String get name => '移回手牌';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final owner = _playerFor(state, playerId, side);
    final idx = owner.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    if (owner.handCount >= GameRules.maxHandSize) return state;
    final card = owner.board[idx];
    final board = List<Card>.from(owner.board)..removeAt(idx);
    final bounced = card.copyWith(
      id: '${card.id}_ret_${_n()}',
      hasAttackedThisTurn: false,
      isDormant: false,
      keywords: const <Keyword>[],
    );
    return state.updatePlayer(owner.copyWith(board: board, hand: [...owner.hand, bounced]));
  }
}

/// 使英雄免疫指定回合数
class HeroImmuneEffect implements CardEffect {
  const HeroImmuneEffect(this.turns);
  final int turns;
  @override
  String get name => '英雄免疫$turns回合';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    return state.updatePlayer(p.copyWith(heroImmuneTurns: turns));
  }
}

/// 保护一个友方角色：英雄免疫1回合；随从获得圣盾
class ProtectRoleEffect implements CardEffect {
  const ProtectRoleEffect();
  @override
  String get name => '保护';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    if (targetId.startsWith('hero_')) {
      final p = state.getCurrentPlayer(playerId);
      return state.updatePlayer(p.copyWith(heroImmuneTurns: 1));
    }
    final p = state.getCurrentPlayer(playerId);
    final idx = p.board.indexWhere((c) => c.id == targetId);
    if (idx == -1) return state;
    final card = p.board[idx];
    final board = List<Card>.from(p.board);
    board[idx] = card.copyWith(keywords: {...card.keywords, Keyword.divineShield}.toList());
    return state.updatePlayer(p.copyWith(board: board));
  }
}

/// 记录全体友方随从为下回合开始时死亡
class PendingDeathEffect implements CardEffect {
  const PendingDeathEffect();
  @override
  String get name => '下回合全体随从死亡';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    return state.updatePlayer(p.copyWith(pendingDeathIds: p.board.map((c) => c.id).toList()));
  }
}

/// 目标反戈：攻击友方随从（或友方英雄）
class BetrayEffect implements CardEffect {
  const BetrayEffect();
  @override
  String get name => '攻击错误目标';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    final enemy = state.opponent;
    final eIdx = enemy.board.indexWhere((c) => c.id == targetId);
    if (eIdx == -1) return state;
    final traitor = enemy.board[eIdx];
    final caster = state.getCurrentPlayer(playerId);
    final enemyBoard = List<Card>.from(enemy.board);
    enemyBoard[eIdx] = traitor.copyWith(hasAttackedThisTurn: true);
    if (caster.board.isEmpty) {
      if (caster.heroImmuneTurns > 0) return state;
      return state
          .updatePlayer(enemy.copyWith(board: enemyBoard))
          .updatePlayer(caster.copyWith(health: caster.health - traitor.attack));
    }
    final victim = caster.board[Random().nextInt(caster.board.length)];
    var casterBoard = List<Card>.from(caster.board);
    final vIdx = casterBoard.indexWhere((c) => c.id == victim.id);
    if (victim.health - traitor.attack <= 0) {
      casterBoard.removeAt(vIdx);
    } else {
      casterBoard[vIdx] = victim.copyWith(health: victim.health - traitor.attack);
    }
    return state
        .updatePlayer(enemy.copyWith(board: enemyBoard))
        .updatePlayer(caster.copyWith(board: casterBoard));
  }
}

/// 随机五行法术
class RandomFiveElementEffect implements CardEffect {
  const RandomFiveElementEffect(this.count);
  final int count;
  @override
  String get name => '随机五行法术';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var current = state;
    final pool = <CardEffect>[
      const DamageRandomEnemyMinionEffect(2),
      const HealTargetEffect(2, side: EffSide.self),
      const DrawOneDeckEffect(),
      const GainArmorEffect(2),
      const AdjustRandomEnemyEffect(-1, 0),
    ];
    for (int i = 0; i < count; i++) {
      current = pool[Random().nextInt(pool.length)].execute(current, playerId, null);
    }
    return current;
  }
}

/// 抽一张牌
class DrawOneDeckEffect implements CardEffect {
  const DrawOneDeckEffect();
  @override
  String get name => '抽一张牌';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    if (p.deck.isEmpty) return state;
    final deck = List<Card>.from(p.deck);
    final drawn = deck.removeAt(0);
    return state.updatePlayer(p.copyWith(deck: deck, hand: [...p.hand, drawn]));
  }
}

/// 从指定池随机发现牌加入手牌
class DiscoverEffect implements CardEffect {
  const DiscoverEffect(this.pool, {this.count = 1});
  final List<Card> pool;
  final int count;
  @override
  String get name => '发现牌';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (pool.isEmpty) return state;
    var current = state;
    for (int i = 0; i < count; i++) {
      final p = current.getCurrentPlayer(playerId);
      if (p.handCount >= GameRules.maxHandSize) break;
      final c = pool[Random().nextInt(pool.length)];
      current = current.updatePlayer(p.copyWith(hand: [...p.hand, c]));
    }
    return current;
  }
}

/// 抽牌，若为随从则加属性
class DrawBuffIfMinionEffect implements CardEffect {
  const DrawBuffIfMinionEffect(this.draw, this.atk, this.def);
  final int draw;
  final int atk;
  final int def;
  @override
  String get name => '抽$draw张，随从+$atk/+$def';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    if (p.deck.isEmpty) return state;
    final deck = List<Card>.from(p.deck);
    final drawn = deck.take(draw).toList();
    final rest = deck.skip(draw).toList();
    var hand = [...p.hand, ...drawn];
    if (hand.length > GameRules.maxHandSize) {
      hand = hand.sublist(hand.length - GameRules.maxHandSize);
    }
    var current = state.updatePlayer(p.copyWith(deck: rest, hand: hand));
    for (final c in drawn.where((c) => c.isMinion)) {
      final p2 = current.getCurrentPlayer(playerId);
      final idx = p2.hand.indexWhere((h) => h.id == c.id);
      if (idx >= 0) {
        final h = List<Card>.from(p2.hand);
        h[idx] = c.copyWith(attack: c.attack + atk, health: c.health + def);
        current = current.updatePlayer(p2.copyWith(hand: h));
      }
    }
    return current;
  }
}

/// 抽两张弃一张
class DrawDiscardEffect implements CardEffect {
  const DrawDiscardEffect();
  @override
  String get name => '抽两张，弃一张';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    if (p.deck.length < 2) return state;
    final deck = List<Card>.from(p.deck);
    final drawn = deck.take(2).toList();
    final rest = deck.skip(2).toList();
    final hand = [...p.hand, ...drawn];
    final idx = Random().nextInt(hand.length);
    final hand2 = List<Card>.from(hand)..removeAt(idx);
    return state.updatePlayer(p.copyWith(deck: rest, hand: hand2));
  }
}

/// 武器攻击+指定值
class BuffWeaponEffect implements CardEffect {
  const BuffWeaponEffect(this.atk);
  final int atk;
  @override
  String get name => '武器攻击+$atk';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    final w = p.weapon;
    if (w == null) return state;
    return state.updatePlayer(p.copyWith(weapon: w.copyWith(attack: w.attack + atk)));
  }
}

/// 获得一个法力水晶
class GainManaCrystalEffect implements CardEffect {
  const GainManaCrystalEffect();
  @override
  String get name => '获得一个法力水晶';
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final p = state.getCurrentPlayer(playerId);
    final newMax = (p.maxMana + 1).clamp(0, GameRules.maxMana);
    return state.updatePlayer(p.copyWith(maxMana: newMax, mana: p.mana + 1));
  }
}