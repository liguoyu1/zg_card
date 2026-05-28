import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/hero.dart' as hero;
import '../../domain/models/card.dart' as domain;
import '../../domain/models/player.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/services.dart' show AIDifficulty;
import '../providers/game_provider.dart';

/// 游戏主界面
class GameScreen extends ConsumerStatefulWidget {
  final String playerId;
  final hero.Hero playerHero;
  final AIDifficulty difficulty;

  const GameScreen({
    super.key,
    required this.playerId,
    required this.playerHero,
    this.difficulty = AIDifficulty.normal,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  domain.Card? _selectedCard;
  domain.Card? _selectedMinion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiGameProvider.notifier).startAIGame(
        playerId: widget.playerId,
        playerHero: widget.playerHero,
        difficulty: widget.difficulty,
      );
      // 玩家先手，开始第一回合
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(aiGameProvider.notifier).startTurn(widget.playerId);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(aiGameProvider);

    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (gameState.isEnded) {
      return _buildEndScreen(gameState);
    }

    final currentPlayer = gameState.activePlayer;
    final opponent = gameState.opponent;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildOpponentArea(opponent),
            const SizedBox(height: 8),
            _buildBoardArea(opponent.board, isOpponent: true),
            const Divider(height: 16),
            _buildBoardArea(currentPlayer.board, isOpponent: false),
            const SizedBox(height: 8),
            _buildPlayerArea(currentPlayer),
            _buildEndTurnButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentArea(Player opponent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildHeroAvatar(opponent.hero),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(opponent.hero.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  Text(' ${opponent.health}'),
                  if (opponent.armor > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.shield, color: Colors.blue, size: 16),
                    Text(' ${opponent.armor}'),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildManaDisplay(opponent),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.brown[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('${opponent.handCount}', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea(Player player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              _buildHeroAvatar(player.hero),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.hero.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      Text(' ${player.health}'),
                      if (player.armor > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.shield, color: Colors.blue, size: 16),
                        Text(' ${player.armor}'),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _buildManaDisplay(player),
            ],
          ),
          const SizedBox(height: 8),
          _buildHandArea(player.hand),
        ],
      ),
    );
  }

  Widget _buildHeroAvatar(hero.Hero hero) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.brown[400],
      child: Text(
        hero.name[0],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildManaDisplay(Player player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[400],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${player.mana}/${player.maxMana}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea(List<domain.Card> board, {required bool isOpponent}) {
    if (board.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            isOpponent ? '敌方战场' : '我方战场',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: board.length,
        itemBuilder: (context, index) {
          final card = board[index];
          final isSelected = _selectedMinion?.id == card.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _onMinionTap(card, isOpponent),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.yellow[200] : _getRarityColor(card.rarity),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.black54,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${card.cost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.attack}/${card.health}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (card.keywords.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: card.keywords.take(2).map((k) {
                          return Text(_getKeywordSymbol(k), style: const TextStyle(fontSize: 10));
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandArea(List<domain.Card> hand) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hand.length,
        itemBuilder: (context, index) {
          final card = hand[index];
          final isSelected = _selectedCard?.id == card.id;
          final canPlay = (ref.read(aiGameProvider)?.activePlayer.mana ?? 0) >= card.cost;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _onCardTap(card),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.yellow[100] : _getRarityColor(card.rarity),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : (canPlay ? Colors.black54 : Colors.grey),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: canPlay ? Colors.blue : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${card.cost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.name.length > 4 ? '${card.name.substring(0, 4)}..' : card.name,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(_getTypeSymbol(card.type), style: const TextStyle(fontSize: 12)),
                    if (card.isMinion || card.isWeapon)
                      Text(
                        '${card.attack}/${card.health}',
                        style: TextStyle(
                          fontSize: 12,
                          color: card.attack > 0 ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCardTap(domain.Card card) {
    final gameState = ref.read(aiGameProvider);
    if (gameState == null) return;
    
    final isMyCard = gameState.activePlayer.hand.any((c) => c.id == card.id);
    if (!isMyCard) return;
    
    // 如果是随从牌且有足够法力，直接打出
    if (card.isMinion && card.cost <= gameState.activePlayer.mana) {
      if (gameState.activePlayer.boardCount < 7) {
        ref.read(aiGameProvider.notifier).playCard(widget.playerId, card);
        setState(() {
          _selectedCard = null;
        });
        return;
      }
    }
    
    // 如果是法术牌，直接打出
    if (card.isSpell && card.cost <= gameState.activePlayer.mana) {
      ref.read(aiGameProvider.notifier).playCard(widget.playerId, card);
      setState(() {
        _selectedCard = null;
      });
      return;
    }
    
    setState(() {
      if (_selectedCard?.id == card.id) {
        _selectedCard = null;
      } else {
        _selectedCard = card;
        _selectedMinion = null;
      }
    });
  }

  void _onMinionTap(domain.Card card, bool isOpponent) {
    final gameState = ref.read(aiGameProvider);
    if (gameState == null) return;
    
    // 如果选择了己方随从，再点击敌方随从则发起攻击
    if (_selectedMinion != null && isOpponent) {
      // 检查是否可以攻击（嘲讽规则）
      final opponent = gameState.opponent;
      final hasTaunt = opponent.board.any((c) => c.hasTaunt);
      if (hasTaunt && !card.hasTaunt) {
        // 必须攻击嘲讽目标
        return;
      }
      
      ref.read(aiGameProvider.notifier).minionAttack(
        widget.playerId,
        _selectedMinion!,
        card.id,
      );
      
      setState(() {
        _selectedMinion = null;
      });
      return;
    }
    
    // 选择己方随从进行攻击准备
    if (!isOpponent && card.canAttack) {
      setState(() {
        if (_selectedMinion?.id == card.id) {
          _selectedMinion = null;
        } else {
          _selectedMinion = card;
          _selectedCard = null;
        }
      });
    }
  }

  Widget _buildEndTurnButton() {
    final gameState = ref.read(aiGameProvider);
    if (gameState == null || gameState.activePlayerId != widget.playerId) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _endTurn(),
          icon: const Icon(Icons.skip_next),
          label: const Text('结束回合'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
  
  void _endTurn() {
    final gameState = ref.read(aiGameProvider);
    if (gameState == null) return;
    
    ref.read(aiGameProvider.notifier).endTurn(widget.playerId);
    
    // AI回合
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _executeAITurn();
      }
    });
  }
  
  void _executeAITurn() {
    final aiNotifier = ref.read(aiGameProvider.notifier);
    final state = ref.read(aiGameProvider);
    if (state == null) return;
    
    final aiPlayerId = state.opponent.id;
    
    // AI出牌
    final aiPlayer = state.opponent;
    final playableCards = aiPlayer.hand.where((c) => c.cost <= aiPlayer.mana).toList();
    
    for (final card in playableCards) {
      if (aiPlayer.boardCount < 7 && card.isMinion) {
        aiNotifier.playCard(aiPlayerId, card);
      }
    }
    
    // AI回合开始（恢复法力+抽牌）
    aiNotifier.startTurn(aiPlayerId);
    
    // AI结束回合
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        aiNotifier.endTurn(aiPlayerId);
        
        // 玩家回合开始
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(aiGameProvider.notifier).startTurn(widget.playerId);
            setState(() {});
          }
        });
      }
    });
  }

  Color _getRarityColor(domain.Rarity rarity) {
    switch (rarity) {
      case domain.Rarity.common: return Colors.grey[200]!;
      case domain.Rarity.rare: return Colors.blue[100]!;
      case domain.Rarity.epic: return Colors.purple[100]!;
      case domain.Rarity.legendary: return Colors.orange[100]!;
    }
  }

  String _getTypeSymbol(domain.CardType type) {
    switch (type) {
      case domain.CardType.minion: return '👤';
      case domain.CardType.spell: return '✨';
      case domain.CardType.weapon: return '⚔️';
    }
  }

  String _getKeywordSymbol(domain.Keyword keyword) {
    switch (keyword) {
      case domain.Keyword.charge: return '⚡';
      case domain.Keyword.taunt: return '🛡️';
      case domain.Keyword.divineShield: return '⛊';
      case domain.Keyword.deathrattle: return '💀';
      case domain.Keyword.battlecry: return '📢';
      case domain.Keyword.windfury: return '🌪️';
      case domain.Keyword.poisonous: return '☠️';
      case domain.Keyword.lifesteal: return '💉';
      default: return '';
    }
  }

  Widget _buildEndScreen(GameState gameState) {
    final isWinner = gameState.winnerId == widget.playerId;
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isWinner ? '🎉 胜利!' : '😢 失败',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              isWinner ? '恭喜你击败了AI!' : 'AI击败了你',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}