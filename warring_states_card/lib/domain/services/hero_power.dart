import '../models/models.dart';

/// 英雄技能效果接口
abstract class HeroPowerEffect {
  /// 应用英雄技能
  GameState apply(GameState state, String playerId, {String? targetId});
  
  /// 获取技能名称
  String get name;
  
  /// 获取技能描述
  String get description;
}

/// 英雄技能工厂
class HeroPowerFactory {
  static HeroPowerEffect create(SkillType type) {
    switch (type) {
      case SkillType.defensive:
        return DefensivePower();
      case SkillType.buff:
        return BuffPower();
      case SkillType.control:
        return ControlPower();
      case SkillType.summon:
        return SummonPower();
      case SkillType.random:
        return RandomPower();
      case SkillType.draw:
        return DrawPower();
      case SkillType.heal:
        return HealPower();
      case SkillType.debuff:
        return DebuffPower();
    }
  }
}

/// 防御型技能：+2护甲
class DefensivePower implements HeroPowerEffect {
  @override
  String get name => '铁壁';
  @override
  String get description => '使英雄获得2点护甲';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final player = state.getCurrentPlayer(playerId);
    final updatedPlayer = player.copyWith(
      armor: player.armor + 2,
      mana: player.mana - 2,
    );
    return state.updatePlayer(updatedPlayer);
  }
}

/// 增益型技能：+1攻击Buff
class BuffPower implements HeroPowerEffect {
  @override
  String get name => '激励';
  @override
  String get description => '使一个友方随从获得+1/+1';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final player = state.getCurrentPlayer(playerId);
    
    if (targetId == null || player.board.isEmpty) {
      // 没选目标，buff第一个随从
      if (player.board.isEmpty) return state;
      final target = player.board.first;
      final buffed = target.copyWith(
        attack: target.attack + 1,
        health: target.health + 1,
      );
      final newBoard = player.board.map((c) => c.id == target.id ? buffed : c).toList();
      final updatedPlayer = player.copyWith(
        board: newBoard,
        mana: player.mana - 2,
      );
      return state.updatePlayer(updatedPlayer);
    }
    
    final targetIndex = player.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final target = player.board[targetIndex];
    final buffed = target.copyWith(
      attack: target.attack + 1,
      health: target.health + 1,
    );
    final newBoard = List<Card>.from(player.board);
    newBoard[targetIndex] = buffed;
    
    final updatedPlayer = player.copyWith(
      board: newBoard,
      mana: player.mana - 2,
    );
    return state.updatePlayer(updatedPlayer);
  }
}

/// 控制型技能：沉默一个敌方随从
class ControlPower implements HeroPowerEffect {
  @override
  String get name => '压制';
  @override
  String get description => '沉默一个敌方随从';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final opponent = state.opponent;
    
    if (opponent.board.isEmpty) return state;
    
    // 默认沉默第一个
    String target = targetId ?? opponent.board.first.id;
    final targetIndex = opponent.board.indexWhere((c) => c.id == target);
    if (targetIndex == -1) return state;
    
    final targetCard = opponent.board[targetIndex];
    final silenced = targetCard.copyWith(keywords: []);
    final newBoard = List<Card>.from(opponent.board);
    newBoard[targetIndex] = silenced;
    
    final player = state.getCurrentPlayer(playerId);
    final updatedPlayer = player.copyWith(mana: player.mana - 2);
    final updatedOpponent = opponent.copyWith(board: newBoard);
    
    return state.updatePlayer(updatedPlayer).updatePlayer(updatedOpponent);
  }
}

/// 召唤型技能：召唤一个1/1随从
class SummonPower implements HeroPowerEffect {
  @override
  String get name => '召集';
  @override
  String get description => '召唤一个1/1的士兵';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final player = state.getCurrentPlayer(playerId);
    
    if (player.boardCount >= 7) return state;
    
    final soldier = Card(
      id: 'soldier_${DateTime.now().millisecondsSinceEpoch}',
      name: '士兵',
      type: CardType.minion,
      cost: 1,
      attack: 1,
      health: 1,
      owner: player.hero.owner,
      description: '英雄技能召唤',
      rarity: Rarity.common,
    );
    
    final updatedPlayer = player.copyWith(
      board: [...player.board, soldier],
      mana: player.mana - 2,
    );
    return state.updatePlayer(updatedPlayer);
  }
}

/// 随机型技能：造成1-2点随机伤害
class RandomPower implements HeroPowerEffect {
  @override
  String get name => '暗算';
  @override
  String get description => '对一个随机敌方随从造成1-2点伤害';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final opponent = state.opponent;
    if (opponent.board.isEmpty) return state;
    
    // 随机选一个随从
    final randomIndex = DateTime.now().millisecond % opponent.board.length;
    final target = opponent.board[randomIndex];
    final damage = 1 + (DateTime.now().millisecond % 2); // 1-2点伤害
    
    final newHealth = target.health - damage;
    final newBoard = List<Card>.from(opponent.board);
    
    if (newHealth <= 0) {
      newBoard.removeAt(randomIndex);
    } else {
      newBoard[randomIndex] = target.copyWith(health: newHealth);
    }
    
    final player = state.getCurrentPlayer(playerId);
    final updatedPlayer = player.copyWith(mana: player.mana - 2);
    final updatedOpponent = opponent.copyWith(board: newBoard);
    
    return state.updatePlayer(updatedPlayer).updatePlayer(updatedOpponent);
  }
}

/// 抽牌型技能：抽一张牌
class DrawPower implements HeroPowerEffect {
  @override
  String get name => '研读';
  @override
  String get description => '抽一张牌';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final player = state.getCurrentPlayer(playerId);
    
    if (player.deck.isEmpty) return state;
    
    final drawnCard = player.deck.first;
    final newDeck = player.deck.sublist(1);
    
    // 手牌已满则抽不到
    if (player.handCount >= 10) {
      final updatedPlayer = player.copyWith(
        deck: newDeck,
        mana: player.mana - 2,
      );
      return state.updatePlayer(updatedPlayer);
    }
    
    final updatedPlayer = player.copyWith(
      hand: [...player.hand, drawnCard],
      deck: newDeck,
      mana: player.mana - 2,
    );
    return state.updatePlayer(updatedPlayer);
  }
}

/// 治疗型技能：治疗2点生命
class HealPower implements HeroPowerEffect {
  @override
  String get name => '疗伤';
  @override
  String get description => '恢复2点生命值';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final player = state.getCurrentPlayer(playerId);
    final healedHealth = player.health + 2;
    
    final updatedPlayer = player.copyWith(
      health: healedHealth,
      mana: player.mana - 2,
    );
    return state.updatePlayer(updatedPlayer);
  }
}

/// 减益型技能：造成1点伤害
class DebuffPower implements HeroPowerEffect {
  @override
  String get name => '中伤';
  @override
  String get description => '对一个敌方随从造成1点伤害';
  
  @override
  GameState apply(GameState state, String playerId, {String? targetId}) {
    final opponent = state.opponent;
    
    if (opponent.board.isEmpty) return state;
    
    final targetIdToUse = targetId ?? opponent.board.first.id;
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetIdToUse);
    if (targetIndex == -1) return state;
    
    final target = opponent.board[targetIndex];
    final newHealth = target.health - 1;
    final newBoard = List<Card>.from(opponent.board);
    
    if (newHealth <= 0) {
      newBoard.removeAt(targetIndex);
    } else {
      newBoard[targetIndex] = target.copyWith(health: newHealth);
    }
    
    final player = state.getCurrentPlayer(playerId);
    final updatedPlayer = player.copyWith(mana: player.mana - 2);
    final updatedOpponent = opponent.copyWith(board: newBoard);
    
    return state.updatePlayer(updatedPlayer).updatePlayer(updatedOpponent);
  }
}