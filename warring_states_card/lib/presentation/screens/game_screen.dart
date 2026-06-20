import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/hero.dart' as hero;
import '../../domain/models/card.dart' as domain;
import '../../domain/models/player.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/services.dart';
import '../../core/audio/audio_manager.dart';
import '../providers/game_provider.dart';
import '../widgets/widgets.dart';
import '../../domain/models/mission_context.dart';
import '../../domain/models/roguelite_run.dart';
import '../../l10n/locale_service.dart';
import '../../data/persistence/save_manager.dart';
import '../../main.dart' show adService;
import '../../core/theme/app_theme.dart';
import '../widgets/theme_widgets.dart';

/// 游戏主界面 - 战国卡牌游戏对战屏幕
enum _InteractionMode { none, attackTargeting, heroPowerTargeting }

/// 伤害数字条目
class _DamageEntry {
  final String cardId;
  final int value;
  final DamageIndicatorState type;
  _DamageEntry(this.cardId, this.value, this.type);
}

class GameScreen extends ConsumerStatefulWidget {
  final String playerId;
  final hero.Hero playerHero;
  final AIDifficulty difficulty;
  final MissionContext? missionContext;
  final int? runHp; // Roguelite: 继承的HP
  final hero.Hero? opponentHero; // Roguelite: 指定对手

  const GameScreen({
    super.key,
    required this.playerId,
    required this.playerHero,
    this.difficulty = AIDifficulty.normal,
    this.missionContext,
    this.runHp,
    this.opponentHero,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // 战国主题颜色常量

  // 状态
  domain.Card? _selectedMinion;
  _InteractionMode _interactionMode = _InteractionMode.none;
  Map<String, int> _lastBoardHealths = {};
  bool _isPlayerTurn = true;
  int _turnTimeRemaining = 20;
  int? _timerStartTime;
  final Set<String> _attackingCardIds = {};
  /// 伤害数字条目
  final List<_DamageEntry> _damageEntries = [];
  /// 战斗日志
  final List<String> _battleLog = [];
  bool _showBattleLog = false;
  /// 死亡动画队列 (卡ID → 卡牌数据, 延迟400ms后清除)
  final Map<String, domain.Card> _dyingCards = {};
  /// AI 回合阶段文字
  String _aiPhaseText = LocaleService.I.t('game.opponent_turn');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
      // 延迟启动 BGM（等音频引擎就绪）
      Future.delayed(const Duration(seconds: 1), () {
        AudioManager.I.playBGM('bgm.mp3');
      });
    });
    // 启动回合计时器（每秒刷新）
    _startTimerLoop();
  }

  void _startTimerLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _updateTimer();
      return true;
    });
  }

  /// 闪烁卡牌以提供视觉反馈（加到攻击动画集，0.3秒后移除）
  void _flashCard(String cardId) {
    setState(() => _attackingCardIds.add(cardId));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _attackingCardIds.remove(cardId));
      }
    });
  }

  /// 显示伤害数字
  void _showDamage(String cardId, int value, DamageIndicatorState type) {
    if (!mounted) return;
    setState(() => _damageEntries.add(_DamageEntry(cardId, value, type)));
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _damageEntries.removeWhere((e) => e.cardId == cardId && e.value == value));
      }
    });
  }

  void _startTurnTimer() {
    _turnTimeRemaining = 20;
    _timerStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 显示错误提示（非法操作反馈）
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: Colors.red.withAlpha(190),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _triggerAttackAnimation(String attackerId, String targetId) {
    setState(() {
      _attackingCardIds.add(attackerId);
      _attackingCardIds.add(targetId);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _attackingCardIds.remove(attackerId);
          _attackingCardIds.remove(targetId);
        });
      }
    });
  }

  void _updateTimer() {
    if (!mounted || !_isPlayerTurn || _timerStartTime == null) return;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - _timerStartTime!) ~/ 1000;
    final remaining = 20 - elapsed;
    if (remaining <= 0) {
      // 超时自动结束回合
      _endTurn();
      return;
    }
    if (remaining != _turnTimeRemaining && mounted) {
      setState(() => _turnTimeRemaining = remaining);
    }
  }

  /// 记录战斗日志
  void _log(String msg) {
    if (!mounted) return;
    setState(() {
      _battleLog.add(msg);
      if (_battleLog.length > 100) _battleLog.removeAt(0);
    });
  }

  void _initializeGame() {
    if (widget.runHp != null && widget.opponentHero != null) {
      // Roguelite: 使用继承的HP和指定对手
      ref.read(aiGameProvider.notifier).startMissionGame(
        playerId: widget.playerId,
        playerHero: widget.playerHero,
        opponentHero: widget.opponentHero!,
        difficulty: widget.difficulty,
        playerHealth: widget.runHp,
      );
    } else {
      // 普通游戏
      ref.read(aiGameProvider.notifier).startAIGame(
        playerId: widget.playerId,
        playerHero: widget.playerHero,
        difficulty: widget.difficulty,
      );
    }
    // 玩家先手，开始第一回合
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(aiGameProvider.notifier).startTurn(widget.playerId);
        AudioManager.I.manaCrystal();
        setState(() {
          _isPlayerTurn = true;
        });
        _startTurnTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(aiGameProvider);

    if (gameState == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.goldAccent),
              const SizedBox(height: 16),
              Text(
                LocaleService.I.t('game.deploying'),
                style: TextStyle(color: AppTheme.parchment, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (gameState.isEnded) {
      return Stack(
        children: [
          _buildGameContent(gameState),
          _buildGameEndOverlay(gameState),
        ],
      );
    }

    return Stack(
      children: [
        _buildGameContent(gameState),
        // 伤害数字覆盖层
        ..._buildDamageOverlays(),
      ],
    );
  }

  /// 构建伤害数字 Overlay
  List<Widget> _buildDamageOverlays() {
    if (_damageEntries.isEmpty) return [];
    // 基于屏幕中央偏上的固定位置显示
    return [
      for (final entry in _damageEntries)
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 40,
          top: MediaQuery.of(context).size.height / 2 - 60,
          child: DamageIndicator(
            value: entry.value,
            state: entry.type,
            startPosition: Offset.zero,
          ),
        ),
    ];
  }

  Widget _buildGameEndOverlay(GameState gameState) {
    final isPlayerWinner = gameState.winnerId == widget.playerId;
    // 结束时播放胜利/失败音效
    Future.microtask(() {
      if (isPlayerWinner) {
        AudioManager.I.victory();
      } else {
        AudioManager.I.defeat();
      }
    });
    // 如为冒险模式，通知任务完成
    if (widget.missionContext != null) {
      Future.microtask(() {
        widget.missionContext!.onComplete(isPlayerWinner);
      });
    }
    return GameEndOverlay(
      winnerId: gameState.winnerId!,
      isPlayerWinner: isPlayerWinner,
      onReturnToMenu: () {
        if (widget.runHp != null) {
          // Roguelite: 返回剩余HP
          final player = gameState.player1.id == widget.playerId
              ? gameState.player1 : gameState.player2;
          Navigator.of(context).pop(RogueliteResult(
            victory: isPlayerWinner,
            remainingHp: isPlayerWinner ? player.health : 0,
            goldEarned: isPlayerWinner ? 10 : 0,
          ));
        } else {
          Navigator.of(context).pop();
        }
      },
      onRevive: !isPlayerWinner ? _reviveFromAd : null,
      onDoubleGold: isPlayerWinner ? _claimDoubleGold : null,
    );
  }

  void _reviveFromAd() async {
    final rewarded = await adService.showRewardedAd(placementId: 'revive');
    if (!rewarded || !mounted) return;

    ref.read(aiGameProvider.notifier).startAIGame(
      playerId: widget.playerId,
      playerHero: widget.playerHero,
      difficulty: widget.difficulty,
    );
    setState(() {});
  }

  void _claimDoubleGold() async {
    final rewarded = await adService.showRewardedAd(placementId: 'double_gold');
    if (!rewarded || !mounted) return;

    final data = await SaveManager.loadPlayerData();
    if (data != null) {
      await SaveManager.savePlayerData(data.copyWith(gold: data.gold + 10));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('双倍金币已领取！')),
    );
  }

  Widget _buildGameContent(GameState gameState) {
    // 判断是否是玩家回合
    _isPlayerTurn = gameState.activePlayerId == widget.playerId;

    // 玩家视角: player是玩家，opponent是AI
    final player = gameState.player1.id == widget.playerId
        ? gameState.player1
        : gameState.player2;
    final opponent = gameState.player1.id == widget.playerId
        ? gameState.player2
        : gameState.player1;

    // 响应式尺寸
    final screenWidth = MediaQuery.of(context).size.width;
    final boardCardWidth = min(80.0, screenWidth * 0.13);
    final boardCardHeight = min(110.0, boardCardWidth * 1.36);
    final handCardWidth = min(90.0, screenWidth * 0.15);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Container(
          decoration: AppTheme.boardDecoration,
          child: Column(
            children: [
              // === 对手区域 (顶部) ===
              _buildOpponentArea(opponent, gameState),

              const SizedBox(height: 8),

              // === 对手战场 ===
              _buildBoardSection(
                opponent.board,
                isOpponent: true,
                boardCardWidth: boardCardWidth,
                boardCardHeight: boardCardHeight,
                gameState: gameState,
              ),

              // === 分隔线 ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.borderGold.withAlpha(100),
                        AppTheme.borderGold.withAlpha(150),
                        AppTheme.borderGold.withAlpha(100),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // === 玩家战场 ===
              _buildBoardSection(
                player.board,
                isOpponent: false,
                boardCardWidth: boardCardWidth,
                boardCardHeight: boardCardHeight,
                gameState: gameState,
              ),

              const SizedBox(height: 8),

              // === 玩家手牌区域 ===
              _buildHandArea(player, handCardWidth, gameState),

              // === 玩家英雄 + 法力 + 结束回合按钮 ===
              _buildPlayerFooter(player, gameState),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建对手区域
  Widget _buildOpponentArea(Player opponent, GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.agedWood.withAlpha(128),
        border: Border(
          bottom: BorderSide(color: AppTheme.goldAccent.withAlpha(76)),
        ),
      ),
      child: Row(
        children: [
          // 英雄头像（可点击作为攻击目标）
          GestureDetector(
            onTap: _isPlayerTurn && _selectedMinion != null
                ? _onOpponentHeroTap
                : null,
            child: HeroAvatar(
              hero: opponent.hero,
              health: opponent.health,
              armor: opponent.armor,
              hasWeapon: opponent.hasWeapon,
            ),
          ),
          const SizedBox(width: 8),
          // 英雄名称
          Expanded(
            child: Text(
              opponent.hero.name,
              style: const TextStyle(
                color: AppTheme.parchment,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 法力水晶
          CompactManaCrystals(
            currentMana: opponent.mana,
            maxMana: opponent.maxMana,
          ),
          const SizedBox(width: 8),
          // 手牌数量
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldAccent.withAlpha(76)),
              image: const DecorationImage(
                image: AssetImage('assets/back/card_back.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style, color: AppTheme.parchment, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${opponent.handCount}',
                  style: const TextStyle(
                    color: AppTheme.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建战场区域
  Widget _buildBoardSection(
    List<domain.Card> board, {
    required bool isOpponent,
    required double boardCardWidth,
    required double boardCardHeight,
    required GameState gameState,
  }) {
    // 检测伤害变化
    Map<String, CardAnimationState> animStates = {};
    for (final card in board) {
      final lastHealth = _lastBoardHealths[card.id];
      if (lastHealth != null && lastHealth > card.health) {
        animStates[card.id] = CardAnimationState.damaged;
      } else if (_attackingCardIds.contains(card.id)) {
        animStates[card.id] = CardAnimationState.attacking;
      }
    }

    // 更新健康值记录
    _lastBoardHealths = {
      for (final card in board) card.id: card.health,
    };

    // 战场容器高度
    final boardHeight = board.isEmpty ? 80.0 : (boardCardHeight + 16);

    return Container(
      height: boardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: board.isEmpty
          ? Center(
              child: Text(
                isOpponent ? LocaleService.I.t('game.enemy_board_empty') : LocaleService.I.t('game.my_board_empty'),
                style: TextStyle(
                  color: AppTheme.parchment.withAlpha(128),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: board.length + (isOpponent ? _dyingCards.length : 0),
              itemBuilder: (context, index) {
                if (index >= board.length) {
                  // 死亡动画卡牌
                  final dyingIndex = index - board.length;
                  final dyingId = _dyingCards.keys.elementAt(dyingIndex);
                  final dyingCard = _dyingCards[dyingId]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: boardCardWidth,
                      height: boardCardHeight,
                      child: BoardCard(
                        key: ValueKey('dying_$dyingId'),
                        card: dyingCard,
                        animationState: CardAnimationState.dying,
                        selectionState: CardSelectionState.none,
                        onTap: null,
                      ),
                    ),
                  );
                }
                final card = board[index];
                final isSelected = _selectedMinion?.id == card.id;

                // 确定选择状态
                CardSelectionState selectionState = CardSelectionState.none;
                if (isOpponent) {
                  // 对手卡牌：如果是攻击目标则高亮
                  if (_selectedMinion != null) {
                    // 检查嘲讽规则：对方战场上是否有嘲讽随从
                    final opponent = gameState.player1.id == widget.playerId
                        ? gameState.player2
                        : gameState.player1;
                    final hasTaunt = opponent.board.any((c) => c.hasTaunt);
                    if (hasTaunt && !card.hasTaunt) {
                      // 有嘲讽，不能选
                    } else {
                      selectionState = CardSelectionState.targetable;
                    }
                  }
                } else {
                  // 己方卡牌
                  if (isSelected) {
                    selectionState = CardSelectionState.selected;
                  } else if (card.canAttack) {
                    selectionState = CardSelectionState.canAttack;
                  } else if (card.hasAttackedThisTurn) {
                    selectionState = CardSelectionState.hasAttacked;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: boardCardWidth,
                    height: boardCardHeight,
                    child: BoardCard(
                      key: ValueKey(card.id),
                      card: card,
                      animationState: animStates[card.id] ?? CardAnimationState.idle,
                      selectionState: selectionState,
                      onTap: () => _onBoardCardTap(card, isOpponent, gameState),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// 处理战场卡牌点击
  void _onBoardCardTap(domain.Card card, bool isOpponent, GameState gameState) {
    if (!_isPlayerTurn) return;

    // 英雄技能选目标模式
    if (_interactionMode == _InteractionMode.heroPowerTargeting) {
      _executeHeroPowerOnTarget(card, isOpponent, gameState);
      return;
    }

    if (isOpponent) {
      // 点击对手卡牌 - 发起攻击
      if (_selectedMinion != null) {
        // 检查嘲讽规则：对方战场上是否有嘲讽随从
        final opponent = gameState.player1.id == widget.playerId
            ? gameState.player2
            : gameState.player1;
        final hasTaunt = opponent.board.any((c) => c.hasTaunt);

        if (hasTaunt && !card.hasTaunt) {
          _showError(LocaleService.I.t('game.taunt_required'));
          return;
        }

        // 执行攻击
        final attacker = _selectedMinion;
        if (attacker == null) return;
        final targetCard = card; // 攻击前缓存目标
        _triggerAttackAnimation(attacker.id, card.id);
        AudioManager.I.attack();
        AudioManager.I.damage();
        _showDamage(card.id, attacker.attack, DamageIndicatorState.damage);
        _log('${attacker.name} 攻击 ${card.name}');
        ref.read(aiGameProvider.notifier).minionAttack(
          widget.playerId,
          attacker,
          card.id,
        );
        // 检测目标是否死亡 → 死亡动画 + 音效
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          final st = ref.read(aiGameProvider);
          if (st == null) return;
          final targetStillAlive = st.opponent.board.any((c) => c.id == card.id);
          if (!targetStillAlive) {
            AudioManager.I.death();
            setState(() {
              _dyingCards[targetCard.id] = targetCard;
            });
            Future.delayed(const Duration(milliseconds: 400), () {
              if (!mounted) return;
              setState(() => _dyingCards.remove(targetCard.id));
            });
          }
        });
        setState(() {
          _selectedMinion = null;
        });
      }
    } else {
      // 点击己方卡牌 - 选择攻击者
      if (card.canAttack) {
        setState(() {
          if (_selectedMinion?.id == card.id) {
            _selectedMinion = null;
          } else {
            _selectedMinion = card;
          }
        });
      } else if (_selectedMinion?.id == card.id) {
        // 取消选择
        setState(() {
          _selectedMinion = null;
        });
      }
    }
  }

  /// 英雄技能选目标：校验合法性并执行
  void _executeHeroPowerOnTarget(domain.Card card, bool isOpponent, GameState gameState) {
    final player = gameState.getCurrentPlayer(widget.playerId);
    final skill = HeroPowerFactory.create(player.hero.skillType);

    // BuffPower 只能选友方
    if (skill is BuffPower && isOpponent) return;
    // ControlPower/DebuffPower 只能选敌方
    if ((skill is ControlPower || skill is DebuffPower) && !isOpponent) return;

    ref.read(aiGameProvider.notifier).useHeroPower(widget.playerId, targetId: card.id);
    _flashCard(card.id);
    setState(() => _interactionMode = _InteractionMode.none);
  }

  /// 处理英雄头像点击 (玩家随从攻击敌方英雄)
  void _onOpponentHeroTap() {
    if (!_isPlayerTurn) return;

    // 英雄技能选目标模式 → 对敌方英雄使用
    if (_interactionMode == _InteractionMode.heroPowerTargeting) {
      final gameState = ref.read(aiGameProvider);
      if (gameState == null) return;
      final player = gameState.getCurrentPlayer(widget.playerId);
      final skill = HeroPowerFactory.create(player.hero.skillType);
      if (skill is BuffPower) return; // Buff 不能对敌人用

      ref.read(aiGameProvider.notifier).useHeroPower(widget.playerId, targetId: 'hero_${widget.playerId}');
      setState(() => _interactionMode = _InteractionMode.none);
      return;
    }

    final attacker = _selectedMinion;
    if (attacker == null) return;

    final gameState = ref.read(aiGameProvider);
    if (gameState == null) return;

    final opponent = gameState.player1.id == widget.playerId
        ? gameState.player2
        : gameState.player1;

    // 有嘲讽时不能直接攻击英雄
    if (opponent.board.any((c) => c.hasTaunt)) return;

    // 随从攻击英雄
    _triggerAttackAnimation(attacker.id, 'hero');
    ref.read(aiGameProvider.notifier).minionAttackHero(widget.playerId, attacker);
    setState(() {
      _selectedMinion = null;
    });
  }

  /// 点击自己英雄头像 — 使用英雄技能或取消技能目标选择
  void _onPlayerHeroTap() {
    if (_interactionMode == _InteractionMode.heroPowerTargeting) {
      setState(() => _interactionMode = _InteractionMode.none);
      return;
    }
    if (_selectedMinion != null) {
      setState(() => _selectedMinion = null);
      return;
    }

    if (!_isPlayerTurn) return;
    final state = ref.read(aiGameProvider);
    if (state == null) return;
    final player = state.getCurrentPlayer(widget.playerId);
    if (player.mana < 2) {
      _showError(LocaleService.I.t('game.mana_insufficient_hero_power', args: {'cost': '2'}));
      return;
    }

    final skill = HeroPowerFactory.create(player.hero.skillType);

    // 检查技能是否需要选目标
    final needsTarget = player.board.isNotEmpty && _heroPowerNeedsTarget(skill);

    if (needsTarget) {
      // 进入选目标模式
      setState(() {
        _interactionMode = _InteractionMode.heroPowerTargeting;
        _selectedMinion = null;
      });
    } else {
      // 直接释放
      ref.read(aiGameProvider.notifier).useHeroPower(widget.playerId);
      AudioManager.I.buttonClick();
      _log('使用英雄技能：${skill.runtimeType}');
      _flashCard('hero_${widget.playerId}');
      setState(() => _selectedMinion = null);
    }
  }

  /// 英雄技能是否需要选目标
  bool _heroPowerNeedsTarget(HeroPowerEffect skill) {
    return skill is BuffPower || skill is ControlPower || skill is DebuffPower;
  }

  /// 构建手牌区域
  Widget _buildHandArea(Player player, double handCardWidth, GameState gameState) {
    if (player.hand.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            LocaleService.I.t('game.hand_empty'),
            style: TextStyle(
              color: AppTheme.parchment.withAlpha(128),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: player.hand.length,
        itemBuilder: (context, index) {
          final card = player.hand[index];
          final canAfford = player.mana >= card.cost;
          final isSelected = _selectedMinion?.id == card.id;

          // 确定手牌状态
          HandCardState cardState = canAfford
              ? HandCardState.playable
              : HandCardState.unplayable;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: handCardWidth,
              child: HandCard(
                card: card,
                cardState: cardState,
                canAfford: canAfford,
                onTap: () => _onHandCardTap(card, gameState),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 处理手牌点击 — 按类型分发（随从/法术/武器）
  void _onHandCardTap(domain.Card card, GameState gameState) {
    if (!_isPlayerTurn) return;

    final player = gameState.player1.id == widget.playerId
        ? gameState.player1
        : gameState.player2;

    if (card.cost > player.mana) {
      _showError(LocaleService.I.t('game.mana_insufficient', args: {'cost': card.cost.toString(), 'mana': player.mana.toString()}));
      return;
    }

    // 随从：需要空位
    if (card.isMinion && player.boardCount >= GameRules.maxBoardSize) {
      _showError(LocaleService.I.t('game.board_full', args: {'max': GameRules.maxBoardSize.toString()}));
      return;
    }

    ref.read(aiGameProvider.notifier).playCard(widget.playerId, card);
    AudioManager.I.playCard();
    _log('打出 ${card.name}（费用 ${card.cost}）');
  }

  /// 构建玩家底部区域 (英雄 + 法力 + 结束按钮)
  Widget _buildPlayerFooter(Player player, GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.agedWood.withAlpha(128),
        border: Border(
          top: BorderSide(color: AppTheme.goldAccent.withAlpha(128)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 英雄头像
              GestureDetector(
                onTap: _onPlayerHeroTap,
                child: HeroAvatar(
                  hero: player.hero,
                  health: player.health,
                  armor: player.armor,
                  hasWeapon: player.hasWeapon,
                ),
              ),
              const SizedBox(width: 12),
              // 英雄信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.hero.name,
                      style: const TextStyle(
                        color: AppTheme.parchment,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildHealthDisplay(player.health, player.armor),
                        if (player.hasWeapon) ...[
                          const SizedBox(width: 12),
                          _buildWeaponDisplay(player.weapon!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 英雄技能按钮
                    _buildHeroPowerButton(player),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 法力水晶
              ManaCrystals(
                currentMana: player.mana,
                maxMana: player.maxMana,
              ),
            ],
          ),
          // 结束回合按钮
          if (_isPlayerTurn) ...[
            const SizedBox(height: 12),
            _buildEndTurnButton(),
          ] else ...[
            const SizedBox(height: 12),
            _buildAITurnIndicator(),
          ],
          const SizedBox(height: 4),
          _buildBattleLog(),
        ],
      ),
    );
  }

  /// 构建英雄技能按钮
  Widget _buildHeroPowerButton(Player player) {
    final canUse = player.mana >= 2 && _isPlayerTurn;
    final isTargeting = _interactionMode == _InteractionMode.heroPowerTargeting;
    return GestureDetector(
      onTap: canUse ? () => _onPlayerHeroTap() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isTargeting
              ? AppTheme.goldAccent.withAlpha(80)
              : AppTheme.cardBack.withAlpha(180),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isTargeting ? AppTheme.goldAccent : AppTheme.parchment.withAlpha(100),
            width: isTargeting ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: canUse ? AppTheme.goldAccent : AppTheme.parchment.withAlpha(100),
            ),
            const SizedBox(width: 4),
            Text(
              isTargeting ? LocaleService.I.t('game.select_target') : player.hero.heroPowerName,
              style: TextStyle(
                color: isTargeting
                    ? AppTheme.goldAccent
                    : canUse
                        ? AppTheme.parchment
                        : AppTheme.parchment.withAlpha(100),
                fontSize: 12,
                fontWeight: isTargeting ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDisplay(int health, int armor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(179),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                '$health',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (armor > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(179),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$armor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeaponDisplay(domain.Card weapon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gavel, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '${weapon.attack}/${weapon.health}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndTurnButton() {
    final timerColor = _turnTimeRemaining <= 5
        ? Colors.red
        : _turnTimeRemaining <= 10
            ? Colors.orange
            : AppTheme.parchment;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _endTurn,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.skip_next, color: AppTheme.parchment, size: 18),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: timerColor.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_turnTimeRemaining',
                    style: TextStyle(
                      color: timerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 28,
                    child: LinearProgressIndicator(
                      value: _turnTimeRemaining / 20,
                      backgroundColor: timerColor.withAlpha(38),
                      valueColor: AlwaysStoppedAnimation(timerColor),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        label: Text(
          LocaleService.I.t('game.end_turn'),
          style: TextStyle(
            color: AppTheme.parchment,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardBack,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.goldAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildBattleLog() {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            _showBattleLog ? Icons.description : Icons.description_outlined,
            color: AppTheme.parchment,
            size: 20,
          ),
          onPressed: () => setState(() => _showBattleLog = !_showBattleLog),
          tooltip: LocaleService.I.t('game.battle_log'),
        ),
        if (_showBattleLog)
          Container(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
            decoration: BoxDecoration(
              color: AppTheme.agedWood.withAlpha(230),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.goldAccent.withAlpha(128)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _battleLog.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  _battleLog[i],
                  style: TextStyle(color: AppTheme.parchment, fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAITurnIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBack.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(76)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _aiPhaseText,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 结束回合
  void _endTurn() {
    _timerStartTime = null; // 停止计时器
    ref.read(aiGameProvider.notifier).endTurn(widget.playerId);
    AudioManager.I.endTurn();
    setState(() {
      _isPlayerTurn = false;
      _selectedMinion = null;
      _interactionMode = _InteractionMode.none;
    });

    // AI回合
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _executeAITurn();
      }
    });
  }

  /// 执行AI回合
  void _executeAITurn() {
    setState(() => _aiPhaseText = LocaleService.I.t('game.ai_starting'));
    // Step 1: AI 回合开始（回蓝+抽牌）
    final initState = ref.read(aiGameProvider);
    if (initState == null) return;
    ref.read(aiGameProvider.notifier).startTurn(initState.activePlayer.id);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _aiPhaseText = LocaleService.I.t('game.ai_playing'));
      // Step 2: AI 出牌（重新读取最新 state）
      _aiPlayCards();

      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        setState(() => _aiPhaseText = LocaleService.I.t('game.ai_attacking'));
        // Step 3: AI 攻击（重新读取最新 state，逐次 400ms 延迟）
        await _aiAttack();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          final curState = ref.read(aiGameProvider);
          if (curState == null) return;
          // Step 4: AI 结束回合 → 启动玩家回合
          ref.read(aiGameProvider.notifier).endTurn(curState.activePlayer.id);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.read(aiGameProvider.notifier).startTurn(widget.playerId);
              setState(() {
                _isPlayerTurn = true;
              });
              _startTurnTimer();
            }
          });
        });
      });
    });
  }

  /// AI出牌逻辑 — 每次操作重新读取最新 state
  void _aiPlayCards() {
    final notifier = ref.read(aiGameProvider.notifier);
    var state = ref.read(aiGameProvider);
    if (state == null) return;
    final aiId = state.activePlayer.id;
    final s = state; // promote to non-null

    // AI 出牌：所有类型（随从/法术/武器），按费用降序
    final playable = s.activePlayer.hand
        .where((c) => c.cost <= s.activePlayer.mana)
        .toList()
      ..sort((a, b) => b.cost.compareTo(a.cost));

    for (final card in playable) {
      state = ref.read(aiGameProvider);
      if (state == null) return;
      if (card.isMinion && state.activePlayer.boardCount >= 7) break;
      if (card.cost > state.activePlayer.mana) continue;
      notifier.playCard(aiId, card);
    }
    // AI 剩余费用 >= 2 且场上还有随从时用英雄技能
    state = ref.read(aiGameProvider);
    if (state != null && state.activePlayer.mana >= 2) {
      final aiPlayer = state.activePlayer;
      final skill = HeroPowerFactory.create(aiPlayer.hero.skillType);
      final needsTarget = aiPlayer.board.isNotEmpty && _heroPowerNeedsTarget(skill);
      if (needsTarget) {
        // 选第一个随从为目标
        notifier.useHeroPower(aiId, targetId: aiPlayer.board.first.id);
      } else {
        notifier.useHeroPower(aiId);
      }
    }
  }

  /// AI攻击逻辑 — 每次操作重新读取最新 state，逐次延迟以产生视觉节奏
  Future<void> _aiAttack() async {
    var state = ref.read(aiGameProvider);
    if (state == null) return;
    final notifier = ref.read(aiGameProvider.notifier);
    final aiId = state.activePlayer.id;

    for (final _ in state.activePlayer.board.where((c) => c.canAttack)) {
      state = ref.read(aiGameProvider);
      if (state == null) return;
      final aiPlayer = state.activePlayer;
      // 按 ID 重新查找可攻击的随从（避免卡牌引用过期）
      final attacker = aiPlayer.board.where((c) => c.canAttack).firstOrNull;
      if (attacker == null) break;

      final humanPlayer = state.opponent;
      final tauntMinions = humanPlayer.board.where((c) => c.hasTaunt).toList();

      if (tauntMinions.isNotEmpty) {
        final target = tauntMinions[Random().nextInt(tauntMinions.length)];
        _triggerAttackAnimation(attacker.id, target.id);
        _showDamage(target.id, attacker.attack, DamageIndicatorState.damage);
        final targetCard = target;
        notifier.minionAttack(aiId, attacker, target.id);
        _detectAIDeath(targetCard);
      } else if (humanPlayer.board.isNotEmpty) {
        final target = humanPlayer.board[Random().nextInt(humanPlayer.board.length)];
        _triggerAttackAnimation(attacker.id, target.id);
        _showDamage(target.id, attacker.attack, DamageIndicatorState.damage);
        final targetCard = target;
        notifier.minionAttack(aiId, attacker, target.id);
        _detectAIDeath(targetCard);
      } else {
        _triggerAttackAnimation(attacker.id, 'hero');
        _showDamage('hero_${humanPlayer.id}', attacker.attack, DamageIndicatorState.damage);
        notifier.minionAttackHero(aiId, attacker);
      }
      AudioManager.I.attack();
      AudioManager.I.damage();
      _log('AI ${attacker.name} 攻击');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    }
  }

  /// AI攻击后的死亡检测
  void _detectAIDeath(domain.Card targetCard) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final st = ref.read(aiGameProvider);
      if (st == null) return;
      final playerId = widget.playerId;
      final playerBoard = st.player1.id == playerId ? st.player1.board : st.player2.board;
      final stillAlive = playerBoard.any((c) => c.id == targetCard.id);
      if (!stillAlive) {
        AudioManager.I.death();
        setState(() => _dyingCards[targetCard.id] = targetCard);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() => _dyingCards.remove(targetCard.id));
        });
      }
    });
  }
}
