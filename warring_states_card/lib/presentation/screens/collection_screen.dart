import 'package:flutter/material.dart';
import 'package:warring_states_card/domain/models/models.dart' as domain;
import 'package:warring_states_card/l10n/locale_service.dart';
import 'deck_editor_screen.dart';
import '../../core/theme/app_theme.dart';

class CollectionScreen extends StatefulWidget {
  final String playerId;
  final List<domain.Card> ownedCards;

  const CollectionScreen({
    super.key,
    required this.playerId,
    required this.ownedCards,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSchool = 'all';
  String _costFilter = 'all';

  static const _schoolTabs = [
    ('全部', 'all'),
    ('兵家', 'bingjia'),
    ('法家', 'fajia'),
    ('儒家', 'rujia'),
    ('道家', 'daojia'),
    ('墨家', 'mojia'),
    ('阴阳家', 'yinyangjia'),
    ('纵横家', 'zonghengjia'),
  ];

  static const _costFilters = [
    ('全部', 'all'),
    ('0-3费', '0-3'),
    ('4-6费', '4-6'),
    ('7+费', '7+'),
  ];

  Color _rarityColor(domain.Rarity r) {
    switch (r) {
      case domain.Rarity.rare:
        return const Color(0xFF4A7C59);
      case domain.Rarity.epic:
        return const Color(0xFF8B4513);
      case domain.Rarity.legendary:
        return const Color(0xFFC59538);
      default:
        return AppTheme.parchment;
    }
  }

  Color _ownerColor(domain.CardOwner o) {
    switch (o) {
      case domain.CardOwner.bingjia:
        return const Color(0xFFC0392B);
      case domain.CardOwner.fajia:
        return const Color(0xFF2E86C1);
      case domain.CardOwner.rujia:
        return const Color(0xFF27AE60);
      case domain.CardOwner.daojia:
        return const Color(0xFF8E44AD);
      case domain.CardOwner.mojia:
        return const Color(0xFFD35400);
      case domain.CardOwner.yinyangjia:
        return const Color(0xFF1ABC9C);
      case domain.CardOwner.zonghengjia:
        return const Color(0xFFF1C40F);
      default:
        return Colors.grey;
    }
  }

  String _ownerLabel(domain.CardOwner o) {
    switch (o) {
      case domain.CardOwner.bingjia:
        return LocaleService.I.t('owner.bingjia');
      case domain.CardOwner.fajia:
        return LocaleService.I.t('owner.fajia');
      case domain.CardOwner.rujia:
        return LocaleService.I.t('owner.rujia');
      case domain.CardOwner.daojia:
        return LocaleService.I.t('owner.daojia');
      case domain.CardOwner.mojia:
        return LocaleService.I.t('owner.mojia');
      case domain.CardOwner.yinyangjia:
        return LocaleService.I.t('owner.yinyangjia');
      case domain.CardOwner.zonghengjia:
        return LocaleService.I.t('owner.zonghengjia');
      default:
        return LocaleService.I.t('owner.neutral');
    }
  }

  domain.CardOwner? _schoolToOwner(String school) {
    switch (school) {
      case 'bingjia':
        return domain.CardOwner.bingjia;
      case 'fajia':
        return domain.CardOwner.fajia;
      case 'rujia':
        return domain.CardOwner.rujia;
      case 'daojia':
        return domain.CardOwner.daojia;
      case 'mojia':
        return domain.CardOwner.mojia;
      case 'yinyangjia':
        return domain.CardOwner.yinyangjia;
      case 'zonghengjia':
        return domain.CardOwner.zonghengjia;
      default:
        return null;
    }
  }

  List<domain.Card> get _filteredCards {
    var cards = widget.ownedCards;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    if (_selectedSchool != 'all') {
      final owner = _schoolToOwner(_selectedSchool);
      if (owner != null) {
        cards = cards.where((c) => c.owner == owner).toList();
      }
    }

    if (_costFilter != 'all') {
      switch (_costFilter) {
        case '0-3':
          cards = cards.where((c) => c.cost >= 0 && c.cost <= 3).toList();
          break;
        case '4-6':
          cards = cards.where((c) => c.cost >= 4 && c.cost <= 6).toList();
          break;
        case '7+':
          cards = cards.where((c) => c.cost >= 7).toList();
          break;
      }
    }

    return cards;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCards;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('collection.title'),
            style: const TextStyle(color: AppTheme.parchment, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.agedWood,
        iconTheme: const IconThemeData(color: AppTheme.goldAccent),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeckEditorScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 18),
            label: Text('编组',
                style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.parchment, fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索卡牌名称...',
                hintStyle: TextStyle(color: AppTheme.parchment.withAlpha(100)),
                prefixIcon: Icon(Icons.search, color: AppTheme.goldAccent, size: 20),
                filled: true,
                fillColor: AppTheme.agedWood,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.goldAccent.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.goldAccent.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // School tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _schoolTabs.map((tab) {
                final label = tab.$1;
                final value = tab.$2;
                final selected = _selectedSchool == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label, style: TextStyle(fontSize: 12, color: selected ? AppTheme.bgDark : AppTheme.parchment)),
                    selected: selected,
                    selectedColor: AppTheme.goldAccent,
                    backgroundColor: AppTheme.agedWood,
                    side: BorderSide(color: selected ? AppTheme.goldAccent : AppTheme.goldAccent.withAlpha(60)),
                    onSelected: (_) => setState(() => _selectedSchool = value),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),

          // Cost filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: _costFilters.map((f) {
                final label = f.$1;
                final value = f.$2;
                final selected = _costFilter == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(label, style: TextStyle(fontSize: 11, color: selected ? AppTheme.bgDark : AppTheme.parchment)),
                    selected: selected,
                    selectedColor: AppTheme.goldAccent,
                    backgroundColor: AppTheme.agedWood,
                    side: BorderSide(color: selected ? AppTheme.goldAccent : AppTheme.goldAccent.withAlpha(40)),
                    onSelected: (_) => setState(() => _costFilter = value),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('共 ${filtered.length} 张',
                  style: TextStyle(color: AppTheme.parchment.withAlpha(150), fontSize: 12)),
            ),
          ),

          // Card grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(LocaleService.I.t('collection.empty'),
                        style: const TextStyle(color: AppTheme.parchment)))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      final rColor = _rarityColor(c.rarity);
                      final oColor = _ownerColor(c.owner);
                      return GestureDetector(
                        onTap: () => _showCardDetail(context, c),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [oColor.withAlpha(80), rColor.withAlpha(60)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: rColor, width: 2),
                            boxShadow: [BoxShadow(color: rColor.withAlpha(40), blurRadius: 6)],
                          ),
                          child: Stack(
                            children: [
                              // Card content
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(c.name,
                                          style: const TextStyle(color: AppTheme.parchment, fontSize: 13, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 6),
                                      if (c.isMinion)
                                        Text('⚔${c.attack} ❤${c.health}',
                                            style: TextStyle(color: AppTheme.parchment.withAlpha(200), fontSize: 11)),
                                      if (!c.isMinion)
                                        Text(c.type == domain.CardType.spell ? '法术' : '武器',
                                            style: TextStyle(color: AppTheme.parchment.withAlpha(150), fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: oColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Cost badge top-left
                              Positioned(
                                top: -4,
                                left: -4,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.parchment, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${c.cost}',
                                      style: const TextStyle(color: AppTheme.bgDark, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCardDetail(BuildContext context, domain.Card card) {
    final rColor = _rarityColor(card.rarity);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: rColor, width: 2),
        ),
        title: Text(card.name, style: TextStyle(color: rColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleService.I.t('collection.cost_stat', args: {
                'cost': card.cost.toString(),
                'attack': card.attack.toString(),
                'health': card.health.toString(),
              }),
              style: const TextStyle(color: AppTheme.parchment)),
            const SizedBox(height: 8),
            Text(card.description, style: TextStyle(color: AppTheme.parchment.withAlpha(180), fontSize: 13)),
            if (card.flavor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"${card.flavor}"',
                  style: TextStyle(color: AppTheme.parchment.withAlpha(100), fontStyle: FontStyle.italic, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭', style: TextStyle(color: AppTheme.goldAccent)),
          ),
        ],
      ),
    );
  }
}
