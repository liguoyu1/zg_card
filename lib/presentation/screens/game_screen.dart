import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/hero.dart' as hero;
import '../../domain/models/card.dart' as domain;
import '../../domain/models/player.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/services.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/card_data_provider.dart';
import '../../domain/models/quest.dart';
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
  final bool isOnline;

  const GameScreen({
    super.key,
    required this.playerId,
    required this.playerHero,
    this.difficulty = AIDifficulty.normal,
    this.missionContext,
    this.runHp,
    this.opponentHero,
    this.isOnline = false,
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
  /// AI 暂停标记
  bool _aiPaused = false;
  final DateTime _gameStartTime = DateTime.now();
  int _totalDamageDealt = 0;
  bool _gameEndProcessed = false; // 防止重复处理
  String? _rewardCardName; // 战后奖励卡牌名称
  domain.Rarity? _rewardCardRarity;
  int _rewardGold = 0;
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
      ref.read(aiGameProvider.notifier).startMissionGame(
        playerId: widget.playerId,
        playerHero: widget.playerHero,
        opponentHero: widget.opponentHero!,
        difficulty: widget.difficulty,
        playerHealth: widget.runHp,
      );
    } else {
      ref.read(aiGameProvider.notifier).startAIGame(
        playerId: widget.playerId,
        playerHero: widget.playerHero,
        difficulty: widget.difficulty,
      );
    }
    // 立即开始第一回合
    if (mounted) {
      ref.read(aiGameProvider.notifier).startTurn(widget.playerId);
      AudioManager.I.manaCrystal();
      _isPlayerTurn = true;
      _startTurnTimer();
    }
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
        // 暂停遮罩
        if (_aiPaused)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _aiPaused = false),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.pause_circle, color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    const Text('已暂停', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('点击继续', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
                  ]),
                ),
              ),
            ),
          ),
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

  /// 胜利后生成随机奖励
  void _generateReward() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    if (rng % 100 < 5) {
      // 5%: 稀有卡
      final rarePool = CardDataProvider.getAllCards()
          .where((c) => c.rarity == domain.Rarity.rare && c.isMinion)
          .toList();
      if (rarePool.isNotEmpty) {
        final card = rarePool[rng % rarePool.length];
        _rewardCardName = card.name;
        _rewardCardRarity = card.rarity;
      }
    } else {
      // 95%: 1张普通卡 + 50-100金币
      final commonPool = CardDataProvider.getAllCards()
          .where((c) => c.rarity == domain.Rarity.common && c.isMinion)
          .toList();
      if (commonPool.isNotEmpty) {
        final card = commonPool[DateTime.now().millisecondsSinceEpoch % commonPool.length];
        _rewardCardName = card.name;
        _rewardCardRarity = card.rarity;
      }
      _rewardGold = 50 + (DateTime.now().millisecondsSinceEpoch % 51); // 50-100
    }
  }

  Widget _buildGameEndOverlay(GameState gameState) {
    final isPlayerWinner = gameState.winnerId == widget.playerId;
    Future.microtask(() {
      if (isPlayerWinner) {
        AudioManager.I.victory();
      } else {
        AudioManager.I.defeat();
      }
    });
    if (!_gameEndProcessed) {
      _gameEndProcessed = true;
      if (isPlayerWinner) _generateReward();

      if (widget.missionContext != null) {
        Future.microtask(() {
          widget.missionContext!.onComplete(isPlayerWinner);
        });
      }

      Future.microtask(() async {
        try {
          final now = DateTime.now();
          final duration = now.difference(_gameStartTime).inSeconds;
          final gs = ref.read(aiGameProvider);
          if (gs == null) return;
          final opponent = gs.player1.id == widget.playerId ? gs.player2 : gs.player1;

          final record = MatchRecord(
            id: const Uuid().v4(),
            timestamp: now,
            playerId: widget.playerId,
            opponentId: opponent.id,
            isWin: isPlayerWinner,
            duration: duration,
            playerHero: widget.playerHero.id,
            opponentHero: opponent.hero.id,
            playerRankScore: 0,
            opponentRankScore: 0,
          );
          await SaveManager.addMatchRecord(record);

          final pd = await SaveManager.loadPlayerData();
          if (pd != null) {
            final history = await SaveManager.loadMatchHistory();
            int curStreak = 0;
            for (int i = history.length - 1; i >= 0; i--) {
              if (history[i].isWin) curStreak++; else break;
            }
            final newStats = Map<String, int>.from(pd.stats);
            newStats['totalDamage'] = (newStats['totalDamage'] ?? 0) + _totalDamageDealt;
            newStats['currentWinStreak'] = curStreak;
            newStats['maxWinStreak'] = max(newStats['maxWinStreak'] ?? 0, curStreak);
            final heroKey = 'heroWins_${widget.playerHero.id}';
            newStats[heroKey] = (newStats[heroKey] ?? 0) + (isPlayerWinner ? 1 : 0);
            newStats['heroAnyWins'] = (newStats['heroAnyWins'] ?? 0) + (isPlayerWinner ? 1 : 0);
            if (isPlayerWinner) {
              newStats['totalGoldEarned'] = (newStats['totalGoldEarned'] ?? 0) + _rewardGold;
            }
            await SaveManager.savePlayerData(pd.copyWith(
              totalMatches: pd.totalMatches + 1,
              winCount: pd.winCount + (isPlayerWinner ? 1 : 0),
              exp: pd.exp + (isPlayerWinner ? 15 : 5),
              stats: newStats,
            ));

            final col = await SaveManager.loadCollection();
            final stats = AchievementService.buildStats(
              await SaveManager.loadPlayerData() ?? pd,
              col ?? Collection(),
              history,
            );
            final unlocked = await AchievementService.I.checkAchievements(
              alreadyAchieved: pd.achievedMedals,
              stats: stats,
            );
            if (unlocked.isNotEmpty && context.mounted) {
              _showAchievementUnlocks(unlocked);
            }
          }
        } catch (_) {}
      });
    }
    return GameEndOverlay(
      winnerId: gameState.winnerId!,
      isPlayerWinner: isPlayerWinner,
      onReturnToMenu: () {
        if (widget.runHp != null) {
          final player = gameState.player1.id == widget.playerId
              ? gameState.player1 : gameState.player2;
          Navigator.of(context).pop(RogueliteResult(
            victory: isPlayerWinner,
            remainingHp: isPlayerWinner ? player.health : 0,
            goldEarned: isPlayerWinner ? _rewardGold : 0,
          ));
        } else {
          context.go('/');
        }
      },
      onDoubleReward: isPlayerWinner ? _claimDoubleReward : null,
      rewardCardName: isPlayerWinner ? _rewardCardName : null,
      rewardCardRarity: isPlayerWinner ? _rewardCardRarity : null,
      rewardGold: isPlayerWinner ? _rewardGold : 0,
    );
  }

  void _claimDoubleReward() async {
    final rewarded = await adService.showRewardedAd(placementId: 'double_reward');
    if (!rewarded || !mounted) return;

    final pd = await SaveManager.loadPlayerData();
    if (pd == null) return;
    // 双倍：额外奖励同稀有度卡牌 + 再给一份金币
    final allCards = CardDataProvider.getAllCards();
    final pool = allCards.where((c) => c.rarity == (_rewardCardRarity ?? domain.Rarity.common) && c.isMinion).toList();
    final bonusCardId = pool.isEmpty ? null : pool[DateTime.now().millisecondsSinceEpoch % pool.length].id;
    final newCards = [...pd.unlockedCards, if (bonusCardId != null) bonusCardId];
    await SaveManager.savePlayerData(pd.copyWith(
      gold: pd.gold + _rewardGold,
      unlockedCards: newCards,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocaleService.I.t('game.reward_doubled')} +$_rewardGold ${LocaleService.I.t('common.gold')}')),
      );
    }
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

    // 响应式尺寸 — 原图 1:1.5，战场卡用 1:1.45 接近原图，防止两侧过度裁剪
    final screenWidth = MediaQuery.of(context).size.width;
    final boardCardWidth = min(66.0, screenWidth * 0.115);
    final boardCardHeight = boardCardWidth * 1.45;
    final handCardWidth = min(76.0, screenWidth * 0.13);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isShort = constraints.maxHeight < 700;
          final adjCW = min(boardCardWidth, isShort ? 64.0 : boardCardWidth);
          final adjCH = min(boardCardHeight, isShort ? 88.0 : boardCardHeight);
          final adjHW = isShort ? 72.0 : handCardWidth;
          return SafeArea(
            child: Container(
              decoration: AppTheme.boardDecoration,
              child: Column(
                children: [
                  // 对手区域（固定）
                  _buildHeroPanel(opponent, isOpponent: true, compact: isShort),
                  _buildHandArea(opponent, adjHW, gameState, isShort: isShort, isEnemy: true),
                  // 对战区：对手战场 + 分隔线 + 玩家战场（均分）
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildBoardSection(opponent.board, isOpponent: true, boardCardWidth: adjCW, boardCardHeight: adjCH, gameState: gameState),
                        ),
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
                        Expanded(
                          child: _buildBoardSection(player.board, isOpponent: false, boardCardWidth: adjCW, boardCardHeight: adjCH, gameState: gameState),
                        ),
                      ],
                    ),
                  ),
                  // 下方固定：玩家手牌 + 英雄面板 + 操作栏
                  _buildHandArea(player, adjHW, gameState, isShort: isShort),
                  _buildHeroPanel(player, compact: isShort),
                  _buildBottomControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建英雄面板（对手/玩家通用）
  /// 三列布局：头像+名 | 盾+武器 | 技能+手牌数/法力水晶
  Widget _buildHeroPanel(Player player, {bool isOpponent = false, bool compact = false}) {
    final vPad = compact ? 4.0 : 8.0;
    final hPad = compact ? 8.0 : 12.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: AppTheme.agedWood.withAlpha(128),
        border: Border(bottom: BorderSide(color: AppTheme.goldAccent.withAlpha(76))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 第一列：头像（血量在头像上）+ 英雄名
          GestureDetector(
            onTap: isOpponent && _isPlayerTurn && _selectedMinion != null ? _onOpponentHeroTap : null,
            child: Column(mainAxisSize: MainAxisSize.min,
              children: [
                HeroAvatar(hero: player.hero, health: player.health, armor: player.armor, hasWeapon: player.hasWeapon),
                const SizedBox(height: 2),
                SizedBox(width: 56,
                  child: Text(player.hero.name, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.parchment, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 第二列：盾在上，武器在下
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              if (player.armor > 0)
                _miniBadge(Icons.shield, '${player.armor}', AppTheme.armorOrange),
              if (player.armor > 0 && player.hasWeapon) const SizedBox(height: 4),
              if (player.hasWeapon) _buildWeaponDisplay(player.weapon!),
            ],
          ),
          const Spacer(),
          // 第三列：技能+手牌数（左右并列） / 法力水晶
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!isOpponent)
                  _buildHeroPowerButton(player)
                else
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, color: Colors.red.withAlpha(150), size: 14),
                    const SizedBox(width: 2),
                    Text(player.hero.heroPowerName, style: const TextStyle(color: Colors.red, fontSize: 10)),
                  ]),
                const SizedBox(width: 4),
                _buildHandCountBadge(player, isOpponent),
              ]),
              const SizedBox(height: 6),
              ManaCrystals(currentMana: player.mana, maxMana: player.maxMana),
            ],
          ),
        ]),
        // 底部行已移到 _buildBottomControls
      ]),
    );
  }

  /// 固定底部操作栏
  /// AI 回合时的暂停/继续按钮
  Widget _buildPauseControls() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => setState(() => _aiPaused = !_aiPaused),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _aiPaused ? AppTheme.goldAccent.withAlpha(180) : AppTheme.cardBack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _aiPaused ? AppTheme.goldAccent : Colors.red.withAlpha(100)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_aiPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(_aiPaused ? '继续' : '暂停', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      const SizedBox(width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
      const SizedBox(width: 4),
      Text(_aiPhaseText, style: const TextStyle(color: Colors.red, fontSize: 11)),
    ]);
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: AppTheme.goldAccent.withAlpha(76))),
      ),
      child: Row(children: [
        if (_isPlayerTurn)
          Expanded(child: _buildEndTurnButton())
        else
          Expanded(child: _buildPauseControls()),
        if (_battleLog.isNotEmpty) ...[
          const SizedBox(width: 8),
          GestureDetector(onTap: () => setState(() => _showBattleLog = !_showBattleLog),
            child: _miniBadge(Icons.article, '${_battleLog.length}', AppTheme.textSecondary)),
        ],
        const SizedBox(width: 4),
        _confirmExitButton(),
      ]),
    );
  }

  Widget _buildHandCountBadge(Player player, bool isOpponent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.goldAccent.withAlpha(100)),
        image: DecorationImage(
          image: isOpponent ? const AssetImage('assets/back/card_back.png') : const AssetImage('assets/icons/icons_icon_qin.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.style, color: AppTheme.parchment, size: 11),
        const SizedBox(width: 3),
        Text('${player.handCount}', style: const TextStyle(color: AppTheme.parchment, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
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

    // 战场容器高度 — 由外层 Expanded 撑满，只有空战场用固定最小高度
    final boardHeight = board.isEmpty ? 80.0 : boardCardHeight + 16;

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
          : LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final totalCardWidth = board.length * boardCardWidth;
                final needsOverlap = totalCardWidth > totalWidth;
                final visibleW = needsOverlap ? boardCardWidth * 0.55 : boardCardWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: board.asMap().entries.map((entry) {
                      final index = entry.key;
                      final card = entry.value;
                      final isSelected = _selectedMinion?.id == card.id;
                      // 确定选择状态
                      CardSelectionState selectionState = CardSelectionState.none;
                      if (isOpponent) {
                        if (_selectedMinion != null) {
                          final opponent = gameState.player1.id == widget.playerId
                              ? gameState.player2
                              : gameState.player1;
                          final hasTaunt = opponent.board.any((c) => c.hasTaunt);
                          if (!hasTaunt || card.hasTaunt) {
                            selectionState = CardSelectionState.targetable;
                          }
                        }
                      } else {
                        if (isSelected) {
                          selectionState = CardSelectionState.selected;
                        } else if (card.canAttack) {
                          selectionState = CardSelectionState.canAttack;
                        } else if (card.hasAttackedThisTurn) {
                          selectionState = CardSelectionState.hasAttacked;
                        }
                      }

                      final overlapOffset = (needsOverlap && index > 0)
                          ? -(boardCardWidth - visibleW)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(overlapOffset, 0),
                        child: Container(
                          width: needsOverlap && index > 0 ? visibleW : boardCardWidth,
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
                    }).toList(),
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
  Widget _buildHandArea(Player player, double handCardWidth, GameState gameState, {bool isShort = false, bool isEnemy = false}) {
    if (player.hand.isEmpty) {
      return Container(
        height: isShort ? 60 : 100,
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

    final count = player.hand.length;
    final isEnemyHand = player.id != widget.playerId;
    // 手牌多时折叠显示（每张更窄+重叠）
    const overlapThreshold = 5;
    final overlap = count > overlapThreshold && !isEnemyHand;
    final itemWidth = overlap
        ? handCardWidth * 0.7
        : handCardWidth;
    final totalOverlap = overlap ? (count - 1) * 4.0 : 0.0;

    return Container(
      height: isShort ? 90 : 120,
      padding: EdgeInsets.only(left: isShort ? 4 : 8, right: totalOverlap + (isShort ? 4 : 8)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        itemBuilder: (context, index) {
          final card = player.hand[index];

          if (isEnemyHand) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: handCardWidth,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3728),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF6B5B3E).withAlpha(120), width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, color: Color(0xFFB8860B), size: 20),
                ),
              ),
            );
          }

          final canAfford = player.mana >= card.cost;
          final isSelected = _selectedMinion?.id == card.id;

          // 确定手牌状态
          HandCardState cardState;
          if (isSelected) {
            cardState = HandCardState.selected;
          } else {
            cardState = canAfford
                ? HandCardState.playable
                : HandCardState.unplayable;
          }

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 4 : 0, right: overlap && index < count - 1 ? 0 : 4),
            child: SizedBox(
              width: itemWidth,
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

  Widget _confirmExitButton() {
    return GestureDetector(
      onTap: _confirmExit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.healthRed.withAlpha(180),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.exit_to_app, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text('退出', style: TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: const Text('确认退出', style: TextStyle(color: AppTheme.parchment)),
        content: const Text('退出将失去本局游戏进度，确认退出？', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () { Navigator.pop(ctx); context.go('/'); }, child: const Text('确认退出', style: TextStyle(color: AppTheme.healthRed))),
        ],
      ),
    );
  }

  Widget _miniBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30), borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
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

    return ElevatedButton.icon(
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

  /// 检查暂停，阻塞直到恢复
  Future<void> _checkPause() async {
    while (_aiPaused && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// 执行AI回合（可暂停）
  void _executeAITurn() async {
    setState(() => _aiPhaseText = LocaleService.I.t('game.ai_starting'));
    // Step 1: AI 回合开始（回蓝+抽牌）
    final initState = ref.read(aiGameProvider);
    if (initState == null) return;
    ref.read(aiGameProvider.notifier).startTurn(initState.activePlayer.id);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _checkPause();
    if (!mounted) return;
    setState(() => _aiPhaseText = LocaleService.I.t('game.ai_playing'));
    _aiPlayCards();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _checkPause();
    if (!mounted) return;
    setState(() => _aiPhaseText = LocaleService.I.t('game.ai_attacking'));
    await _aiAttack();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final curState = ref.read(aiGameProvider);
    if (curState == null) return;
    // Step 4: AI 结束回合 → 启动玩家回合
    ref.read(aiGameProvider.notifier).endTurn(curState.activePlayer.id);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ref.read(aiGameProvider.notifier).startTurn(widget.playerId);
      setState(() {
        _isPlayerTurn = true;
        _aiPaused = false;
      });
      _startTurnTimer();
    }
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

  /// 展示成就解锁弹窗
  void _showAchievementUnlocks(List<Achievement> unlocked) {
    if (!mounted) return;
    for (final ach in unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏆 ${ach.title}: ${ach.description} (${ach.goldReward}金币)'),
          backgroundColor: const Color(0xFF2D1B00),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
