import 'theme_widgets.dart';
import '../../core/theme/app_theme.dart';
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
    final accent = win ? AppTheme.goldAccent : const Color(0xFF8A7F74);
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: win
                  ? const [Color(0xFF3A2614), Color(0xFF1A120B)]
                  : const [Color(0xFF2A1714), Color(0xFF120C0A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withAlpha(170), width: 1.5),
            boxShadow: [
              BoxShadow(color: accent.withAlpha(win ? 90 : 30), blurRadius: 40, spreadRadius: 2),
              const BoxShadow(color: Color(0xAA000000), blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlag(),
              const SizedBox(height: 14),
              _buildResultTitle(),
              const SizedBox(height: 16),
              _buildRewardSection(),
              const SizedBox(height: 22),
              if (win && widget.onDoubleReward != null) ...[
                _buildDoubleRewardButton(),
                const SizedBox(height: 10),
              ],
              _buildReturnButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 胜：金色旋转光芒 + 「勝」印；败：灰墨「敗」印
  Widget _buildFlag() {
    final win = widget.isPlayerWinner;
    final seal = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: win
            ? const RadialGradient(colors: [Color(0xFFFFE19A), Color(0xFFD9A441), Color(0xFF8A5A14)])
            : const RadialGradient(colors: [Color(0xFF6A5F57), Color(0xFF3A322C)]),
        border: Border.all(color: win ? const Color(0xFFFFF0C2) : const Color(0xFF8A7F74), width: 2.5),
        boxShadow: [
          BoxShadow(color: (win ? AppTheme.goldAccent : Colors.black).withAlpha(150), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      alignment: Alignment.center,
      child: Text(win ? '勝' : '敗',
          style: TextStyle(
            fontSize: 54,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: win ? const Color(0xFF5A1E0E) : const Color(0xFFD9CFC4),
          )),
    );
    if (!win) return seal;
    return SizedBox(
      width: 200,
      height: 150,
      child: Stack(alignment: Alignment.center, children: [
        _Rays(),
        seal,
      ]),
    );
  }

  Widget _buildResultTitle() {
    final win = widget.isPlayerWinner;
    return ShaderMask(
      shaderCallback: (r) => (win
              ? AppTheme.goldGradient
              : const LinearGradient(colors: [Color(0xFFBFB3A6), Color(0xFF85776A)]))
          .createShader(r),
      child: Text(
        win ? LocaleService.I.t('game.victory') : LocaleService.I.t('game.defeat'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6),
      ),
    );
  }

  Widget _buildRewardSection() {
    if (!widget.isPlayerWinner) {
      return Text(
        LocaleService.I.t('game.no_reward'),
        style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
      );
    }
    final hasCard = widget.rewardCardName != null;
    return Column(children: [
      Row(children: [
        Expanded(child: Divider(color: AppTheme.goldAccent.withAlpha(80))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(LocaleService.I.t('game.reward_title'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.goldAccent, letterSpacing: 2)),
        ),
        Expanded(child: Divider(color: AppTheme.goldAccent.withAlpha(80))),
      ]),
      const SizedBox(height: 12),
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
        if (hasCard)
          _rewardTile(Icons.style_rounded, widget.rewardCardName!, _rarityToColor(widget.rewardCardRarity)),
        if (widget.rewardGold > 0)
          _rewardTile(Icons.monetization_on_rounded, '+${widget.rewardGold}', AppTheme.goldBright),
      ]),
    ]);
  }

  Widget _rewardTile(IconData icon, String text, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(170)),
          boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 12)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  Color _rarityToColor(domain.Rarity? r) {
    return switch (r) {
      domain.Rarity.rare => AppTheme.rarityRare,
      domain.Rarity.epic => AppTheme.rarityEpic,
      domain.Rarity.legendary => AppTheme.rarityLegendary,
      _ => AppTheme.textSecondary,
    };
  }

  Widget _buildDoubleRewardButton() {
    return Opacity(
      opacity: _rewardClaimed ? 0.5 : 1,
      child: WPrimaryButton(
        label: _rewardClaimed
            ? LocaleService.I.t('game.reward_doubled')
            : LocaleService.I.t('game.ad_double_reward'),
        icon: Icons.play_circle_fill_rounded,
        danger: true,
        height: 50,
        onTap: _rewardClaimed
            ? null
            : () {
                widget.onDoubleReward?.call();
                setState(() => _rewardClaimed = true);
              },
      ),
    );
  }

  Widget _buildReturnButton() {
    final label = LocaleService.I.t('game.btn_return');
    if (!widget.isPlayerWinner || widget.onDoubleReward == null) {
      return WPrimaryButton(label: label, icon: Icons.home_rounded, height: 50, onTap: widget.onReturnToMenu);
    }
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(onPressed: widget.onReturnToMenu, child: Text(label)),
    );
  }
}

/// 胜利光芒：缓慢旋转的放射扇形
class _Rays extends StatefulWidget {
  @override
  State<_Rays> createState() => _RaysState();
}

class _RaysState extends State<_Rays> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: CustomPaint(size: const Size(190, 190), painter: _RaysPainter()),
      );
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(colors: [AppTheme.goldBright.withAlpha(150), AppTheme.goldBright.withAlpha(0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * 3.14159265 / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), a - 0.09, 0.18, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
