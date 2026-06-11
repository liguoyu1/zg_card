import 'dart:math';
import 'package:flutter/material.dart';
import 'package:warring_states_card/domain/models/models.dart' as domain;
import 'package:warring_states_card/domain/services/pack_service.dart';
import 'package:warring_states_card/core/audio/audio_manager.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import 'package:warring_states_card/main.dart' show adService;
import '../widgets/pack_opening_effect.dart';
import '../../core/theme/app_theme.dart';

class PackScreen extends StatefulWidget {
  final String playerId;
  final List<domain.Card> cardPool;

  const PackScreen({super.key, required this.playerId, required this.cardPool});

  @override
  State<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends State<PackScreen> with TickerProviderStateMixin {
  final PackService _packService = PackService();
  bool _isOpening = false;
  bool _isAdOpening = false;
  int _playerGold = 500;
  final List<domain.Card> _openedCards = [];
  bool _showAnimation = false;
  List<domain.Card>? _animatingCards;
  AnimationController? _totalController;

  @override
  void dispose() {
    _totalController?.dispose();
    super.dispose();
  }

  Color _rarityColor(domain.Rarity r) {
    switch (r) {
      case domain.Rarity.rare: return const Color(0xFF4A7C59);
      case domain.Rarity.epic: return const Color(0xFF8B4513);
      case domain.Rarity.legendary: return const Color(0xFFC59538);
      default: return AppTheme.parchment;
    }
  }

  void _openPack() {
    if (_isOpening || widget.cardPool.isEmpty) return;
    if (_playerGold < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleService.I.t('pack.gold_insufficient'))),
      );
      return;
    }
    final result = _packService.openPack(widget.cardPool, count: 5);
    setState(() {
      _playerGold -= 50;
      _isOpening = true;
      _openedCards.clear();
      _animatingCards = result.cards;
      _showAnimation = true;
    });
  }

  void _openPackFromAd() async {
    if (_isAdOpening) return;
    setState(() => _isAdOpening = true);

    final rewarded = await adService.showRewardedAd(placementId: 'free_pack');
    if (!rewarded) {
      setState(() => _isAdOpening = false);
      return;
    }

    final result = _packService.openPack(widget.cardPool, count: 5);
    setState(() {
      _animatingCards = result.cards;
      _showAnimation = true;
      _isAdOpening = false;
    });
  }

  void _onAnimationComplete() {
    if (_animatingCards != null) {
      _showOpenedCards(_animatingCards!);
    }
    setState(() {
      _showAnimation = false;
      _animatingCards = null;
      _isOpening = false;
    });
  }

  void _showOpenedCards(List<domain.Card> cards) {
    setState(() => _openedCards.addAll(cards));
    AudioManager.I.playCard();

    _totalController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200 + _openedCards.length * 200),
    );
    _totalController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_showAnimation && _animatingCards != null) {
      return PackOpeningEffect(
        cards: _animatingCards!,
        onComplete: _onAnimationComplete,
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('pack.title'),
            style: const TextStyle(color: AppTheme.parchment, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.agedWood,
        iconTheme: const IconThemeData(color: AppTheme.goldAccent),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.cardBack.withAlpha(120),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 24),
                const SizedBox(width: 8),
                Text('$_playerGold ${LocaleService.I.t('pack.gold')}',
                    style: const TextStyle(color: AppTheme.goldAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                Text(LocaleService.I.t('pack.gold_price'),
                    style: TextStyle(color: AppTheme.parchment.withAlpha(180), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _openedCards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 160, height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBack,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.goldAccent, width: 2),
                            boxShadow: [BoxShadow(color: AppTheme.goldAccent.withAlpha(50), blurRadius: 20)],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.card_giftcard, color: AppTheme.goldAccent, size: 48),
                                const SizedBox(height: 8),
                                Text(LocaleService.I.t('pack.pack_name'),
                                    style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isOpening ? null : _openPack,
                          icon: const Icon(Icons.vpn_key),
                          label: Text(LocaleService.I.t('pack.btn_open')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldAccent,
                            foregroundColor: AppTheme.agedWood,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _isAdOpening ? null : _openPackFromAd,
                          child: Text(LocaleService.I.t('pack.btn_open_ad'),
                              style: TextStyle(
                                color: _isAdOpening
                                    ? AppTheme.parchment.withAlpha(80)
                                    : AppTheme.parchment.withAlpha(120),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              )),
                        ),
                      ],
                    ),
                  )
                : _buildOpenedCards(),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenedCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(LocaleService.I.t('pack.opened_cards'),
              style: const TextStyle(color: AppTheme.goldAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 0.72, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _openedCards.length,
              itemBuilder: (ctx, i) {
                final c = _openedCards[i];
                final color = _rarityColor(c.rarity);
                return Container(
                  decoration: BoxDecoration(
                    color: color.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [BoxShadow(color: color.withAlpha(50), blurRadius: 8)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: color, size: 28),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(c.name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                      Text('${c.cost}费 ${c.attack}/${c.health}',
                          style: TextStyle(color: color.withAlpha(200), fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _openedCards.clear()),
            icon: const Icon(Icons.refresh, color: AppTheme.parchment),
            label: Text(LocaleService.I.t('pack.btn_again'),
                style: const TextStyle(color: AppTheme.parchment)),
          ),
        ],
      ),
    );
  }
}
