import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../domain/services/services.dart' show AIDifficulty, TurnService, GameRules, BattlefieldService;
import '../../data/cards/cards.dart';
import '../../data/heroes/heroes_data.dart';

/// 游戏状态Notifier
class GameStateNotifier extends StateNotifier<GameState?> {
  GameStateNotifier() : super(null);

  /// 初始化游戏
  void initGame({
    required String player1Id,
    required String player2Id,
    required Hero player1Hero,
    required Hero player2Hero,
    List<Card>? player1Deck,
    List<Card>? player2Deck,
  }) {
    // 使用预设卡组或自定义卡组
    final deck1 = player1Deck ?? getPresetDeck(player1Hero.owner);
    final deck2 = player2Deck ?? getPresetDeck(player2Hero.owner);

    // 初始发牌
    final hand1 = TurnService.drawInitialHands(deck1, GameRules.initialHandSize);
    final hand2 = TurnService.drawInitialHands(deck2, GameRules.initialHandSize);

    final player1 = Player(
      id: player1Id,
      hero: player1Hero,
      health: GameRules.initialHealth,
      mana: 1,
      maxMana: 1,
      hand: hand1.hand,
      deck: hand1.deck,
    );

    final player2 = Player(
      id: player2Id,
      hero: player2Hero,
      health: GameRules.initialHealth,
      mana: 1,
      maxMana: 1,
      hand: hand2.hand,
      deck: hand2.deck,
    );

    state = GameState(
      player1: player1,
      player2: player2,
      activePlayerId: player1Id,
      phase: GamePhase.mulligan,
    );
  }

  /// 出牌
  void playCard(String playerId, Card card, {String? targetId}) {
    if (state == null) return;
    final service = BattlefieldService();
    state = service.playCard(state!, playerId, card, targetId: targetId);
  }

  /// 随从攻击
  void minionAttack(String playerId, Card attacker, String targetId) {
    if (state == null) return;
    final service = BattlefieldService();
    state = service.minionAttack(state!, playerId, attacker, targetId);
  }

  /// 英雄攻击
  void heroAttack(String playerId, String targetId) {
    if (state == null) return;
    final service = BattlefieldService();
    state = service.heroAttack(state!, playerId, targetId);
  }

  /// 使用英雄技能
  void useHeroPower(String playerId, {String? targetId}) {
    if (state == null) return;
    // 简化实现：扣除2点法力
    final player = state!.getCurrentPlayer(playerId);
    if (player.mana < 2) return;
    
    final updatedPlayer = player.copyWith(mana: player.mana - 2);
    state = state!.updatePlayer(updatedPlayer);
  }

  /// 开始回合
  void startTurn(String playerId) {
    if (state == null) return;
    final service = TurnService();
    state = service.startTurn(state!, playerId);
  }

  /// 结束回合
  void endTurn(String playerId) {
    if (state == null) return;
    final service = TurnService();
    state = service.endTurn(state!, playerId);
    
    // 检查游戏结束
    _checkGameEnd();
  }

  /// 检查游戏是否结束
  void _checkGameEnd() {
    if (state == null) return;
    final result = GameRules.checkGameEnd(state!.player1, state!.player2);
    if (result != null) {
      final winnerId = result ? state!.player1.id : state!.player2.id;
      state = state!.copyWith(
        phase: GamePhase.ended,
        winnerId: winnerId,
      );
    }
  }

  /// 获取当前玩家
  Player get currentPlayer => state?.activePlayer ?? state!.player1;

  /// 获取对手
  Player get opponent => state!.opponent;

  /// 重置游戏
  void reset() {
    state = null;
  }
}

/// AI对战状态Notifier
class AIGameNotifier extends StateNotifier<GameState?> {
  late GameStateNotifier _gameStateNotifier;
  AIGameNotifier() : super(null);

  /// 开始AI对战
  void startAIGame({
    required String playerId,
    required Hero playerHero,
    required AIDifficulty difficulty,
  }) {
    // 随机选择AI英雄
    final allHeroes = getAllHeroes();
    final aiHeroes = allHeroes.where((h) => h.className != playerHero.className).toList();
    final aiHero = aiHeroes[DateTime.now().millisecond % aiHeroes.length];

    _gameStateNotifier = GameStateNotifier();
    _gameStateNotifier.initGame(
      player1Id: playerId,
      player2Id: 'ai_${difficulty.name}',
      player1Hero: playerHero,
      player2Hero: aiHero,
    );
    state = _gameStateNotifier.state;
  }

  // 代理方法
  void playCard(String playerId, Card card, {String? targetId}) {
    _gameStateNotifier.playCard(playerId, card, targetId: targetId);
    state = _gameStateNotifier.state;
  }

  void minionAttack(String playerId, Card attacker, String targetId) {
    _gameStateNotifier.minionAttack(playerId, attacker, targetId);
    state = _gameStateNotifier.state;
  }

  void startTurn(String playerId) {
    _gameStateNotifier.startTurn(playerId);
    state = _gameStateNotifier.state;
  }

  void endTurn(String playerId) {
    _gameStateNotifier.endTurn(playerId);
    state = _gameStateNotifier.state;
  }
}

/// Provider定义
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  return GameStateNotifier();
});

final aiGameProvider = StateNotifierProvider<AIGameNotifier, GameState?>((ref) {
  return AIGameNotifier();
});