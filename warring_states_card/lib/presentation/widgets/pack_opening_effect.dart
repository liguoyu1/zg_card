import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/models.dart' as domain;
import '../../l10n/locale_service.dart';

/// 卡包打开动画 — 包裂开 + 金色粒子 + 卡牌翻转
class PackOpeningEffect extends StatefulWidget {
  final List<domain.Card> cards;
  final VoidCallback onComplete;

  const PackOpeningEffect({
    super.key,
    required this.cards,
    required this.onComplete,
  });

  @override
  State<PackOpeningEffect> createState() => _PackOpeningEffectState();
}

class _PackOpeningEffectState extends State<PackOpeningEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _openAnim;
  late Animation<double> _particleAnim;
  int _revealedIndex = -1;
  List<_Particle> _particles = [];

  static const _gold = Color(0xFFB8860B);
  static const _bg = Color(0xFF2C1810);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _openAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );
    _particleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _particles = List.generate(30, (_) => _Particle(Random()));
    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
    _ctrl.addListener(() {
      final progress = _ctrl.value;
      if (progress > 0.5 && _revealedIndex < 0) {
        setState(() => _revealedIndex = 0);
      }
      if (progress > 0.7 && _revealedIndex < 1) {
        setState(() => _revealedIndex = 1);
      }
      if (progress > 0.85 && _revealedIndex < 2) {
        setState(() => _revealedIndex = 2);
      }
      if (progress > 0.95 && _revealedIndex < 3) {
        setState(() => _revealedIndex = 3);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _rarityGlow(domain.Rarity r) {
    switch (r) {
      case domain.Rarity.rare: return const Color(0xFF4A7C59);
      case domain.Rarity.epic: return const Color(0xFF8B4513);
      case domain.Rarity.legendary: return const Color(0xFFC59538);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: Stack(
        children: [
          // 金色粒子
          ..._particles.map((p) => Positioned(
            left: p.x * MediaQuery.of(context).size.width,
            top: p.y * MediaQuery.of(context).size.height,
            child: Opacity(
              opacity: _particleAnim.value < p.phase ? 0 : (1 - _particleAnim.value) * (1 - p.phase),
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _gold.withAlpha(100), blurRadius: 4)],
                ),
              ),
            ),
          )),
          // 裂开动画（光柱）
          if (_openAnim.value < 0.8)
            Center(
              child: Container(
                width: 200,
                height: 200 * (1 - _openAnim.value * 0.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold, width: 2),
                  gradient: RadialGradient(
                    colors: [
                      _gold.withAlpha((0.5 - _openAnim.value * 0.5).clamp(0, 1).toInt()),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: _gold, size: 48 * (1 - _openAnim.value)),
                      Text(LocaleService.I.t('pack.opening'), style: const TextStyle(color: _gold)),
                    ],
                  ),
                ),
              ),
            ),
          // 卡牌翻转
          if (_revealedIndex >= 0)
            ...List.generate(min(_revealedIndex + 1, widget.cards.length), (i) {
              final card = widget.cards[i];
              final glow = _rarityGlow(card.rarity);
              final angle = (i - 1.5) * 0.15;
              final revealProgress = (_ctrl.value - 0.5 - i * 0.15).clamp(0, 0.15) / 0.15;
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 - 100 + i * 60,
                top: MediaQuery.of(context).size.height / 2 - 40,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle)
                    ..rotateX((1 - revealProgress) * pi),
                  child: Container(
                    width: 70, height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _bg,
                      border: Border.all(color: glow, width: revealProgress > 0.5 ? 2 : 0),
                      boxShadow: revealProgress > 0.5
                          ? [BoxShadow(color: glow.withAlpha(80), blurRadius: 8)]
                          : null,
                    ),
                    child: revealProgress > 0.5
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${card.cost}', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                              Text(card.name, style: TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [Colors.brown.shade800, Colors.brown.shade900],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(child: Icon(Icons.star, color: Colors.amber, size: 20)),
                          ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Particle {
  final double x, y, phase;
  _Particle(Random r) : x = r.nextDouble(), y = r.nextDouble(), phase = r.nextDouble();
}
