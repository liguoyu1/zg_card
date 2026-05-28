import 'dart:math';
import '../models/models.dart';
import 'effects.dart';
import 'effect_executor.dart';

/// 游戏核心规则服务
class GameRules {
  /// 最大手牌数
  static const int maxHandSize = 10;
  
  /// 最大战场随从数
  static const int maxBoardSize = 7;
  
  /// 初始生命值
  static const int initialHealth = 30;
  
  /// 初始手牌数
  static const int initialHandSize = 3;
  
  /// 每回合抽牌数
  static const int cardsPerTurn = 1;
  
  /// 最大法力水晶
  static const int maxMana = 10;
  
  /// 随从可以攻击的条件
  static bool canMinionAttack(Card minion, bool hasAttackedThisTurn) {
    // 有冲锋可以直接攻击
    if (minion.hasCharge) return true;
    // 已经攻击过
    if (hasAttackedThisTurn) return false;
    return true;
  }
  
  /// 检查是否可以出牌
  static bool canPlayCard(Card card, Player player) {
    // 手牌已满
    if (player.handCount >= maxHandSize) return false;
    
    // 法力不足
    if (card.cost > player.mana) return false;
    
    // 战场已满时出随从
    if (card.isMinion && player.isBoardFull) return false;
    
    return true;
  }
  
  /// 计算攻击伤害
  static int calculateDamage(int attack, bool hasDivineShield) {
    return attack;
  }
  
  /// 结算战斗伤害
  static ({int attackerDamage, int defenderDamage}) resolveCombat(
    Card attacker,
    Card defender,
  ) {
    int attackerDamage = defender.attack;
    int defenderDamage = attacker.attack;
    
    // 攻击方有剧毒，双方同归于尽
    if (attacker.keywords.contains(Keyword.poisonous)) {
      attackerDamage = attacker.health;
    }
    
    // 防守方有圣盾，忽略第一次伤害
    if (defender.keywords.contains(Keyword.divineShield)) {
      attackerDamage = 0;
      // 移除圣盾
    }
    
    // 攻击方有风怒，可以攻击两次(简化处理)
    
    return (attackerDamage: attackerDamage, defenderDamage: defenderDamage);
  }
  
  /// 检查游戏是否结束
  static bool? checkGameEnd(Player player1, Player player2) {
    if (player1.isDead && player2.isDead) return null; // 平局
    if (player1.isDead) return false; // player2胜利
    if (player2.isDead) return true; // player1胜利
    return null; // 游戏继续
  }
  
  /// 获取嘲讽目标
  static List<Card> getTauntTargets(Player opponent) {
    return opponent.board.where((c) => c.hasTaunt).toList();
  }
  
  /// 检查是否必须攻击嘲讽
  static bool mustAttackTaunt(Player opponent) {
    return opponent.board.any((c) => c.hasTaunt);
  }
}

/// 战场服务 - 处理战场逻辑
class BattlefieldService {
  final EffectExecutor _executor = EffectExecutor();
  
  /// 出牌
  GameState playCard(GameState state, String playerId, Card card, {String? targetId}) {
    final player = state.getCurrentPlayer(playerId);
    
    // 检查是否可以出牌
    if (!GameRules.canPlayCard(card, player)) {
      return state;
    }
    
    // 消耗法力
    final newMana = player.mana - card.cost;
    
    // 从手牌移除
    final newHand = List<Card>.from(player.hand)..remove(card);
    
    // 如果是随从，加入战场
    List<Card> newBoard = player.board;
    if (card.isMinion) {
      if (player.boardCount < GameRules.maxBoardSize) {
        final playedCard = card.copyWith(
          id: '${card.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
        newBoard = [...player.board, playedCard];
      }
    }
    
    // 更新玩家状态
    var updatedPlayer = player.copyWith(
      mana: newMana,
      hand: newHand,
      board: newBoard,
    );
    
    var updatedState = state.updatePlayer(updatedPlayer);
    
    // 执行战吼效果
    if (card.hasBattlecry) {
      updatedState = _executor.executeBattlecry(updatedState, playerId, card, targetId);
    }
    
    return updatedState;
  }
  
  /// 随从攻击
  GameState minionAttack(
    GameState state,
    String playerId,
    Card attacker,
    String targetId,
  ) {
    final opponent = state.opponent;
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetId);
    
    if (targetIndex == -1) return state;
    
    final target = opponent.board[targetIndex];
    
    // 必须攻击嘲讽
    if (GameRules.mustAttackTaunt(opponent) && !target.hasTaunt) {
      return state;
    }
    
    // 结算伤害
    final combat = GameRules.resolveCombat(attacker, target);
    
    // 计算攻击者受到的伤害
    final newAttackerHealth = attacker.health - combat.attackerDamage;
    var newBoard = List<Card>.from(opponent.board);
    
    // 更新目标
    final newTargetHealth = target.health - combat.defenderDamage;
    if (newTargetHealth <= 0) {
      // 目标死亡，触发亡语
      newBoard.removeAt(targetIndex);
      if (target.hasDeathrattle) {
        var deathState = state.updatePlayer(opponent.copyWith(board: newBoard));
        deathState = _executor.executeDeathrattle(deathState, opponent.id, target);
        newBoard = deathState.getCurrentPlayer(opponent.id).board;
      }
    } else {
      final updatedTarget = target.copyWith(health: newTargetHealth);
      newBoard[targetIndex] = updatedTarget;
    }
    
    // 处理攻击者的圣盾
    var updatedAttacker = attacker;
    if (attacker.keywords.contains(Keyword.divineShield)) {
      final newKeywords = List<Keyword>.from(attacker.keywords)
        ..remove(Keyword.divineShield);
      updatedAttacker = attacker.copyWith(keywords: newKeywords);
    }
    
    // 更新攻击者生命
    if (newAttackerHealth <= 0) {
      // 攻击者死亡
      if (updatedAttacker.hasDeathrattle) {
        // 执行亡语效果需要先获取当前玩家状态
      }
    }
    
    var currentState = state.updatePlayer(opponent.copyWith(board: newBoard));
    
    // 处理攻击者的生命偷取
    if (attacker.hasLifesteal && combat.defenderDamage > 0) {
      final player = currentState.getCurrentPlayer(playerId);
      final newHealth = player.health + combat.defenderDamage;
      currentState = currentState.updatePlayer(player.copyWith(health: newHealth));
    }
    
    return currentState;
  }
  
  /// 英雄攻击
  GameState heroAttack(GameState state, String playerId, String targetId) {
    final opponent = state.opponent;
    final attacker = state.activePlayer;
    
    final targetIndex = opponent.board.indexWhere((c) => c.id == targetId);
    if (targetIndex == -1) return state;
    
    final target = opponent.board[targetIndex];
    
    // 必须攻击嘲讽
    if (GameRules.mustAttackTaunt(opponent) && !target.hasTaunt) {
      return state;
    }
    
    // 英雄攻击
    final newHealth = target.health - (attacker.weapon?.attack ?? 1);
    final newBoard = List<Card>.from(opponent.board);
    
    if (newHealth <= 0) {
      newBoard.removeAt(targetIndex);
    } else {
      newBoard[targetIndex] = target.copyWith(health: newHealth);
    }
    
    return state.updatePlayer(opponent.copyWith(board: newBoard));
  }
  
  /// 沉默随从
  GameState silenceMinion(GameState state, String playerId, String targetId) {
    final player = state.getCurrentPlayer(playerId);
    final targetIndex = player.board.indexWhere((c) => c.id == targetId);
    
    if (targetIndex == -1) return state;
    
    final target = player.board[targetIndex];
    final newBoard = List<Card>.from(player.board);
    newBoard[targetIndex] = target.copyWith(keywords: []);
    
    return state.updatePlayer(player.copyWith(board: newBoard));
  }
  
  /// 消灭随从
  GameState destroyMinion(GameState state, String playerId, String targetId) {
    final opponent = state.opponent;
    final newBoard = opponent.board.where((c) => c.id != targetId).toList();
    
    return state.updatePlayer(opponent.copyWith(board: newBoard));
  }
}

/// 回合服务 - 处理回合流程
class TurnService {
  /// 开始回合
  GameState startTurn(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    
    // 增加法力水晶
    final newMaxMana = (player.maxMana + 1).clamp(0, GameRules.maxMana);
    
    // 恢复法力
    final newMana = newMaxMana;
    
    // 抽牌
    List<Card> newHand = player.hand;
    List<Card> newDeck = player.deck;
    
    if (player.deckCount > 0) {
      final drawnCard = newDeck.first;
      newDeck = newDeck.sublist(1);
      
      // 手牌已满，抽到的牌进入战场或摧毁
      if (player.handCount < GameRules.maxHandSize) {
        newHand = [...player.hand, drawnCard];
      }
    } else {
      // 疲劳伤害
      final fatigueDamage = 1; // 简化处理
      final newHealth = player.health - fatigueDamage;
      return state.updatePlayer(player.copyWith(
        mana: newMana,
        maxMana: newMaxMana,
        hand: newHand,
        deck: newDeck,
        health: newHealth,
      )).copyWith(activePlayerId: playerId);
    }
    
    return state.updatePlayer(player.copyWith(
      mana: newMana,
      maxMana: newMaxMana,
      hand: newHand,
      deck: newDeck,
    )).copyWith(activePlayerId: playerId);
  }
  
  /// 结束回合
  GameState endTurn(GameState state, String playerId) {
    final opponentId = state.player1.id == playerId 
      ? state.player2.id 
      : state.player1.id;
    
    // 触发回合结束效果(亡语等)
    final opponent = state.getCurrentPlayer(opponentId);
    final newOpponentBoard = List<Card>.from(opponent.board);
    
    // 检查亡语
    for (final card in newOpponentBoard) {
      if (card.hasDeathrattle) {
        // 简化处理，实际应该执行亡语效果
      }
    }
    
    return state.copyWith(
      activePlayerId: opponentId,
      turnNumber: state.turnNumber + 1,
    );
  }
  
  /// 洗牌
  static List<Card> shuffleDeck(List<Card> deck) {
    final random = Random();
    final shuffled = List<Card>.from(deck);
    shuffled.shuffle(random);
    return shuffled;
  }
  
  /// 初始发牌
  static ({List<Card> hand, List<Card> deck}) drawInitialHands(
    List<Card> deck,
    int handSize,
  ) {
    final shuffled = shuffleDeck(deck);
    final hand = shuffled.take(handSize).toList();
    final remainingDeck = shuffled.skip(handSize).toList();
    return (hand: hand, deck: remainingDeck);
  }
}