import 'package:flutter/material.dart' hide Card;
import 'package:warring_states_card/data/card_image_service.dart';
import 'package:warring_states_card/data/cards/cards.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import 'package:warring_states_card/domain/models/card.dart';

import '../../core/theme/app_theme.dart';

class BasicCardScreen extends StatefulWidget {
  const BasicCardScreen({super.key});
  @override
  State<BasicCardScreen> createState() => _BasicCardScreenState();
}

class _BasicCardScreenState extends State<BasicCardScreen> with TickerProviderStateMixin {
  Card? _selectedCard;
  bool _showDetail = false;
  String _filterFaction = 'all';

  late AnimationController _slideController;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleUp;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideUp = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _scaleUp = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  List<Card> _getAllCards() {
    final allCards = <Card>[];
    final allPlayers = getAllHeroes();
    for (final h in allPlayers) {
      allCards.addAll(getPresetDeck(h.owner));
    }
    // Deduplicate by id
    final seen = <String>{};
    return allCards.where((c) => seen.add(c.id)).toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
  }

  List<Card> _getFilteredCards() {
    final all = _getAllCards();
    if (_filterFaction == 'all') return all;
    return all.where((c) => c.owner.name == _filterFaction).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _getFilteredCards();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('基础出牌', style: TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.cardBack,
        iconTheme: const IconThemeData(color: AppTheme.parchment),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppTheme.parchment),
            onSelected: (v) => setState(() { _filterFaction = v; _selectedCard = null; _showDetail = false; _slideController.reverse(); }),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'bingjia', child: Text('兵家')),
              const PopupMenuItem(value: 'fajia', child: Text('法家')),
              const PopupMenuItem(value: 'rujia', child: Text('儒家')),
              const PopupMenuItem(value: 'daojia', child: Text('道家')),
              const PopupMenuItem(value: 'mojia', child: Text('墨家')),
              const PopupMenuItem(value: 'yinyangjia', child: Text('阴阳家')),
              const PopupMenuItem(value: 'zonghengjia', child: Text('纵横家')),
              const PopupMenuItem(value: 'neutral', child: Text('中立')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 卡牌详情区域（选中时展开）
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showDetail ? 220 : 0,
            child: _showDetail && _selectedCard != null ? _buildDetailPanel(_selectedCard!) : null,
          ),
          // 卡牌网格
          Expanded(
            child: cards.isEmpty
                ? Center(child: Text('暂无卡牌', style: TextStyle(color: AppTheme.parchment.withAlpha(128))))
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (_, i) => _buildCardItem(cards[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(Card card) {
    final isSelected = _selectedCard?.id == card.id;
    final imgPath = card.imageAsset.isNotEmpty
        ? card.imageAsset
        : CardImageService.getImageAsset(card.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCard?.id == card.id) {
            _showDetail = !_showDetail;
            _showDetail ? _slideController.forward() : _slideController.reverse();
          } else {
            _selectedCard = card;
            _showDetail = true;
            _slideController.forward(from: 0);
          }
        });
      },
      child: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          final isThis = _selectedCard?.id == card.id;
          return Transform.translate(
            offset: isThis ? _slideUp.value * 100 : Offset.zero,
            child: Transform.scale(
              scale: isThis ? _scaleUp.value : 1.0,
              child: Opacity(
                opacity: isThis && _showDetail ? _fadeIn.value : 1.0,
                child: _buildCardMini(card, imgPath, isSelected),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardMini(Card card, String imgPath, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.goldAccent : AppTheme.parchment.withAlpha(76),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.goldAccent.withAlpha(76), blurRadius: 8)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景
            if (imgPath.isNotEmpty)
              Image.asset(imgPath, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _getCostColor(card.cost)))
            else
              Container(color: _getCostColor(card.cost)),
            // 费用角标
            Positioned(
              left: 2, top: 2,
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: Center(child: Text('${card.cost}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
            ),
            // 名称
            Positioned(
              left: 2, right: 2, top: 22,
              child: Text(card.name, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black87)]),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
            // 攻击/生命
            if (card.isMinion)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(160)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('${card.attack}', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${card.health}', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(Card card) {
    final imgPath = card.imageAsset.isNotEmpty
        ? card.imageAsset
        : CardImageService.getImageAsset(card.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBack,
        border: Border(bottom: BorderSide(color: AppTheme.goldAccent.withAlpha(128))),
      ),
      child: Row(
        children: [
          // 放大卡牌
          SizedBox(
            width: 80, height: 110,
            child: _buildCardMini(card, imgPath, true),
          ),
          const SizedBox(width: 16),
          // 信息区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card.name, style: const TextStyle(color: AppTheme.parchment, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('费用: ${card.cost}  |  类型: ${_typeName(card.type)}', style: TextStyle(color: AppTheme.parchment.withAlpha(179), fontSize: 13)),
                if (card.isMinion) ...[
                  const SizedBox(height: 4),
                  Text('攻击: ${card.attack}  |  生命: ${card.health}', style: TextStyle(color: AppTheme.parchment.withAlpha(179), fontSize: 13)),
                ],
                if (card.keywords.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, children: card.keywords.map((k) => _keywordBadge(k)).toList()),
                ],
                const SizedBox(height: 4),
                Text(card.description, style: TextStyle(color: AppTheme.parchment.withAlpha(230), fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keywordBadge(Keyword kw) {
    final info = _keywordInfo(kw);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: info.color.withAlpha(51),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: info.color.withAlpha(128)),
      ),
      child: Text(info.name, style: TextStyle(color: info.color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  ({String name, Color color}) _keywordInfo(Keyword kw) => switch (kw) {
    Keyword.charge => (name: '冲锋', color: Colors.yellow),
    Keyword.taunt => (name: '嘲讽', color: Colors.grey),
    Keyword.divineShield => (name: '圣盾', color: Colors.white),
    Keyword.windfury => (name: '风怒', color: Colors.cyan),
    Keyword.lifesteal => (name: '吸血', color: Colors.red),
    Keyword.poisonous => (name: '剧毒', color: Colors.green),
    Keyword.battlecry => (name: '战吼', color: Colors.blue),
    Keyword.deathrattle => (name: '亡语', color: Colors.brown),
    Keyword.stealth => (name: '潜行', color: Colors.purple),
    Keyword.silence => (name: '沉默', color: Colors.grey),
    Keyword.inspire => (name: '激励', color: Colors.orange),
    Keyword.combo => (name: '连击', color: Colors.red),
    Keyword.draw => (name: '抽牌', color: Colors.blue),
  };

  String _typeName(CardType t) => switch (t) {
    CardType.minion => '随从',
    CardType.spell => '法术',
    CardType.weapon => '武器',
  };

  Color _getCostColor(int cost) {
    if (cost <= 2) return Colors.grey[700]!;
    if (cost <= 5) return Colors.blue[700]!;
    if (cost <= 7) return Colors.purple[700]!;
    return Colors.orange[700]!;
  }
}
