import 'package:flutter/material.dart';

import '../../domain/models/card.dart' as domain;
import '../../l10n/locale_service.dart';

const _parchment = Color(0xFFE8D5B7);
const _goldAccent = Color(0xFFB8860B);
const _bgDark = Color(0xFF2C1810);
const _agedWood = Color(0xFF3D2B1F);
const _cardBack = Color(0xFF4A3728);

/// 稀有度 → 着色
Color _rarityColor(domain.Rarity r) => switch (r) {
  domain.Rarity.common => _parchment,
  domain.Rarity.rare => const Color(0xFF4FC3F7),
  domain.Rarity.epic => const Color(0xFFBA68C8),
  domain.Rarity.legendary => _goldAccent,
};

/// 结算弹窗 — 胜利时展示奖励与「看广告双倍」按钮。
class GameEndOverlay extends StatefulWidget {
  const GameEndOverlay({
    super.key,
    required this.winnerId,
    required this.isPlayerWinner,
    required this.onReturnToMenu,
    this.onDoubleReward,
    this.rewardCardName,
    this.rewardCardRarity,
    this.rewardGold = 0,
  });
  final String winnerId;
  final bool isPlayerWinner;
  final VoidCallback onReturnToMenu;
  final VoidCallback? onDoubleReward;
  final String? rewardCardName;
  final domain.Rarity? rewardCardRarity;
  final int rewardGold;

  @override
  State<GameEndOverlay> createState() => _GameEndOverlayState();
}

class _GameEndOverlayState extends State<GameEndOverlay>
    with SingleTickerProviderStateMixin {
  bool _doubleRewardClaimed = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.black.withAlpha((_fadeAnimation.value * 179).toInt()),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(scale: _scaleAnimation.value, child: child),
            ),
          );
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isPlayerWinner
                ? [_agedWood, _bgDark, const Color(0xFF4A3728)]
                : [const Color(0xFF2A0A0A), const Color(0xFF1A0A0A), const Color(0xFF0A0505)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isPlayerWinner
                ? _goldAccent.withAlpha(128)
                : Colors.red.withAlpha(76),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isPlayerWinner
                  ? _goldAccent.withAlpha(51)
                  : Colors.red.withAlpha(26),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultCharacter(),
            const SizedBox(height: 32),
            _buildResultTitle(),
            const SizedBox(height: 16),
            _buildResultDescription(),
            if (widget.isPlayerWinner) ...[
              const SizedBox(height: 24),
              _buildRewardSummary(),
            ],
            const SizedBox(height: 40),
            if (widget.isPlayerWinner && !_doubleRewardClaimed && widget.onDoubleReward != null)
              _buildDoubleRewardButton(),
            if (widget.isPlayerWinner && !_doubleRewardClaimed && widget.onDoubleReward != null)
              const SizedBox(height: 16),
            _buildReturnButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCharacter() {
    return Container(
      width: 160, height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isPlayerWinner
            ? _goldAccent.withAlpha(51)
            : Colors.red.withAlpha(51),
        border: Border.all(
          color: widget.isPlayerWinner ? _goldAccent : Colors.red[700]!,
          width: 4,
        ),
        boxShadow: widget.isPlayerWinner
            ? [BoxShadow(color: _goldAccent.withAlpha(128), blurRadius: 30, spreadRadius: 10)]
            : null,
      ),
      child: Center(
        child: Text(
          widget.isPlayerWinner
              ? LocaleService.I.t('game.victory_char')
              : LocaleService.I.t('game.defeat_char'),
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: widget.isPlayerWinner ? _goldAccent : Colors.red[700],
            shadows: widget.isPlayerWinner
                ? [Shadow(color: _goldAccent.withAlpha(179), blurRadius: 20)]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildResultTitle() {
    return Text(
      widget.isPlayerWinner
          ? LocaleService.I.t('game.victory')
          : LocaleService.I.t('game.defeat'),
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: widget.isPlayerWinner ? _parchment : Colors.red[300],
        letterSpacing: 4,
        shadows: [Shadow(color: Colors.black.withAlpha(128), blurRadius: 4, offset: const Offset(1, 1))],
      ),
    );
  }

  Widget _buildResultDescription() {
    return Text(
      widget.isPlayerWinner
          ? LocaleService.I.t('game.victory_desc')
          : LocaleService.I.t('game.defeat_desc'),
      style: TextStyle(fontSize: 18, color: _parchment.withAlpha(179)),
    );
  }

  Widget _buildRewardSummary() {
    final gold = widget.rewardGold;
    final cardName = widget.rewardCardName;
    final rarity = widget.rewardCardRarity;
    final hasReward = gold > 0 || cardName != null;

    if (!hasReward) {
      return Text(
        LocaleService.I.t('game.no_reward'),
        style: TextStyle(fontSize: 16, color: _parchment.withAlpha(153)),
      );
    }

    return Column(
      children: [
        Text(
          LocaleService.I.t('game.reward_title'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _goldAccent),
        ),
        const SizedBox(height: 8),
        if (gold > 0)
          Text(
            '💰 +$gold ${LocaleService.I.t('common.gold')}',
            style: const TextStyle(fontSize: 16, color: _parchment),
          ),
        if (cardName != null && rarity != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ $cardName',
              style: TextStyle(fontSize: 16, color: _rarityColor(rarity)),
            ),
          ),
      ],
    );
  }

  Widget _buildDoubleRewardButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          widget.onDoubleReward?.call();
          setState(() => _doubleRewardClaimed = true);
        },
        icon: const Icon(Icons.play_circle_outline),
        label: Text(LocaleService.I.t('game.ad_double_reward')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReturnButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isPlayerWinner
              ? [const Color(0xFFB8860B), const Color(0xFF8B6914)]
              : [_cardBack, _bgDark],
        ),
        border: Border.all(
          color: widget.isPlayerWinner ? _goldAccent : _parchment.withAlpha(128),
          width: 2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: widget.onReturnToMenu,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          LocaleService.I.t('game.btn_return'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _parchment, letterSpacing: 2),
        ),
      ),
    );
  }
}