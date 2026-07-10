import 'package:flutter/material.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import '../../domain/models/card.dart' as domain;

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
  bool _rewardClaimed = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  static const _bgDark = Color(0xFF2C1810);
  static const _goldAccent = Color(0xFFB8860B);
  static const _parchment = Color(0xFFE8D5B7);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
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
        builder: (context, child) => Container(
          color: Colors.black.withAlpha((_fadeAnim.value * 179).toInt()),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(scale: _scaleAnim.value, child: child),
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final win = widget.isPlayerWinner;
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: win
                  ? [const Color(0xFF3D2B1F), _bgDark, const Color(0xFF4A3728)]
                  : [const Color(0xFF2A0A0A), const Color(0xFF1A0A0A), const Color(0xFF0A0505)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: win ? _goldAccent.withAlpha(128) : Colors.grey.withAlpha(76),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: win ? _goldAccent.withAlpha(51) : Colors.grey.withAlpha(26),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlag(),
              const SizedBox(height: 24),
              _buildResultTitle(),
              const SizedBox(height: 12),
              _buildRewardSection(),
              const SizedBox(height: 32),
              if (win && widget.onDoubleReward != null) ...[
                _buildDoubleRewardButton(),
                const SizedBox(height: 12),
              ],
              _buildReturnButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlag() {
    final win = widget.isPlayerWinner;
    return Container(
      width: 200,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: win
              ? [const Color(0xFFFFD700), const Color(0xFFB8860B)]
              : [const Color(0xFF555555), const Color(0xFF222222)],
        ),
        boxShadow: [
          BoxShadow(
            color: win ? _goldAccent.withAlpha(128) : Colors.black.withAlpha(102),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 旗面波纹装饰
          Positioned(
            right: -10,
            child: CustomPaint(
              size: const Size(40, 120),
              painter: _WavePainter(color: win ? const Color(0xFFFFC107) : const Color(0xFF444444)),
            ),
          ),
          // 旗杆
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: win ? const Color(0xFF8B6914) : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 旗帜文字
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 20),
            child: Text(
              win ? '🏆' : '🏴',
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTitle() {
    final win = widget.isPlayerWinner;
    return Text(
      win ? LocaleService.I.t('game.victory') : LocaleService.I.t('game.defeat'),
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: win ? _parchment : Colors.grey[400],
        letterSpacing: 4,
        shadows: [Shadow(color: Colors.black.withAlpha(128), blurRadius: 4, offset: const Offset(1, 1))],
      ),
    );
  }

  Widget _buildRewardSection() {
    if (!widget.isPlayerWinner) {
      return Text(
        LocaleService.I.t('game.no_reward'),
        style: TextStyle(fontSize: 16, color: _parchment.withAlpha(153)),
      );
    }
    final hasCard = widget.rewardCardName != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(76),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldAccent.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(LocaleService.I.t('game.reward_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _goldAccent)),
          const SizedBox(height: 12),
          if (hasCard) ...[
            _rewardRow(
              icon: '🃏',
              text: widget.rewardCardName!,
              color: _rarityToColor(widget.rewardCardRarity),
            ),
            const SizedBox(height: 6),
          ],
          if (widget.rewardGold > 0)
            _rewardRow(
              icon: '🪙',
              text: '+${widget.rewardGold} ${LocaleService.I.t('common.gold')}',
              color: _goldAccent,
            ),
        ],
      ),
    );
  }

  Widget _rewardRow({required String icon, required String text, required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _rarityToColor(domain.Rarity? r) {
    return switch (r) {
      domain.Rarity.rare => const Color(0xFF2196F3),
      domain.Rarity.epic => const Color(0xFF9C27B0),
      domain.Rarity.legendary => const Color(0xFFFF9800),
      _ => const Color(0xFF9E9E9E), // common or null
    };
  }

  Widget _buildDoubleRewardButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _rewardClaimed ? null : () {
          widget.onDoubleReward?.call();
          setState(() => _rewardClaimed = true);
        },
        icon: const Icon(Icons.play_circle_outline),
        label: Text(_rewardClaimed
            ? LocaleService.I.t('game.reward_doubled')
            : LocaleService.I.t('game.ad_double_reward')),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReturnButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onReturnToMenu,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A3728),
          foregroundColor: _parchment,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: widget.isPlayerWinner ? _goldAccent.withAlpha(128) : _parchment.withAlpha(76),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: Text(LocaleService.I.t('game.btn_return')),
      ),
    );
  }
}

/// 旗帜飘动波纹装饰
class _WavePainter extends CustomPainter {
  _WavePainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withAlpha(120)..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.25, 0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.75, 0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
