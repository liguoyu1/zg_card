import 'package:flutter/material.dart';

import '../../domain/models/card.dart' as domain;
import '../../l10n/locale_service.dart';

const _parchment = Color(0xFFE8D5B7);
const _goldAccent = Color(0xFFB8860B);
const _bgDark = Color(0xFF2C1810);

/// 战后选牌弹窗 — 从 3 张随机卡中选择 1 张加入临时卡组
class RewardPicker extends StatefulWidget {

  const RewardPicker({
    super.key,
    required this.cards,
    required this.onSelected,
  });
  final List<domain.Card> cards;
  final void Function(domain.Card selected) onSelected;

  @override
  State<RewardPicker> createState() => _RewardPickerState();
}

class _RewardPickerState extends State<RewardPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(179),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocaleService.I.t('roguelite.reward_title'),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _goldAccent)),
            const SizedBox(height: 8),
            Text(LocaleService.I.t('roguelite.reward_hint'),
                style: TextStyle(color: _parchment.withAlpha(179))),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _controller,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.cards.map((card) {
                  return _CardChoice(
                    card: card,
                    onTap: () {
                      widget.onSelected(card);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardChoice extends StatelessWidget {

  const _CardChoice({required this.card, required this.onTap});
  final domain.Card card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _parchment.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _goldAccent.withAlpha(100)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _parchment)),
            const SizedBox(height: 4),
            Text('⚔${card.attack} ❤${card.health}',
                style: TextStyle(fontSize: 12, color: _parchment.withAlpha(179))),
            const SizedBox(height: 4),
            Text('💰${card.cost}',
                style: TextStyle(fontSize: 12, color: _goldAccent.withAlpha(179))),
          ],
        ),
      ),
    );
  }
}
