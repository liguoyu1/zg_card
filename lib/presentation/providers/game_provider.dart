import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cards/cards.dart';
import '../../data/heroes/heroes_data.dart';
import '../../data/online_game_service.dart';
import '../../domain/models/models.dart';
import '../../domain/services/deterministic_random.dart';
import '../../domain/services/game_actions.dart';
import '../../domain/services/services.dart' show AIDifficulty, TurnService, GameRules, BattlefieldService, HeroPowerFactory;

/// 游戏状态Notifier
class GameStateNotifier extends StateNotifier<GameState?> implements GameStateDriver {
  GameStateNotifier() : super(null);

  // 复用服务实例（无状态，可安全复用）
  final BattlefieldService _bfs = BattlefieldService();
  final TurnService _turnService = TurnService();

  /// 初始化游戏
  void initGame({
    required String player1Id,
    required String player2Id,
    required Hero player1Hero,
    required Hero player2Hero,
    List<Card>? player1Deck,
    List<Card>? player2Deck,
    int? player1Health,
    int? player2Health,
    int? seed,
  }) {
    // 使用预设卡组或自定义卡组
    final deck1 = player1Deck ?? getPresetDeck(player1Hero.owner);
    final deck2 = player2Deck ?? getPresetDeck(player2Hero.owner);

    // 对局种子：联机时两端同步；单机时随机生成（每局不同）
    final s = seed ?? Random().nextInt(1 << 31);
    final rng = DeterministicRandom(s);

    // 初始发牌（同一确定性 rng → 两端手牌/牌库一致）
    final hand1 = TurnService.drawInitialHands(deck1, GameRules.initialHandSize, rng: rng);
    final hand2 = TurnService.drawInitialHands(deck2, GameRules.initialHandSize, rng: rng);

    final player1 = Player(
      id: player1Id,
      hero: player1Hero,
      health: player1Health ?? GameRules.initialHealth,
      mana: 1,
      maxMana: 1,
      hand: hand1.hand,
      deck: hand1.deck,
    );

    final player2 = Player(
      id: player2Id,
      hero: player2Hero,
      health: player2Health ?? GameRules.initialHealth,
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
      seed: s,
    );
  }

  /// 出牌
  void playCard(String playerId, Card card, {String? targetId}) {
    if (state == null) return;
    state = _bfs.playCard(state!, playerId, card, targetId: targetId);
  }

  /// 随从攻击
  void minionAttack(String playerId, Card attacker, String targetId) {
    if (state == null) return;
    state = _bfs.minionAttack(state!, playerId, attacker, targetId);
    // 检查游戏结束
    _checkGameEnd();
  }

  /// 英雄攻击（攻击敌方英雄）
  @override
  void heroAttackDirect(String playerId) {
    if (state == null) return;
    state = _bfs.heroAttack(state!, playerId);
    _checkGameEnd();
  }

  /// 随从攻击（暴击敌方英雄）
  void minionAttackHero(String playerId, Card attacker) {
    if (state == null) return;
    state = _bfs.minionAttackHero(state!, playerId, attacker);
    _checkGameEnd();
  }
  void useHeroPower(String playerId, {String? targetId}) {
    if (state == null) return;
    final player = state!.getCurrentPlayer(playerId);
    if (player.mana < 2) return;

    final skill = HeroPowerFactory.create(player.hero.skillType);
    state = skill.apply(state!, playerId, targetId: targetId);
    _checkGameEnd();
  }

  /// 开始回合
  @override
  void startTurn(String playerId) {
    if (state == null) return;
    state = _turnService.startTurn(state!, playerId);
  }

  /// 结束回合
  @override
  void endTurn(String playerId) {
    if (state == null) return;
    state = _turnService.endTurn(state!, playerId);
    
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

  // ── GameStateDriver 实现（联机动作应用入口）──

  @override
  void playCardAt(String playerId, int handIndex, {ActionTarget? target}) {
    if (state == null) return;
    final player = state!.getCurrentPlayer(playerId);
    if (handIndex < 0 || handIndex >= player.hand.length) return;
    final card = player.hand[handIndex];
    playCard(playerId, card, targetId: _targetToId(playerId, target));
  }

  @override
  void minionAttackAt(String playerId, int attIndex, int targetIndex) {
    if (state == null) return;
    final player = state!.getCurrentPlayer(playerId);
    final opp = state!.opponent;
    if (attIndex < 0 || attIndex >= player.board.length) return;
    if (targetIndex < 0 || targetIndex >= opp.board.length) return;
    minionAttack(playerId, player.board[attIndex], opp.board[targetIndex].id);
  }

  @override
  void minionAttackHeroAt(String playerId, int attIndex) {
    if (state == null) return;
    final player = state!.getCurrentPlayer(playerId);
    if (attIndex < 0 || attIndex >= player.board.length) return;
    minionAttackHero(playerId, player.board[attIndex]);
  }

  @override
  void useHeroPowerAt(String playerId, {ActionTarget? target}) {
    useHeroPower(playerId, targetId: _targetToId(playerId, target));
  }

  /// 编码目标 → 本地 targetId（'hero_x' 或随从 id）
  String? _targetToId(String playerId, ActionTarget? target) {
    if (target == null || state == null) return null;
    if (target.index >= 0) {
      final opp = state!.opponent;
      if (target.index < opp.board.length) return opp.board[target.index].id;
      return null;
    }
    final id = target.side == 'self' ? playerId : state!.opponent.id;
    return 'hero_$id';
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

/// AI对战 / 真联机对战状态Notifier
///
/// 单机模式：代理到本地 GameStateNotifier，对手由 GameScreen 的 AI 驱动。
/// 联机模式（[startOnlineGame]）：两端用同一 seed 确定性演进。
/// 本端玩家操作先在本地演化，再编码为 action 提交到后端中继；
/// 轮询循环拉取对端动作（跳过自己的），应用到本地状态，实现状态一致。
class AIGameNotifier extends StateNotifier<GameState?> {
  AIGameNotifier({OnlineGameService? onlineService})
      : _onlineService = onlineService ?? OnlineGameService(),
        super(null);
  late GameStateNotifier _gameStateNotifier;

  // ── 联机字段 ──
  final OnlineGameService _onlineService;
  bool _online = false;
  String _matchId = '';
  String _myId = '';
  String _oppId = '';
  int _processedSeq = 0;
  Timer? _pollTimer;
  bool _pollBusy = false;
  Hero _localHero = const Hero(id: '', name: '', className: '', kingdom: '', heroPowerName: '', heroPowerDescription: '', skillType: SkillType.defensive);
  Hero _remoteHero = const Hero(id: '', name: '', className: '', kingdom: '', heroPowerName: '', heroPowerDescription: '', skillType: SkillType.defensive);

  /// 开始AI对战
  void startAIGame({
    required String playerId,
    required Hero playerHero,
    required AIDifficulty difficulty,
  }) {
    _online = false;
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

  /// 开始冒险任务（Roguelite模式）
  void startMissionGame({
    required String playerId,
    required Hero playerHero,
    required Hero opponentHero,
    required AIDifficulty difficulty,
    int? playerHealth,
  }) {
    _online = false;
    _gameStateNotifier = GameStateNotifier();
    _gameStateNotifier.initGame(
      player1Id: playerId,
      player2Id: 'ai_${difficulty.name}',
      player1Hero: playerHero,
      player2Hero: opponentHero,
      player1Health: playerHealth,
    );
    state = _gameStateNotifier.state;
  }

  /// 开始真联机对局。
  /// [isHost]：true 的一方生成种子并提交 `start` 动作广播给对端；
  /// 非 host 等待轮询到 `start` 动作后，用同一种子初始化本地状态。
  void startOnlineGame({
    required Hero playerHero,
    required Hero opponentHero,
    required String matchId,
    required String myId,
    required String oppId,
    required bool isHost,
  }) {
    _online = true;
    _matchId = matchId;
    _myId = myId;
    _oppId = oppId;
    _localHero = playerHero;
    _remoteHero = opponentHero;
    _processedSeq = 0;
    _pollTimer?.cancel();

    if (isHost) {
      // 本端生成种子，初始化并广播。
      // 约定：host 始终为 player1，两端以同一 p1/p2 顺序确定性演进。
      final seed = Random().nextInt(1 << 31);
      _gameStateNotifier = GameStateNotifier();
      _gameStateNotifier.initGame(
        player1Id: myId,
        player2Id: oppId,
        player1Hero: playerHero,
        player2Hero: opponentHero,
        seed: seed,
      );
      state = _gameStateNotifier.state;
      _submit('start', {'seed': seed});
    } else {
      // 非 host：先置 null，等待 poll 到 start 动作后用同 seed 初始化。
      // 非 host 视角：host 为 player1，本地为 player2（与 host 端一致的 p1/p2 顺序）。
      state = null;
    }

    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (!_online || _pollBusy) return;
    _pollBusy = true;
    try {
      final result = await _onlineService.pollActions(_matchId, after: _processedSeq);
      final actions = result['actions'] as List<dynamic>? ?? [];
      if (actions.isEmpty) return;
      actions.sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
      for (final raw in actions) {
        final seq = raw['seq'] as int;
        if (seq <= _processedSeq) continue;
        final odID = raw['odID'] as String;
        if (odID == _myId) {
          _processedSeq = seq; // 自己的动作，本地已演化，仅推进游标
          continue;
        }
        final action = raw['action'] as Map<String, dynamic>? ?? const {};
        _applyRemoteAction(odID, action['type'] as String? ?? '', action['data'] as Map<String, dynamic>? ?? const {});
        _processedSeq = seq;
      }
    } catch (e) {
      // 网络错误静默重试
    } finally {
      _pollBusy = false;
    }
  }

  /// 应用对端动作。`start` 动作携带 seed，用于初始化本端确定性引擎。
  void _applyRemoteAction(String actorId, String type, Map<String, dynamic> data) {
    if (type == 'start') {
      final seed = data['seed'] as int?;
      if (seed == null) return;
      // 只有非 host 会走到这里。为与 host 端 p1/p2 顺序一致：
      // host(=_oppId) 为 player1，本地(=_myId) 为 player2。
      _gameStateNotifier = GameStateNotifier();
      _gameStateNotifier.initGame(
        player1Id: _oppId,
        player2Id: _myId,
        player1Hero: _remoteHero,
        player2Hero: _localHero,
        seed: seed,
      );
      state = _gameStateNotifier.state;
      return;
    }
    if (_gameStateNotifier.state == null) return; // 尚未同步 seed，忽略后续动作
    applyAction(_gameStateNotifier, actorId, type, data);
    state = _gameStateNotifier.state;
  }

  /// 提交一个动作到后端中继。
  void _submit(String type, Map<String, dynamic> data) {
    _onlineService.submitAction(_matchId, _myId, type, data: data);
  }

  // ── 玩家操作（本地演化 + 联机提交） ──

  void playCard(String playerId, Card card, {String? targetId}) {
    _gameStateNotifier.playCard(playerId, card, targetId: targetId);
    state = _gameStateNotifier.state;
    if (_online) {
      final st = state;
      if (st == null) return;
      final handIdx = st.getCurrentPlayer(playerId).hand.indexWhere((c) => c.id == card.id);
      if (handIdx < 0) return;
      _submit('play', {'hand': handIdx, 'target': _encodeTarget(st, playerId, targetId)});
    }
  }

  void minionAttack(String playerId, Card attacker, String targetId) {
    _gameStateNotifier.minionAttack(playerId, attacker, targetId);
    state = _gameStateNotifier.state;
    if (_online) {
      final st = state;
      if (st == null) return;
      final attIdx = st.getCurrentPlayer(playerId).board.indexWhere((c) => c.id == attacker.id);
      final opp = st.opponent;
      final tgtIdx = opp.board.indexWhere((c) => c.id == targetId);
      if (attIdx < 0 || tgtIdx < 0) return;
      _submit('attack_minion', {'att': attIdx, 'target': tgtIdx});
    }
    _checkEndInOnline();
  }

  void heroAttackDirect(String playerId) {
    _gameStateNotifier.heroAttackDirect(playerId);
    state = _gameStateNotifier.state;
    if (_online) _submit('hero_direct', {});
    _checkEndInOnline();
  }

  void minionAttackHero(String playerId, Card attacker) {
    _gameStateNotifier.minionAttackHero(playerId, attacker);
    state = _gameStateNotifier.state;
    if (_online) {
      final st = state;
      if (st == null) return;
      final attIdx = st.getCurrentPlayer(playerId).board.indexWhere((c) => c.id == attacker.id);
      if (attIdx < 0) return;
      _submit('attack_hero', {'att': attIdx});
    }
    _checkEndInOnline();
  }

  void startTurn(String playerId) {
    _gameStateNotifier.startTurn(playerId);
    state = _gameStateNotifier.state;
    if (_online) _submit('start_turn', {});
  }

  void useHeroPower(String playerId, {String? targetId}) {
    _gameStateNotifier.useHeroPower(playerId, targetId: targetId);
    state = _gameStateNotifier.state;
    if (_online) {
      final st = state;
      if (st == null) return;
      _submit('power', {'target': _encodeTarget(st, playerId, targetId)});
    }
    _checkEndInOnline();
  }

  void endTurn(String playerId) {
    _gameStateNotifier.endTurn(playerId);
    state = _gameStateNotifier.state;
    if (_online) _submit('end_turn', {});
  }

  /// 把本地 targetId 编码为 ActionTarget JSON。
  Map<String, dynamic>? _encodeTarget(GameState st, String playerId, String? targetId) {
    if (targetId == null) return null;
    if (targetId.startsWith('hero_')) {
      final id = targetId.substring(5);
      return {'t': 'hero', 's': id == playerId ? 'self' : 'opp'};
    }
    final opp = st.opponent;
    final idx = opp.board.indexWhere((c) => c.id == targetId);
    if (idx < 0) return null;
    return {'t': 'board', 'i': idx};
  }

  /// 联机下检查游戏结束并广播结束（复用本地 _checkGameEnd 的判定）。
  void _checkEndInOnline() {
    final st = state;
    if (st == null) return;
    final result = GameRules.checkGameEnd(st.player1, st.player2);
    if (result != null) {
      final winnerId = result ? st.player1.id : st.player2.id;
      state = st.copyWith(
        phase: GamePhase.ended,
        winnerId: winnerId,
      );
    }
  }
}

/// Provider定义
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  return GameStateNotifier();
});

final aiGameProvider = StateNotifierProvider<AIGameNotifier, GameState?>((ref) {
  return AIGameNotifier();
});