import 'package:flutter/material.dart';
import 'package:warring_states_card/domain/models/card.dart' as domain;
import 'package:warring_states_card/domain/models/deck.dart';
import 'package:warring_states_card/domain/services/card_data_provider.dart';
import 'package:warring_states_card/domain/services/card_pool.dart';
import 'package:warring_states_card/l10n/locale_service.dart';

const _bg = Color(0xFF2C1810);
const _parchment = Color(0xFFE8D5B7);
const _gold = Color(0xFFB8860B);
const _wood = Color(0xFF3D2B1F);

const _schoolColors = {
  domain.CardOwner.neutral: Colors.grey,
  domain.CardOwner.bingjia: Color(0xFFC0392B),
  domain.CardOwner.fajia: Color(0xFF2E86C1),
  domain.CardOwner.rujia: Color(0xFF27AE60),
  domain.CardOwner.daojia: Color(0xFF8E44AD),
  domain.CardOwner.mojia: Color(0xFFD35400),
  domain.CardOwner.yinyangjia: Color(0xFF1ABC9C),
  domain.CardOwner.zonghengjia: Color(0xFFF39C12),
};

class DeckEditorScreen extends StatefulWidget {
  const DeckEditorScreen({super.key, this.existingDeck});
  final Deck? existingDeck;

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  final _nameController = TextEditingController();
  final List<domain.Card> _selectedCards = [];
  List<domain.Card> _poolCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPool();
    if (widget.existingDeck != null) {
      _nameController.text = widget.existingDeck!.name;
      _selectedCards.addAll(widget.existingDeck!.cards);
    }
  }

  Future<void> _loadPool() async {
    final ownedIds = await CardPool.loadOwnedIds();
    final trialIds = await CardPool.getWeeklyTrials();
    final allCards = CardDataProvider.getAllCards();
    final usable = CardPool.getUsableCards(allCards, ownedIds, trialIds);
    setState(() {
      _poolCards = usable.toSet().toList()..sort((a, b) => a.cost.compareTo(b.cost));
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addCard(domain.Card card) {
    if (_selectedCards.length >= 30) return;
    setState(() => _selectedCards.add(card));
  }

  void _removeCard(domain.Card card) {
    setState(() {
      final idx = _selectedCards.lastIndexOf(card);
      if (idx >= 0) _selectedCards.removeAt(idx);
    });
  }

  Map<int, int> get _costCurve {
    final curve = <int, int>{};
    for (var c = 0; c <= 10; c++) {
      curve[c] = _selectedCards.where((e) => e.cost == c).length;
    }
    return curve;
  }

  Widget _buildCostCurve() {
    final curve = _costCurve;
    final maxCount = curve.values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: curve.entries.map((e) {
          final barH = maxCount > 0 ? (e.value / maxCount) * 60.0 : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${e.value}',
                      style: const TextStyle(
                          color: _parchment, fontSize: 10)),
                  Container(
                    height: barH.clamp(0, 60),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.8),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                  Text('${e.key}',
                      style: const TextStyle(
                          color: _parchment, fontSize: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardItem(domain.Card card, {bool inDeck = false}) {
    final schoolColor = _schoolColors[card.owner] ?? Colors.grey;
    return Card(
      color: _wood,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        onTap: () => inDeck ? _removeCard(card) : _addCard(card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Cost badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('${card.cost}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 8),
              // School chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: schoolColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: schoolColor),
                ),
                child: Text(card.owner.name,
                    style:
                        TextStyle(color: schoolColor, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              // Name
              Expanded(
                child: Text(
                  card.name,
                  style: const TextStyle(
                      color: _parchment,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Attack / Health for minions
              if (card.isMinion)
                Text(
                  '⚔${card.attack} ❤${card.health}',
                  style: const TextStyle(color: _parchment, fontSize: 12),
                ),
              if (card.isSpell)
                const Text('✨',
                    style: TextStyle(color: _gold, fontSize: 12)),
              if (card.isWeapon)
                const Text('🗡',
                    style: TextStyle(color: _gold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel({
    required String title,
    required List<domain.Card> cards,
    required bool inDeck,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: _wood,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              if (!inDeck)
                Text(LocaleService.I.t('deck_editor.card_count', args: {'count': '${_selectedCards.length}'}),
                    style: TextStyle(
                        color: _selectedCards.length == 30
                            ? Colors.redAccent
                            : _parchment,
                        fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Text(LocaleService.I.t('deck_editor.empty'),
                      style: TextStyle(color: _parchment, fontSize: 16)))
              : ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (_, i) =>
                      _buildCardItem(cards[i], inDeck: inDeck),
                ),
        ),
      ],
    );
  }

  Future<void> _saveDeck() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMsg(LocaleService.I.t('deck_editor.name_empty'));
      return;
    }
    if (_selectedCards.length < 30) {
      _showMsg(LocaleService.I.t('deck_editor.card_missing', args: {'count': '${_selectedCards.length}'}));
      return;
    }
    final deck = Deck(
      id: widget.existingDeck?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      heroId: widget.existingDeck?.heroId ?? 'neutral',
      cards: List.from(_selectedCards),
      createdAt: widget.existingDeck?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(deck);
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(LocaleService.I.t('deck_editor.title'), style: const TextStyle(color: _gold)),
        backgroundColor: _wood,
        iconTheme: const IconThemeData(color: _gold),
        actions: [
          TextButton.icon(
            onPressed: _saveDeck,
            icon: const Icon(Icons.save, color: _gold),
            label: Text(LocaleService.I.t('deck_editor.save'), style: const TextStyle(color: _gold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Deck name & cost curve
          Container(
            padding: const EdgeInsets.all(8),
            color: _wood,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: LocaleService.I.t('deck_editor.name_hint'),
                    hintStyle: TextStyle(color: _parchment),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _gold)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _gold, width: 2)),
                  ),
                  style: const TextStyle(color: _parchment),
                  cursorColor: _gold,
                ),
                const SizedBox(height: 8),
                _buildCostCurve(),
              ],
            ),
          ),
          // Two panels
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildPanel(
                    title: LocaleService.I.t('deck_editor.pool_title'),
                    cards: _poolCards,
                    inDeck: false,
                  ),
                ),
                Container(width: 1, color: _gold.withValues(alpha: 0.5)),
                Expanded(
                  child: _buildPanel(
                    title: LocaleService.I.t('deck_editor.deck_title'),
                    cards: _selectedCards,
                    inDeck: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
