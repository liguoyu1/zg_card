import 'dart:math';
import '../models/models.dart';
import '../../data/card_image_service.dart';
import 'effects.dart';
import 'effect_executor.dart';
import 'combo_system.dart';

/// 游戏核心规则服务
class GameRules {
  /// 最大手牌数
  static const int maxHandSize = 10;
  
  /// 最大战场随从数
  static const int maxBoardSize = 7;
  
  /// 初始生命值
  static const int initialHealth = 30;
  
  /// 初始手牌数
  static const int initialHandSize = 4;
  
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
  
  /// 结算战斗伤害（原始伤害，不含圣盾处理）
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
  
  /// 出牌 — 支持随从/法术/武器三种类型
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

    // 按类型处理
    List<Card> newBoard = player.board;
    Card? newWeapon = player.weapon;

    if (card.isMinion) {
      // 随从：加入战场
      if (player.boardCount < GameRules.maxBoardSize) {
        final playedCard = card.copyWith(
          id: '${card.id}_${DateTime.now().millisecondsSinceEpoch}',
          imageAsset: card.imageAsset.isNotEmpty ? card.imageAsset : CardImageService.getImageAsset(card.id),
          isDormant: !card.hasCharge,
        );
        newBoard = [...player.board, playedCard];
      }
    } else if (card.isWeapon) {
      // 武器：装备到英雄，替换旧武器
      newWeapon = card.copyWith(
        id: '${card.id}_${DateTime.now().millisecondsSinceEpoch}',
        imageAsset: card.imageAsset.isNotEmpty ? card.imageAsset : CardImageService.getImageAsset(card.id),
      );
    }
    // 法术：只在战场上生效（通过战吼执行），不占板位

    var updatedPlayer = player.copyWith(
      mana: newMana,
      hand: newHand,
      board: newBoard,
      weapon: newWeapon,
    );

    var updatedState = state.updatePlayer(updatedPlayer);

    // 执行战吼/法术效果
    if (card.hasBattlecry) {
      updatedState = _executor.executeBattlecry(updatedState, playerId, card, targetId);
    }

    // 检查组合系统激活
    final updatedPlayerAfterBc = updatedState.getCurrentPlayer(playerId);
    final combos = ComboSystem.getActivatedCombos(updatedPlayerAfterBc.hand);
    for (final combo in combos) {
      final result = ComboSystem.executeCombo(combo, updatedState, playerId);
      for (final msg in result.messages) {
        print('[Combo] $msg');
      }
      updatedState = result.state;
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
    final currentPlayer = state.getCurrentPlayer(playerId);
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
    
    // 计算目标受到的伤害
    var newTargetHealth = target.health - combat.defenderDamage;
    var newAttackerHealth = attacker.health - combat.attackerDamage;
    
    // 处理目标的圣盾
    var newOpponentBoard = List<Card>.from(opponent.board);
    if (target.hasDivineShield) {
      // 圣盾：抵消伤害，移除圣盾关键词
      final newTargetKeywords = target.keywords.where((k) => k != Keyword.divineShield).toList();
      final updatedTarget = target.copyWith(keywords: newTargetKeywords);
      newOpponentBoard[targetIndex] = updatedTarget;
    } else if (newTargetHealth <= 0) {
      // 目标死亡
      newOpponentBoard.removeAt(targetIndex);
      if (target.hasDeathrattle) {
        state = state.updatePlayer(opponent.copyWith(board: newOpponentBoard));
        state = _executor.executeDeathrattle(state, opponent.id, target);
        newOpponentBoard = state.getCurrentPlayer(opponent.id).board;
      }
    } else {
      final updatedTarget = target.copyWith(health: newTargetHealth);
      newOpponentBoard[targetIndex] = updatedTarget;
    }
    
    // 处理攻击者的圣盾
    var newCurrentBoard = List<Card>.from(currentPlayer.board);
    var attackerWithUpdatedKeywords = attacker;
    if (attacker.hasDivineShield) {
      final newAttackerKeywords = attacker.keywords.where((k) => k != Keyword.divineShield).toList();
      attackerWithUpdatedKeywords = attacker.copyWith(keywords: newAttackerKeywords);
      newAttackerHealth = attacker.health; // 圣盾抵消伤害
    }
    
    // 更新攻击者
    final attackerIndex = currentPlayer.board.indexWhere((c) => c.id == attacker.id);
    if (newAttackerHealth <= 0) {
      // 攻击者死亡
      if (attackerIndex >= 0) {
        newCurrentBoard.removeAt(attackerIndex);
      }
      // 触发亡语
      if (attacker.hasDeathrattle) {
        state = state.updatePlayer(currentPlayer.copyWith(board: newCurrentBoard));
        state = _executor.executeDeathrattle(state, currentPlayer.id, attacker);
        newCurrentBoard = state.getCurrentPlayer(currentPlayer.id).board;
      }
    } else {
      // 更新攻击者
      final attackerIndex = currentPlayer.board.indexWhere((c) => c.id == attacker.id);
      if (attackerIndex >= 0) {
        // 风怒随从：第一次攻击后不清除攻击标记，允许再攻击一次
        if (attacker.hasWindfury && !attacker.hasUsedFirstWindfuryAttack) {
          newCurrentBoard[attackerIndex] = attackerWithUpdatedKeywords.copyWith(
            health: newAttackerHealth,
            hasUsedFirstWindfuryAttack: true,
          );
        } else {
          newCurrentBoard[attackerIndex] = attackerWithUpdatedKeywords.copyWith(
            health: newAttackerHealth,
            hasAttackedThisTurn: true,
          );
        }
      }
    }
    
    // 更新战场状态
    state = state.updatePlayer(opponent.copyWith(board: newOpponentBoard));
    state = state.updatePlayer(currentPlayer.copyWith(board: newCurrentBoard));
    
    // 处理生命偷取
    if (attacker.hasLifesteal && combat.defenderDamage > 0) {
      final player = state.getCurrentPlayer(playerId);
      final newHealth = player.health + combat.defenderDamage;
      state = state.updatePlayer(player.copyWith(health: newHealth));
    }
    
    return state;
  }
  
  /// 英雄攻击 - 攻击敌方英雄
  GameState heroAttack(GameState state, String playerId) {
    final opponent = state.opponent;
    final attacker = state.activePlayer;
    
    // 必须攻击嘲讽
    if (GameRules.mustAttackTaunt(opponent)) {
      return state;
    }
    
    // 英雄攻击力 = 武器攻击力（无武器为0）
    final weaponDamage = attacker.weapon?.attack ?? 0;
    if (weaponDamage == 0) return state; // 没有武器，无法攻击
    
    // 对敌方英雄造成伤害
    final newOpponentHealth = opponent.health - weaponDamage;
    final newState = state.updatePlayer(opponent.copyWith(health: newOpponentHealth));
    
    return newState;
  }
  
  /// 随从攻击敌方英雄
  GameState minionAttackHero(GameState state, String playerId, Card attacker) {
    final currentPlayer = state.getCurrentPlayer(playerId);
    final opponent = state.opponent;
    
    // 必须攻击嘲讽
    if (GameRules.mustAttackTaunt(opponent)) return state;
    if (!attacker.canAttack) return state;
    
    // 随从攻击力 = 对英雄造成的伤害
    final newOpponentHealth = opponent.health - attacker.attack;
    
    // 更新攻击者状态（标记已攻击）
    var newBoard = List<Card>.from(currentPlayer.board);
    final atkIdx = newBoard.indexWhere((c) => c.id == attacker.id);
    if (atkIdx >= 0) {
      if (attacker.hasWindfury && !attacker.hasUsedFirstWindfuryAttack) {
        newBoard[atkIdx] = attacker.copyWith(hasUsedFirstWindfuryAttack: true);
      } else {
        newBoard[atkIdx] = attacker.copyWith(hasAttackedThisTurn: true);
      }
    }
    
    var newState = state.updatePlayer(opponent.copyWith(health: newOpponentHealth));
    newState = newState.updatePlayer(currentPlayer.copyWith(board: newBoard));
    
    // 生命偷取
    if (attacker.hasLifesteal) {
      final updatedPlayer = newState.getCurrentPlayer(playerId);
      newState = newState.updatePlayer(updatedPlayer.copyWith(health: updatedPlayer.health + attacker.attack));
    }
    
    return newState;
  }
  
  /// 消灭随从
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
    final target = opponent.board.firstWhere((c) => c.id == targetId);

    // 触发亡语
    var newState = state;
    if (target.hasDeathrattle) {
      newState = _executor.executeDeathrattle(state, opponent.id, target);
    }

    final newBoard = opponent.board.where((c) => c.id != targetId).toList();
    final updatedOpponent = opponent.copyWith(board: newBoard);

    return newState.updatePlayer(updatedOpponent);
  }
}

/// 回合服务 - 处理回合流程
class TurnService {
  /// 开始回合
  GameState startTurn(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    
    // 重置所有随从的攻击状态（含风怒），并唤醒休眠随从
    final resetBoard = player.board.map((card) =>
      card.copyWith(hasAttackedThisTurn: false, hasUsedFirstWindfuryAttack: false, isDormant: false)
    ).toList();
    
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
      final newFatigueCounter = player.fatigueCounter + 1;
      final fatigueDamage = newFatigueCounter;
      final newHealth = player.health - fatigueDamage;
      return state.updatePlayer(player.copyWith(
        mana: newMana,
        maxMana: newMaxMana,
        hand: newHand,
        deck: newDeck,
        health: newHealth,
        fatigueCounter: newFatigueCounter,
        board: resetBoard,
      )).copyWith(activePlayerId: playerId);
    }
    
    return state.updatePlayer(player.copyWith(
      mana: newMana,
      maxMana: newMaxMana,
      hand: newHand,
      deck: newDeck,
      board: resetBoard,
    )).copyWith(activePlayerId: playerId);
  }
  
  /// 结束回合
  GameState endTurn(GameState state, String playerId) {
    final opponentId = state.player1.id == playerId
      ? state.player2.id
      : state.player1.id;

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