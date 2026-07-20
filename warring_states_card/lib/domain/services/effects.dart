import '../models/models.dart';
import 'game_rules.dart';

/// 卡牌效果接口
abstract class CardEffect {
  String get name;
  GameState execute(GameState state, String playerId, String? targetId);
}

/// 造成伤害效果
class DamageEffect implements CardEffect {
  
  const DamageEffect(this.damage, {this.targetHero = false});
  final int damage;
  final bool targetHero;
  
  @override
  String get name => '造成$damage点伤害';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final opponent = state.opponent;
    final caster = state.getCurrentPlayer(playerId);
    final totalDamage = damage + caster.spellPower;
    
    if (targetHero || targetId == null) {
      final totalDmg = damage + caster.spellPower;
      // 装甲先吸收
      var newArmor = opponent.armor;
      var newHealth = opponent.health;
      if (newArmor >= totalDmg) {
        newArmor -= totalDmg;
      } else {
        newHealth -= (totalDmg - newArmor);
        newArmor = 0;
      }
      final newOpponent = opponent.copyWith(
        health: newHealth, armor: newArmor,
      );
      return state.updatePlayer(newOpponent);
    }
    
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final targetCard = opponent.board[targetIndex];
    final newHealth = targetCard.health - totalDamage;
    
    final newBoard = List<Card>.from(opponent.board);
    if (newHealth <= 0) {
      newBoard.removeAt(targetIndex);
    } else {
      newBoard[targetIndex] = targetCard.copyWith(health: newHealth);
    }
    
    return state.updatePlayer(opponent.copyWith(board: newBoard));
  }
}

/// 恢复生命效果
class HealEffect implements CardEffect {
  
  const HealEffect(this.healAmount);
  final int healAmount;
  
  @override
  String get name => '恢复$healAmount点生命';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    // 治疗可以超过初始生命值，但不超过初始生命值+10的上限
    const maxHealth = GameRules.initialHealth + 10;
    final newHealth = (player.health + healAmount).clamp(0, maxHealth);
    return state.updatePlayer(player.copyWith(health: newHealth));
  }
}

/// 抽牌效果
class DrawCardsEffect implements CardEffect {
  
  const DrawCardsEffect(this.cardCount);
  final int cardCount;
  
  @override
  String get name => '抽$cardCount张牌';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    
    if (player.deckCount < cardCount) return state;
    
    final newDeck = List<Card>.from(player.deck);
    final drawnCards = newDeck.take(cardCount).toList();
    final remainingDeck = newDeck.skip(cardCount).toList();
    
    final newHand = [...player.hand, ...drawnCards];
    
    return state.updatePlayer(player.copyWith(
      deck: remainingDeck,
      hand: newHand,
    ));
  }
}

/// 召唤随从效果
class SummonEffect implements CardEffect {
  
  const SummonEffect(this.cardToSummon);
  final Card cardToSummon;
  
  @override
  String get name => '召唤${cardToSummon.name}';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    
    if (player.isBoardFull) return state;
    
    final summonedCard = cardToSummon.copyWith(
      id: '${cardToSummon.id}_summon_${DateTime.now().microsecondsSinceEpoch}',
    );
    
    final newBoard = [...player.board, summonedCard];
    return state.updatePlayer(player.copyWith(board: newBoard));
  }
}

/// 获得护甲效果
class GainArmorEffect implements CardEffect {
  
  const GainArmorEffect(this.armorAmount);
  final int armorAmount;
  
  @override
  String get name => '获得$armorAmount点护甲';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    final newArmor = player.armor + armorAmount;
    return state.updatePlayer(player.copyWith(armor: newArmor));
  }
}

/// 抽排废弃效果(弃掉手牌)
class DiscardEffect implements CardEffect {
  
  const DiscardEffect(this.discardCount);
  final int discardCount;
  
  @override
  String get name => '弃掉$discardCount张手牌';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    
    if (player.handCount <= discardCount) {
      return state.updatePlayer(player.copyWith(hand: []));
    }
    
    final newHand = List<Card>.from(player.hand)..removeRange(0, discardCount);
    return state.updatePlayer(player.copyWith(hand: newHand));
  }
}

/// buff属性效果
class BuffEffect implements CardEffect {
  
  const BuffEffect({
    this.attackBonus = 0,
    this.healthBonus = 0,
    this.toSelf = false,
  });
  final int attackBonus;
  final int healthBonus;
  final bool toSelf;
  
  @override
  String get name => '获得+$attackBonus/+$healthBonus';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    
    if (toSelf && targetId == null) {
      final newBoard = player.board.map((card) => card.copyWith(
        attack: card.attack + attackBonus,
        health: card.health + healthBonus,
      )).toList();
      return state.updatePlayer(player.copyWith(board: newBoard));
    }
    
    if (targetId == null) return state;
    
    final targetIndex = player.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final targetCard = player.board[targetIndex];
    final newBoard = List<Card>.from(player.board);
    newBoard[targetIndex] = targetCard.copyWith(
      attack: targetCard.attack + attackBonus,
      health: targetCard.health + healthBonus,
    );
    
    return state.updatePlayer(player.copyWith(board: newBoard));
  }
}

/// 沉默效果
class SilenceEffect implements CardEffect {
  @override
  String get name => '沉默';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    
    final opponent = state.opponent;
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final targetCard = opponent.board[targetIndex];
    final newBoard = List<Card>.from(opponent.board);
    newBoard[targetIndex] = targetCard.copyWith(keywords: []);
    
    return state.updatePlayer(opponent.copyWith(board: newBoard));
  }
}

/// 变形效果
class TransformEffect implements CardEffect {
  
  const TransformEffect(this.transformation);
  final Card transformation;
  
  @override
  String get name => '变成${transformation.name}';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final opponent = state.opponent;
    
    if (targetId == null) return state;
    
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final newBoard = List<Card>.from(opponent.board);
    newBoard[targetIndex] = transformation.copyWith(
      id: targetId,
    );
    
    return state.updatePlayer(opponent.copyWith(board: newBoard));
  }
}

/// 复制效果
class CopyEffect implements CardEffect {
  
  const CopyEffect({this.toHand = true});
  final bool toHand;
  
  @override
  String get name => toHand ? '复制到手牌' : '复制到战场';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    
    final opponent = state.opponent;
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final player = state.getCurrentPlayer(playerId);
    final targetCard = opponent.board[targetIndex];
    
    if (toHand) {
      if (player.handCount >= GameRules.maxHandSize) return state;
      final newHand = [...player.hand, targetCard];
      return state.updatePlayer(player.copyWith(hand: newHand));
    } else {
      if (player.isBoardFull) return state;
      final newBoard = [...player.board, targetCard.copyWith(
        id: '${targetCard.id}_copy_${DateTime.now().microsecondsSinceEpoch}',
      )];
      return state.updatePlayer(player.copyWith(board: newBoard));
    }
  }
}

/// 消灭效果
class DestroyEffect implements CardEffect {
  @override
  String get name => '消灭';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    if (targetId == null) return state;
    
    final opponent = state.opponent;
    final newBoard = opponent.board.where((c) => c.id != targetId).toList();
    
    return state.updatePlayer(opponent.copyWith(board: newBoard));
  }
}

/// 法术增强效果(使法术获得额外效果)
class SpellPowerEffect implements CardEffect {
  
  const SpellPowerEffect(this.powerBonus, {this.toSelf = false});
  final int powerBonus;
  final bool toSelf;
  
  @override
  String get name => '法术伤害+$powerBonus';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    final newSpellPower = player.spellPower + powerBonus;
    return state.updatePlayer(player.copyWith(spellPower: newSpellPower));
  }
}

/// 武器效果
class WeaponEffect implements CardEffect {
  
  const WeaponEffect(this.attack, this.durability);
  final int attack;
  final int durability;
  
  @override
  String get name => '获得$attack/$durability武器';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final player = state.getCurrentPlayer(playerId);
    final weapon = Card(
      id: 'weapon_${DateTime.now().microsecondsSinceEpoch}',
      name: '武器',
      type: CardType.weapon,
      cost: 0,
      attack: attack,
      health: durability,
      description: '',
      owner: player.hero.className == 'bingjia' 
        ? CardOwner.bingjia 
        : CardOwner.neutral,
      rarity: Rarity.common,
    );
    
    return state.updatePlayer(player.copyWith(weapon: weapon));
  }
}

/// 随机效果
class RandomEffect implements CardEffect {
  
  const RandomEffect(this.possibleEffects, {this.selectCount = 1});
  final List<CardEffect> possibleEffects;
  final int selectCount;
  
  @override
  String get name => '随机$selectCount个效果';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var currentState = state;
    
    for (int i = 0; i < selectCount; i++) {
      final effect = possibleEffects[i % possibleEffects.length];
      currentState = effect.execute(currentState, playerId, targetId);
    }
    
    return currentState;
  }
}

/// 条件触发效果
class ConditionalEffect implements CardEffect {
  
  const ConditionalEffect({
    required this.condition,
    required this.trueEffect,
    required this.falseEffect,
  });
  final bool Function(GameState, String) condition;
  final CardEffect trueEffect;
  final CardEffect falseEffect;
  
  @override
  String get name => '条件效果';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    final effect = condition(state, playerId) ? trueEffect : falseEffect;
    return effect.execute(state, playerId, targetId);
  }
}

/// 组合效果(多个效果组合)
class ComboEffect implements CardEffect {
  
  const ComboEffect(this.effects);
  final List<CardEffect> effects;
  
  @override
  String get name => '组合效果(${effects.length}个)';
  
  @override
  GameState execute(GameState state, String playerId, String? targetId) {
    var currentState = state;
    
    for (final effect in effects) {
      currentState = effect.execute(currentState, playerId, targetId);
    }
    
    return currentState;
  }
}