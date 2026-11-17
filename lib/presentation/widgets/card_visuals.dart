import 'package:flutter/material.dart' hide Card;

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/card.dart';

/// 卡牌共用视觉件：稀有度边框色、费用宝石、攻防徽章、传说流光。

Color rarityFrameColor(Rarity r) => switch (r) {
      Rarity.common => const Color(0xFF8C7B66),
      Rarity.rare => AppTheme.rarityRare,
      Rarity.epic => AppTheme.rarityEpic,
      Rarity.legendary => AppTheme.rarityLegendary,
    };

/// 费用宝石：蓝色渐变圆 + 白描边
class CostGem extends StatelessWidget {
  const CostGem({super.key, required this.cost, this.dim = false, this.size = 22});
  final int cost;
  final bool dim;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: dim
              ? const [Color(0xFF8A8A8A), Color(0xFF4A4A4A)]
              : const [Color(0xFF8FD0FF), Color(0xFF2468B8)],
        ),
        border: Border.all(color: const Color(0xFFEAF4FF), width: 1.3),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text('$cost',
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.55,
              height: 1.05,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)])),
    );
  }
}

/// 攻击（金）/ 生命（红）徽章；生命受损时数字变红、增益时变绿
class StatBadge extends StatelessWidget {
  const StatBadge({super.key, required this.value, required this.attack, this.size = 20, this.state = 0});
  final int value;
  final bool attack;
  final double size;

  /// -1 受损，0 正常，1 增益
  final int state;

  @override
  Widget build(BuildContext context) {
    final colors = attack
        ? const [Color(0xFFFFD27A), Color(0xFFB3741A)]
        : const [Color(0xFFFF7A6B), Color(0xFFA8241A)];
    final textColor = state < 0
        ? const Color(0xFFFFC2BA)
        : state > 0
            ? const Color(0xFFB8FFC9)
            : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: attack ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: attack ? BorderRadius.circular(size * 0.28) : null,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        border: Border.all(color: const Color(0xFF1A120A), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 1.5))],
      ),
      alignment: Alignment.center,
      child: Text('$value',
          style: TextStyle(
              color: textColor,
              fontSize: size * 0.56,
              height: 1.05,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)])),
    );
  }
}

/// 传说卡流光：斜向高光带循环扫过
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({super.key});

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          // 前 45% 时间扫过，其余静止，避免一直晃眼
          final t = (_c.value / 0.45).clamp(0.0, 1.0);
          final x = -1.6 + 3.2 * t;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(x - 0.5, -1),
                end: Alignment(x + 0.5, 1),
                colors: const [Color(0x00FFE7A8), Color(0x55FFE7A8), Color(0x00FFE7A8)],
              ),
            ),
          );
        },
      ),
    );
  }
}
