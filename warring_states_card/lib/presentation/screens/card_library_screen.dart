import 'package:flutter/material.dart' hide Card;

import '../../core/theme/app_theme.dart';
import '../../data/card_image_service.dart';
import '../../data/data_version.dart';
import '../../data/persistence/save_manager.dart';
import '../../l10n/locale_service.dart';
import '../../domain/models/card.dart' as cm;
import '../../domain/services/card_data_provider.dart';
import '../../domain/services/card_pool.dart';

/// 卡牌库 — 全部卡牌按学派筛选，已拥有标记
class CardLibraryScreen extends StatefulWidget {
  const CardLibraryScreen({super.key});
  @override
  State<CardLibraryScreen> createState() => _CardLibraryScreenState();
}

class _CardLibraryScreenState extends State<CardLibraryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tc;
  Set<String> _owned = {};
  List<String> _ownedOrdered = []; // 保序（最新优先）
  Set<String> _trial = {};
  List<String> _fav = [];
  List<cm.Card> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    dataVersionNotifier.addListener(_load);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _tc.dispose();
    WidgetsBinding.instance.removeObserver(this);
    dataVersionNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final pd = await SaveManager.loadPlayerData();
    final ownedIds = pd?.unlockedCards ?? [];
    final owned = Set<String>.from(ownedIds);
    final trial = await CardPool.getWeeklyTrials();
    var col = await SaveManager.loadCollection();
    if (col == null) { col = Collection(); await SaveManager.saveCollection(col); }
    if (mounted) {
      setState(() {
      _owned = owned;
      _ownedOrdered = ownedIds.reversed.toList(); // 最新优先
      _trial = trial;
      _fav = List<String>.from(col!.favoriteCards);
      _all = CardDataProvider.getAllCards();
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('card_library.title'), style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.cardBack,
        iconTheme: const IconThemeData(color: AppTheme.parchment),
        bottom: TabBar(
          controller: _tc,
          indicatorColor: AppTheme.goldAccent,
          labelColor: AppTheme.goldAccent,
          unselectedLabelColor: AppTheme.parchment.withAlpha(153),
          tabs: [
            Tab(text: LocaleService.I.t('card_library.all_cards')),
            Tab(text: LocaleService.I.t('card_library.owned_count', args: {'count': '${_owned.length}'})),
            Tab(text: LocaleService.I.t('card_library.wishlist_count', args: {'count': '${_fav.length}'})),
          ],
        ),
      ),
      body: TabBarView(controller: _tc, children: [
        _CardGridView(allCards: _all, owned: _owned, trial: _trial, fav: _fav, onRefresh: _load),
        _CardGridView(allCards: _all.where((c) => _owned.contains(c.id) || _trial.contains(c.id)).toList(), owned: _owned, trial: _trial, ownedOrdered: _ownedOrdered, fav: _fav, onRefresh: _load),
        _WishlistView(cards: _all.where((c) => _fav.contains(c.id)).toList(), fav: _fav, onRefresh: _load),
      ]),
    );
  }
}

// ============ 卡牌网格（全部/已有共用） ============
class _CardGridView extends StatefulWidget {
  const _CardGridView({required this.allCards, required this.owned, required this.trial, this.ownedOrdered = const [], required this.fav, required this.onRefresh});
  final List<cm.Card> allCards; final Set<String> owned; final Set<String> trial;
  final List<String> ownedOrdered; final List<String> fav; final VoidCallback onRefresh;
  @override
  State<_CardGridView> createState() => _CardGridViewState();
}

class _CardGridViewState extends State<_CardGridView> {
  String _filter = 'all'; String _search = '';
  final _searchCtrl = TextEditingController();
  final bool _loadingImages = false;
  // 拥有状态筛选：all / owned / trial / unowned
  String _statusFilter = 'all';
  final _statusFilterCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); _statusFilterCtrl.dispose(); super.dispose(); }

  List<cm.Card> get _cards {
    var c = widget.allCards;
    if (_filter != 'all') c = c.where((x) => x.owner.name == _filter).toList();
    if (_search.isNotEmpty) c = c.where((x) => x.name.contains(_search)).toList();
    // 拥有状态筛选
    if (_statusFilter == 'owned') {
      c = c.where((x) => widget.owned.contains(x.id)).toList();
    } else if (_statusFilter == 'trial') c = c.where((x) => widget.trial.contains(x.id) && !widget.owned.contains(x.id)).toList();
    else if (_statusFilter == 'unowned') c = c.where((x) => !widget.owned.contains(x.id) && !widget.trial.contains(x.id)).toList();
    // 排序：已拥有 → 试用 → 未拥有（已拥有按最新获得顺序）
    c = c.toList()..sort((a, b) {
      final aStatus = widget.owned.contains(a.id) ? 0 : widget.trial.contains(a.id) ? 1 : 2;
      final bStatus = widget.owned.contains(b.id) ? 0 : widget.trial.contains(b.id) ? 1 : 2;
      if (aStatus != bStatus) return aStatus.compareTo(bStatus);
      // 同是已拥有：按 ownedOrdered 排序（最新优先）
      if (aStatus == 0) {
        final ai = widget.ownedOrdered.indexOf(a.id);
        final bi = widget.ownedOrdered.indexOf(b.id);
        return ai.compareTo(bi);
      }
      return 0;
    });
    return c;
  }

  void _detail(cm.Card card) async {
    final owned = widget.owned.contains(card.id);
    final trial = widget.trial.contains(card.id);
    final fav = widget.fav.contains(card.id);
    final imgPath = CardImageService.getImageByType(card.id, _typeEng(card.type));

    // 预加载不阻塞弹窗
    if (imgPath.isNotEmpty) {
      try { precacheImage(AssetImage(imgPath), context); } catch (_) {}
    }

    if (!mounted) return;
    showDialog(context: context, builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Material(color: Colors.transparent, child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 320, padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(color: AppTheme.cardBack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderGold.withAlpha(100))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // 卡面素材
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imgPath.isNotEmpty
                      ? Image.asset(imgPath, height: 200, width: double.infinity,
                          fit: BoxFit.cover, alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => _imgPlaceholder(card, 200))
                      : _imgPlaceholder(card, 200),
                ),
                const SizedBox(height: 12),
                Text(card.name, style: const TextStyle(color: AppTheme.goldAccent,
                    fontSize: 20, fontWeight: FontWeight.bold)),
                Text('${_typeName(card.type)} · ${_schoolName(card.owner)} · ${_rarityName(card.rarity)}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                if (card.isMinion)
                  Text('${card.cost}费 ⚔${card.attack} ❤${card.health}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                Text(card.description, textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.parchment.withAlpha(200), fontSize: 13, fontStyle: FontStyle.italic)),
                if (card.flavor.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(card.flavor, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10))),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _statusChip(owned ? LocaleService.I.t('card_library.owned') : trial ? LocaleService.I.t('card_library.trial') : LocaleService.I.t('card_library.unowned'),
                      owned ? AppTheme.healGreen : trial ? Colors.cyan : Colors.grey),
                  if (owned && card.rarity == cm.Rarity.common)
                    TextButton(onPressed: () => _dust(card, ctx),
                        child: Text(LocaleService.I.t('card_library.dust_action'), style: const TextStyle(color: Colors.orange))),
                ]),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var col = await SaveManager.loadCollection();
                      if (col == null) { col = Collection(); await SaveManager.saveCollection(col); }
                      final nf = fav
                          ? col.favoriteCards.where((id) => id != card.id).toList()
                          : [...col.favoriteCards, card.id];
                      await SaveManager.saveCollection(col.copyWith(favoriteCards: nf));
                      bumpDataVersion();
                      widget.onRefresh();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 18),
                    label: Text(fav ? LocaleService.I.t('card_library.wishlist_remove') : LocaleService.I.t('card_library.wishlist_add')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bgMedium),
                  ),
                ),
              ]),
            ),
            // 关闭按钮
            Positioned(
              right: 4, top: 4,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: AppTheme.parchment, size: 18),
                ),
              ),
            ),
          ],
        )),
      );
    });
  }

  void _dust(cm.Card card, BuildContext ctx) async {
    final d = await SaveManager.loadPlayerData();
    if (d == null) return;
    await SaveManager.savePlayerData(d.copyWith(
        unlockedCards: d.unlockedCards.where((id) => id != card.id).toList(),
        gems: d.gems + 5, gold: d.gold + 1));
    bumpDataVersion();
    widget.onRefresh(); if (ctx.mounted) Navigator.of(ctx).pop();
  }

  Widget _imgPlaceholder(cm.Card card, double h) => Container(height: h,
      color: _costColor(card.cost).withAlpha(100),
      child: Center(child: Text(card.name[0],
          style: const TextStyle(color: AppTheme.parchment, fontSize: 40))));

  Color _costColor(int cost) {
    if (cost <= 2) return Colors.grey[700]!;
    if (cost <= 5) return Colors.blue[700]!;
    if (cost <= 7) return Colors.purple[700]!;
    return Colors.orange[700]!;
  }

  Widget _statusChip(String s, Color c) => Chip(
      label: Text(s, style: TextStyle(color: c, fontSize: 11)),
      backgroundColor: c.withAlpha(30), visualDensity: VisualDensity.compact);

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Column(children: [
      // 搜索
      Container(padding: const EdgeInsets.fromLTRB(8, 6, 8, 2), color: AppTheme.cardBack,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppTheme.parchment, fontSize: 13),
            decoration: InputDecoration(
              hintText: LocaleService.I.t('card_library.search_hint'), hintStyle: TextStyle(color: AppTheme.textMuted.withAlpha(150)),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true, fillColor: AppTheme.bgDark,
            ),
            onChanged: (v) => setState(() => _search = v),
          )),
      // 学派过滤
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), color: AppTheme.cardBack,
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('all', LocaleService.I.t('card_library.all')), _chip('bingjia', LocaleService.I.t('owner.bingjia')), _chip('fajia', LocaleService.I.t('owner.fajia')),
                _chip('rujia', LocaleService.I.t('owner.rujia')), _chip('daojia', LocaleService.I.t('owner.daojia')), _chip('mojia', LocaleService.I.t('owner.mojia')),
                _chip('yinyangjia', LocaleService.I.t('owner.yinyangjia')), _chip('zonghengjia', LocaleService.I.t('owner.zonghengjia')), _chip('neutral', LocaleService.I.t('owner.neutral')),
              ]))),
      // 拥有状态过滤
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), color: AppTheme.cardBack,
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: [
                _ownChip('all', LocaleService.I.t('card_library.all')), _ownChip('owned', LocaleService.I.t('card_library.owned')),
                _ownChip('trial', LocaleService.I.t('card_library.trial')), _ownChip('unowned', LocaleService.I.t('card_library.unowned')),
              ]))),
      Expanded(child: cards.isEmpty
          ? Center(child: Text(LocaleService.I.t('card_library.no_cards'), style: TextStyle(color: AppTheme.parchment.withAlpha(128))))
          : Padding(padding: const EdgeInsets.all(8),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, childAspectRatio: 0.72, crossAxisSpacing: 6, mainAxisSpacing: 6),
                itemCount: cards.length,
                itemBuilder: (_, i) => _cardItem(cards[i]),
              ))),
    ]);
  }

  Widget _chip(String v, String l) {
    final s = _filter == v;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ChoiceChip(label: Text(l, style: TextStyle(fontSize: 11,
            color: s ? Colors.white : AppTheme.parchment)),
            selected: s, selectedColor: AppTheme.goldAccent,
            backgroundColor: Colors.grey[800],
            onSelected: (_) => setState(() => _filter = v),
            visualDensity: VisualDensity.compact));
  }

  Widget _ownChip(String v, String l) {
    final s = _statusFilter == v;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ChoiceChip(label: Text(l, style: TextStyle(fontSize: 11,
            color: s ? Colors.white : AppTheme.parchment)),
            selected: s, selectedColor: AppTheme.goldAccent,
            backgroundColor: Colors.grey[800],
            onSelected: (_) => setState(() => _statusFilter = v),
            visualDensity: VisualDensity.compact));
  }

  Color _rarityBorder(cm.Rarity r) => switch (r) {
    cm.Rarity.common => AppTheme.parchment.withAlpha(76),
    cm.Rarity.rare => Colors.blue.withAlpha(180),
    cm.Rarity.epic => Colors.purple.withAlpha(180),
    cm.Rarity.legendary => Colors.orange.withAlpha(200),
  };

  Widget _cardItem(cm.Card card) {
    final owned = widget.owned.contains(card.id);
    final trial = widget.trial.contains(card.id);
    final imgPath = CardImageService.getImageByType(card.id, _typeEng(card.type));
    final rc = _rarityBorder(card.rarity);
    final bc = trial ? Colors.cyan : owned ? AppTheme.healGreen : rc;

    return GestureDetector(
      onTap: () => _detail(card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bc, width: trial || owned ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(fit: StackFit.expand, children: [
            // 底图
            if (imgPath.isNotEmpty)
              Image.asset(imgPath, fit: BoxFit.cover, alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(color: _costColor(card.cost)))
            else
              Container(color: _costColor(card.cost)),
            // 暗色遮罩让文字可见
            Container(color: Colors.black.withAlpha(80)),
            // 费用
            Positioned(left: 3, top: 3, child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              child: Center(child: Text('${card.cost}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
            // 名称
            Positioned(left: 4, right: 4, top: 28,
                child: Text(card.name,
                    style: const TextStyle(fontSize: 9, color: Colors.white,
                        fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 3, color: Colors.black87)]),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            // 稀有度标签
            Positioned(top: 3, right: 3, child: _rarityBadge(card.rarity)),
            // 攻击/生命
            if (card.isMinion)
              Positioned(left: 0, right: 0, bottom: 0, child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(180)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Text('⚔${card.attack}', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('❤${card.health}', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]))),
            // 状态标签
            if (trial && !owned)
              Positioned(bottom: 0, right: 0, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(color: Colors.cyan.withAlpha(179),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4))),
                  child: Text(LocaleService.I.t('card_library.badge_trial'), style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)))),
            if (owned)
              Positioned(bottom: 0, left: 0, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.healGreen.withAlpha(150),
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(4))),
                  child: Text(LocaleService.I.t('card_library.badge_owned'), style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    );
  }

  Widget _rarityBadge(cm.Rarity r) {
    final (label, color) = switch (r) {
      cm.Rarity.common => ('C', Colors.grey),
      cm.Rarity.rare => ('R', Colors.blue),
      cm.Rarity.epic => ('E', Colors.purple),
      cm.Rarity.legendary => ('L', Colors.orange),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(color: color.withAlpha(160), borderRadius: BorderRadius.circular(3)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)));
  }

  String _typeEng(cm.CardType t) => switch (t) {
    cm.CardType.minion => 'minion', cm.CardType.spell => 'spell', cm.CardType.weapon => 'weapon',
  };
  String _typeName(cm.CardType t) => switch (t) {
    cm.CardType.minion => LocaleService.I.t('card_library.type_minion'), cm.CardType.spell => LocaleService.I.t('card_library.type_spell'), cm.CardType.weapon => LocaleService.I.t('card_library.type_weapon'),
  };
  String _schoolName(cm.CardOwner o) => switch (o) {
    cm.CardOwner.bingjia => LocaleService.I.t('owner.bingjia'), cm.CardOwner.fajia => LocaleService.I.t('owner.fajia'), cm.CardOwner.rujia => LocaleService.I.t('owner.rujia'),
    cm.CardOwner.daojia => LocaleService.I.t('owner.daojia'), cm.CardOwner.mojia => LocaleService.I.t('owner.mojia'), cm.CardOwner.yinyangjia => LocaleService.I.t('owner.yinyangjia'),
    cm.CardOwner.zonghengjia => LocaleService.I.t('owner.zonghengjia'), cm.CardOwner.neutral => LocaleService.I.t('owner.neutral'),
  };
  String _rarityName(cm.Rarity r) => switch (r) {
    cm.Rarity.common => LocaleService.I.t('card_library.rarity_common'), cm.Rarity.rare => LocaleService.I.t('card_library.rarity_rare'), cm.Rarity.epic => LocaleService.I.t('card_library.rarity_epic'), cm.Rarity.legendary => LocaleService.I.t('card_library.rarity_legendary'),
  };
}

// ============ 愿望单 ============
class _WishlistView extends StatelessWidget {
  const _WishlistView({required this.cards, required this.fav, required this.onRefresh});
  final List<cm.Card> cards; final List<String> fav; final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.favorite_border, size: 64, color: AppTheme.parchment.withAlpha(128)),
      const SizedBox(height: 16),
      Text(LocaleService.I.t('card_library.wishlist_empty'), style: const TextStyle(color: AppTheme.parchment, fontSize: 16)),
      const SizedBox(height: 8),
      Text(LocaleService.I.t('card_library.wishlist_hint'), style: TextStyle(color: AppTheme.parchment.withAlpha(100), fontSize: 12)),
    ]));
    }
    return Padding(padding: const EdgeInsets.all(8),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, childAspectRatio: 0.72, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemCount: cards.length,
          itemBuilder: (_, i) => Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent.withAlpha(76))),
            child: ClipRRect(borderRadius: BorderRadius.circular(5),
                child: Stack(fit: StackFit.expand, children: [
                  Container(color: Colors.grey[700]),
                  Positioned(left: 2, top: 2, child: Container(width: 22, height: 22,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: Center(child: Text('${cards[i].cost}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
                  Positioned(left: 2, right: 2, top: 24, child: Text(cards[i].name,
                      style: const TextStyle(fontSize: 8, color: Colors.white,
                          fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black87)]),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                ])),
          ),
        ));
  }
}