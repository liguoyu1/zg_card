import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warring_states_card/data/cards/cards.dart';
import '../../l10n/locale_service.dart';
import 'package:warring_states_card/domain/models/models.dart';

/// 卡组管理服务
class DeckManager {
  /// 验证卡组是否有效
  static bool validateDeck(List<Card> cards) {
    if (cards.length != 30) return false;
    
    // 检查卡牌数量限制（同名卡最多2张，传说最多1张）
    final cardCounts = <String, int>{};
    for (final card in cards) {
      cardCounts[card.id] = (cardCounts[card.id] ?? 0) + 1;
      
      if (card.rarity == Rarity.legendary && cardCounts[card.id]! > 1) {
        return false;
      }
      if (cardCounts[card.id]! > 2) {
        return false;
      }
    }
    
    return true;
  }
  
  /// 获取预设卡组
  static List<Card> getPresetDeck(CardOwner owner) {
    final allCards = getAllCards();
    return allCards.where((c) => c.owner == owner).take(30).toList();
  }
  
  /// 创建空卡组
  static List<Card> createEmptyDeck() {
    return [];
  }
  
  /// 添加卡牌到卡组
  static List<Card> addCard(List<Card> deck, Card card) {
    if (deck.length >= 30) return deck;
    
    final count = deck.where((c) => c.id == card.id).length;
    if (card.rarity == Rarity.legendary && count >= 1) return deck;
    if (count >= 2) return deck;
    
    return [...deck, card];
  }
  
  /// 从卡组移除卡牌
  static List<Card> removeCard(List<Card> deck, int index) {
    if (index < 0 || index >= deck.length) return deck;
    
    final newDeck = List<Card>.from(deck);
    newDeck.removeAt(index);
    return newDeck;
  }
}

/// 卡组编辑界面
class DeckEditScreen extends ConsumerStatefulWidget {
  
  const DeckEditScreen({
    super.key,
    required this.owner,
    this.onSave,
  });
  final CardOwner owner;
  final Function(List<Card>)? onSave;
  
  @override
  ConsumerState<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends ConsumerState<DeckEditScreen> {
  late List<Card> _deck;
  String _searchQuery = '';
  String _selectedOwner = 'all';
  
  @override
  void initState() {
    super.initState();
    _deck = [];
    _selectedOwner = widget.owner.name;
  }
  
  @override
  Widget build(BuildContext context) {
    final allCards = _getFilteredCards();
    final deckCards = _deck;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleService.I.t('deck_edit.title', args: {'count': '${deckCards.length}'})),
        actions: [
          if (_deck.length == 30)
            TextButton(
              onPressed: () => _saveDeck(),
              child: Text(LocaleService.I.t('deck_edit.save'), style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Row(
        children: [
          // 左侧：可用卡牌列表
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildOwnerFilter(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: allCards.length,
                    itemBuilder: (context, index) {
                      return _buildCardItem(allCards[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          // 右侧：当前卡组
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.brown[300],
                  child: Row(
                    children: [
                      const Icon(Icons.style, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        LocaleService.I.t('deck_edit.deck_label', args: {'count': '${deckCards.length}'}),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: deckCards.length,
                    itemBuilder: (context, index) {
                      return _buildDeckCard(deckCards[index], index);
                    },
                  ),
                ),
                _buildDeckStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText: LocaleService.I.t('deck_edit.search_hint'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }
  
  Widget _buildOwnerFilter() {
    final owners = [
      ('all', LocaleService.I.t('deck_edit.all')),
      (widget.owner.name, _getOwnerName(widget.owner)),
      ('neutral', LocaleService.I.t('deck_edit.neutral')),
    ];
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: owners.map((o) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o.$2),
              selected: _selectedOwner == o.$1,
              onSelected: (selected) {
                if (selected) setState(() => _selectedOwner = o.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
  
  List<Card> _getFilteredCards() {
    var cards = getAllCards();
    
    if (_selectedOwner != 'all') {
      final owner = _parseOwner(_selectedOwner);
      if (owner != null) {
        cards = cards.where((c) => c.owner == owner).toList();
      }
    }
    
    if (_searchQuery.isNotEmpty) {
      cards = cards.where((c) => c.name.contains(_searchQuery)).toList();
    }
    
    return cards;
  }
  
  Widget _buildCardItem(Card card) {
    final count = _deck.where((c) => c.id == card.id).length;
    final canAdd = _deck.length < 30 && 
        (card.rarity != Rarity.legendary || count < 1) && 
        count < 2;
    
    return GestureDetector(
      onTap: canAdd ? () => _addCard(card) : null,
      child: Container(
        decoration: BoxDecoration(
          color: _getRarityColor(card.rarity),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black26),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${card.cost}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.name.length > 4 ? card.name.substring(0, 4) : card.name,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (card.isMinion)
                  Text(
                    '${card.attack}/${card.health}',
                    style: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeckCard(Card card, int index) {
    return Dismissible(
      key: Key('${card.id}_$index'),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red[300],
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _deck.removeAt(index));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _getRarityColor(card.rarity),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue[700],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${card.cost}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                card.name,
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeckStats() {
    final manaCurve = <int, int>{};
    for (final card in _deck) {
      manaCurve[card.cost] = (manaCurve[card.cost] ?? 0) + 1;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleService.I.t('deck_edit.mana_curve'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: List.generate(8, (cost) {
              final count = manaCurve[cost] ?? 0;
              return Text(
                '$cost: $count',
                style: TextStyle(fontSize: 10, color: count > 8 ? Colors.red : Colors.grey[700]),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  void _addCard(Card card) {
    setState(() => _deck = DeckManager.addCard(_deck, card));
  }
  
  void _saveDeck() {
    if (_deck.length == 30 && DeckManager.validateDeck(_deck)) {
      widget.onSave?.call(_deck);
      Navigator.pop(context);
    }
  }
  
  Color _getRarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common: return Colors.grey[200]!;
      case Rarity.rare: return Colors.blue[100]!;
      case Rarity.epic: return Colors.purple[100]!;
      case Rarity.legendary: return Colors.orange[100]!;
    }
  }
  
  String _getOwnerName(CardOwner owner) {
    final names = {
      CardOwner.bingjia: LocaleService.I.t('owner.bingjia'),
      CardOwner.fajia: LocaleService.I.t('owner.fajia'),
      CardOwner.rujia: LocaleService.I.t('owner.rujia'),
      CardOwner.daojia: LocaleService.I.t('owner.daojia'),
      CardOwner.mojia: LocaleService.I.t('owner.mojia'),
      CardOwner.yinyangjia: LocaleService.I.t('owner.yinyangjia'),
      CardOwner.zonghengjia: LocaleService.I.t('owner.zonghengjia'),
      CardOwner.neutral: LocaleService.I.t('owner.neutral'),
    };
    return names[owner] ?? LocaleService.I.t('owner.neutral');
  }
  
  CardOwner? _parseOwner(String name) {
    final owners = {
      'bingjia': CardOwner.bingjia,
      'fajia': CardOwner.fajia,
      'rujia': CardOwner.rujia,
      'daojia': CardOwner.daojia,
      'mojia': CardOwner.mojia,
      'yinyangjia': CardOwner.yinyangjia,
      'zonghengjia': CardOwner.zonghengjia,
      'neutral': CardOwner.neutral,
    };
    return owners[name];
  }
}