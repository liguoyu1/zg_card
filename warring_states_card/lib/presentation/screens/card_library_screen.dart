import 'package:flutter/material.dart' hide Card;
import 'package:warring_states_card/domain/models/card.dart';
import 'package:warring_states_card/domain/services/card_data_provider.dart';
import 'package:warring_states_card/domain/services/card_pool.dart';
import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import '../../core/theme/app_theme.dart';

/// 卡牌库 — 自有卡 + 周试用 + 愿望单
class CardLibraryScreen extends StatefulWidget {
  const CardLibraryScreen({super.key});

  @override
  State<CardLibraryScreen> createState() => _CardLibraryScreenState();
}

class _CardLibraryScreenState extends State<CardLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _ownedIds = {};
  Set<String> _trialIds = {};
  List<String> _favoriteIds = [];
  List<Card> _ownedCards = [];
  List<Card> _trialCards = [];
  List<Card> _favoriteCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _ownedIds = await CardPool.loadOwnedIds();
    _trialIds = await CardPool.getWeeklyTrials();
    final all = CardDataProvider.getAllCards();

    final saved = await SaveManager.loadCollection();
    _favoriteIds = List<String>.from(saved?.favoriteCards ?? []);

    _ownedCards = all.where((c) => _ownedIds.contains(c.id)).toList();
    _trialCards = all.where((c) => _trialIds.contains(c.id)).toList();
    _favoriteCards = all.where((c) => _favoriteIds.contains(c.id)).toList();

    if (mounted) setState(() => _loading = false);
  }

  Color _costColor(int cost) {
    if (cost <= 2) return Colors.grey[700]!;
    if (cost <= 5) return Colors.blue[700]!;
    if (cost <= 7) return Colors.purple[700]!;
    return Colors.orange[700]!;
  }

  String _typeName(CardType t) => switch (t) {
        CardType.minion => '随从',
        CardType.spell => '法术',
        CardType.weapon => '武器',
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('卡牌库', style: TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.cardBack,
        iconTheme: const IconThemeData(color: AppTheme.parchment),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldAccent,
          labelColor: AppTheme.goldAccent,
          unselectedLabelColor: AppTheme.parchment.withAlpha(153),
          tabs: [
            Tab(text: '自有 (${_ownedCards.length + _trialCards.length})'),
            Tab(text: '愿望单 (${_favoriteCards.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OwnedCardsView(
            ownedCards: _ownedCards,
            trialCards: _trialCards,
            trialIds: _trialIds,
            favoriteIds: _favoriteIds,
            onCollectionChanged: _load,
          ),
          _WishlistView(
            cards: _favoriteCards,
            favoriteIds: _favoriteIds,
            onCollectionChanged: _load,
          ),
        ],
      ),
    );
  }
}

/// 自有 + 试用卡牌视图
class _OwnedCardsView extends StatefulWidget {
  final List<Card> ownedCards;
  final List<Card> trialCards;
  final Set<String> trialIds;
  final List<String> favoriteIds;
  final VoidCallback onCollectionChanged;

  const _OwnedCardsView({
    required this.ownedCards,
    required this.trialCards,
    required this.trialIds,
    required this.favoriteIds,
    required this.onCollectionChanged,
  });

  @override
  State<_OwnedCardsView> createState() => _OwnedCardsViewState();
}

class _OwnedCardsViewState extends State<_OwnedCardsView> {
  String _filter = 'all';

  List<Card> get _filteredCards {
    final merged = [...widget.ownedCards, ...widget.trialCards];
    final seen = <String>{};
    final deduped = merged.where((c) => seen.add(c.id)).toList();
    deduped.sort((a, b) => a.cost.compareTo(b.cost));
    if (_filter == 'all') return deduped;
    return deduped.where((c) => c.owner.name == _filter).toList();
  }

  void _showDetail(Card card) {
    final isOwned = widget.ownedCards.any((c) => c.id == card.id);
    final isTrial = widget.trialIds.contains(card.id);
    final isFav = widget.favoriteIds.contains(card.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBack,
        title: Text(card.name,
            style: const TextStyle(color: AppTheme.parchment)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('费用: ${card.cost} | 类型: ${_typeName(card.type)}',
                style: const TextStyle(color: AppTheme.parchment)),
            if (card.isMinion)
              Text('⚔${card.attack} ❤${card.health}',
                  style: const TextStyle(color: AppTheme.parchment)),
            const SizedBox(height: 8),
            Text(card.description,
                style: TextStyle(
                    color: AppTheme.parchment.withAlpha(204),
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            if (isOwned)
              Chip(
                label: const Text('已拥有', style: TextStyle(color: Colors.green)),
                backgroundColor: Colors.green.withAlpha(51),
              ),
            if (isTrial && !isOwned)
              Chip(
                label: const Text('试用中', style: TextStyle(color: Colors.orange)),
                backgroundColor: Colors.orange.withAlpha(51),
              ),
            if (!isOwned && !isTrial)
              Chip(
                label: const Text('未拥有', style: TextStyle(color: Colors.grey)),
                backgroundColor: Colors.grey.withAlpha(51),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final col = await SaveManager.loadCollection();
              if (col == null) return;
              final newFav = isFav
                  ? col.favoriteCards.where((id) => id != card.id).toList()
                  : [...col.favoriteCards, card.id];
              await SaveManager.saveCollection(
                  col.copyWith(favoriteCards: newFav));
              widget.onCollectionChanged();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              isFav ? '移出愿望单' : '加入愿望单',
              style: TextStyle(
                  color: isFav ? Colors.redAccent : AppTheme.goldAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _typeName(CardType t) => switch (t) {
        CardType.minion => '随从',
        CardType.spell => '法术',
        CardType.weapon => '武器',
      };

  @override
  Widget build(BuildContext context) {
    final cards = _filteredCards;
    return Column(
      children: [
        // 过滤栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.cardBack,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', '全部'),
                _filterChip('bingjia', '兵家'),
                _filterChip('fajia', '法家'),
                _filterChip('rujia', '儒家'),
                _filterChip('daojia', '道家'),
                _filterChip('mojia', '墨家'),
                _filterChip('yinyangjia', '阴阳家'),
                _filterChip('zonghengjia', '纵横家'),
                _filterChip('neutral', '中立'),
              ],
            ),
          ),
        ),
        // 卡牌网格
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Text('暂无卡牌',
                      style: TextStyle(color: AppTheme.parchment.withAlpha(128))))
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => _buildCardItem(cards[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : AppTheme.parchment)),
        selected: isSelected,
        selectedColor: AppTheme.goldAccent,
        backgroundColor: Colors.grey[800],
        onSelected: (v) => setState(() => _filter = value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCardItem(Card card) {
    final isTrial = widget.trialIds.contains(card.id);
    final isOwned = widget.ownedCards.any((c) => c.id == card.id);
    final costColor = _costColor(card.cost);

    return GestureDetector(
      onTap: () => _showDetail(card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isTrial && !isOwned
                ? Colors.cyan.withAlpha(153)
                : AppTheme.parchment.withAlpha(76),
            width: isTrial && !isOwned ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 底色（按费用）
              Container(color: costColor),
              // 费用角标
              Positioned(
                left: 2,
                top: 2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: Colors.blue, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${card.cost}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              // 名称
              Positioned(
                left: 2,
                right: 2,
                top: 24,
                child: Text(
                  card.name,
                  style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black87)]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              // 攻击/生命
              if (card.isMinion)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration:
                        BoxDecoration(color: Colors.black.withAlpha(160)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('${card.attack}',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        Text('${card.health}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              // 试用角标
              if (isTrial && !isOwned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withAlpha(179),
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(4)),
                    ),
                    child: const Text('试用',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _costColor(int cost) {
    if (cost <= 2) return Colors.grey[700]!;
    if (cost <= 5) return Colors.blue[700]!;
    if (cost <= 7) return Colors.purple[700]!;
    return Colors.orange[700]!;
  }
}

/// 愿望单视图
class _WishlistView extends StatelessWidget {
  final List<Card> cards;
  final List<String> favoriteIds;
  final VoidCallback onCollectionChanged;

  const _WishlistView({
    required this.cards,
    required this.favoriteIds,
    required this.onCollectionChanged,
  });

  Color _costColor(int cost) {
    if (cost <= 2) return Colors.grey[700]!;
    if (cost <= 5) return Colors.blue[700]!;
    if (cost <= 7) return Colors.purple[700]!;
    return Colors.orange[700]!;
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 64, color: AppTheme.parchment.withAlpha(128)),
            const SizedBox(height: 16),
            Text('愿望单为空',
                style:
                    TextStyle(color: AppTheme.parchment.withAlpha(128), fontSize: 16)),
            const SizedBox(height: 8),
            Text('在有卡牌详情中点击「加入愿望单」',
                style: TextStyle(
                    color: AppTheme.parchment.withAlpha(102), fontSize: 12)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final card = cards[i];
          return GestureDetector(
            onTap: () => _showDetail(context, card),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.redAccent.withAlpha(76), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: _costColor(card.cost)),
                        Positioned(
                          left: 2,
                          top: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Colors.blue, shape: BoxShape.circle),
                            child: Center(
                              child: Text('${card.cost}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 2,
                          right: 2,
                          top: 24,
                          child: Text(
                            card.name,
                            style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black87)
                                ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 红心移除
                Positioned(
                  right: 2,
                  top: 2,
                  child: GestureDetector(
                    onTap: () async {
                      final col = await SaveManager.loadCollection();
                      if (col == null) return;
                      await SaveManager.saveCollection(col.copyWith(
                          favoriteCards: col.favoriteCards
                              .where((id) => id != card.id)
                              .toList()));
                      onCollectionChanged();
                    },
                    child: const Icon(Icons.favorite,
                        color: Colors.redAccent, size: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Card card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBack,
        title: Text(card.name,
            style: const TextStyle(color: AppTheme.parchment)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('费用: ${card.cost} | 类型: ${_typeName(card.type)}',
                style: const TextStyle(color: AppTheme.parchment)),
            if (card.isMinion)
              Text('⚔${card.attack} ❤${card.health}',
                  style: const TextStyle(color: AppTheme.parchment)),
            const SizedBox(height: 8),
            Text(card.description,
                style: TextStyle(
                    color: AppTheme.parchment.withAlpha(204),
                    fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final col = await SaveManager.loadCollection();
              if (col == null) return;
              await SaveManager.saveCollection(col.copyWith(
                  favoriteCards: col.favoriteCards
                      .where((id) => id != card.id)
                      .toList()));
              onCollectionChanged();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('移出愿望单',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _typeName(CardType t) => switch (t) {
        CardType.minion => '随从',
        CardType.spell => '法术',
        CardType.weapon => '武器',
      };
}
