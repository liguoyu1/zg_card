import 'package:flutter/material.dart';
import 'package:warring_states_card/l10n/locale_service.dart';

class GameEndOverlay extends StatefulWidget {
  final String winnerId;
  final bool isPlayerWinner;
  final VoidCallback onReturnToMenu;
  final VoidCallback? onRevive;
  final VoidCallback? onDoubleGold;

  const GameEndOverlay({
    super.key,
    required this.winnerId,
    required this.isPlayerWinner,
    required this.onReturnToMenu,
    this.onRevive,
    this.onDoubleGold,
  });

  @override
  State<GameEndOverlay> createState() => _GameEndOverlayState();
}

class _GameEndOverlayState extends State<GameEndOverlay>
    with SingleTickerProviderStateMixin {
  bool _doubleGoldClaimed = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const _bgDark = Color(0xFF2C1810);
  static const _goldAccent = Color(0xFFB8860B);
  static const _parchment = Color(0xFFE8D5B7);
  static const _agedWood = Color(0xFF3D2B1F);
  static const _cardBack = Color(0xFF4A3728);

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
            const SizedBox(height: 48),
            if (!widget.isPlayerWinner && widget.onRevive != null)
              _buildReviveButton(),
            if (!widget.isPlayerWinner && widget.onRevive != null)
              const SizedBox(height: 16),
            if (widget.isPlayerWinner && widget.onDoubleGold != null)
              _buildDoubleGoldButton(),
            if (widget.isPlayerWinner && widget.onDoubleGold != null)
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
          widget.isPlayerWinner ? LocaleService.I.t('game.victory_char') : LocaleService.I.t('game.defeat_char'),
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
      widget.isPlayerWinner ? LocaleService.I.t('game.victory') : LocaleService.I.t('game.defeat'),
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

  Widget _buildReviveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onRevive,
        icon: const Icon(Icons.play_circle_outline),
        label: Text(LocaleService.I.t('game.ad_revive')),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDoubleGoldButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _doubleGoldClaimed ? null : () {
          widget.onDoubleGold?.call();
          setState(() => _doubleGoldClaimed = true);
        },
        icon: const Icon(Icons.play_circle_outline),
        label: Text(LocaleService.I.t('game.double_gold')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
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
          widget.isPlayerWinner
              ? LocaleService.I.t('game.btn_return')
              : LocaleService.I.t('game.btn_return'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _parchment, letterSpacing: 2),
        ),
      ),
    );
  }
}
