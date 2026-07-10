import 'package:flutter/material.dart';

/// 法力水晶动画状态
enum ManaAnimationState {
  idle,
  spending,
  gaining,
}

/// 法力水晶组件 - 显示当前/最大法力值
class ManaCrystals extends StatefulWidget {

  const ManaCrystals({
    super.key,
    required this.currentMana,
    required this.maxMana,
    this.animationState = ManaAnimationState.idle,
    this.spentCrystalIndex,
  });
  final int currentMana;
  final int maxMana;
  final ManaAnimationState animationState;
  final int? spentCrystalIndex;

  @override
  State<ManaCrystals> createState() => _ManaCrystalsState();
}

class _ManaCrystalsState extends State<ManaCrystals> with TickerProviderStateMixin {
  late AnimationController _spendingController;
  late AnimationController _gainingController;
  
  late Animation<double> _spendingScale;
  late Animation<double> _gainingScale;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // 消耗动画控制器
    _spendingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _spendingScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _spendingController, curve: Curves.easeIn));

    // 获得动画控制器
    _gainingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gainingScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _gainingController, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(ManaCrystals oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 动画状态变化
    if (widget.animationState == ManaAnimationState.spending &&
        oldWidget.animationState != ManaAnimationState.spending) {
      _spendingController.forward(from: 0);
    }
    
    if (widget.animationState == ManaAnimationState.gaining &&
        oldWidget.animationState != ManaAnimationState.gaining) {
      _gainingController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _spendingController.dispose();
    _gainingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMax = widget.maxMana.clamp(0, 10);
    final effectiveCurrent = widget.currentMana.clamp(0, effectiveMax);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 法力值数字显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$effectiveCurrent/$effectiveMax',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 水晶行
          _buildCrystalsRow(effectiveCurrent, effectiveMax),
        ],
      ),
    );
  }

  Widget _buildCrystalsRow(int current, int max) {
    final crystals = <Widget>[];
    
    for (int i = 0; i < max; i++) {
      final isFilled = i < current;
      final isAnimating = widget.animationState != ManaAnimationState.idle && 
                          widget.spentCrystalIndex == i;
      
      crystals.add(
        AnimatedBuilder(
          animation: isAnimating && widget.animationState == ManaAnimationState.spending
              ? _spendingController
              : isAnimating && widget.animationState == ManaAnimationState.gaining
                  ? _gainingController
                  : const AlwaysStoppedAnimation(0),
          builder: (context, child) {
            double scale = 1.0;
            final double opacity = isFilled ? 1.0 : 0.3;
            Color color = isFilled ? Colors.blue : Colors.grey[400]!;
            
            if (isAnimating) {
              if (widget.animationState == ManaAnimationState.spending && isFilled) {
                scale = _spendingScale.value;
                color = Colors.red.withAlpha(128);
              } else if (widget.animationState == ManaAnimationState.gaining && !isFilled) {
                scale = _gainingScale.value;
              }
            }
            
            return Transform.scale(
              scale: scale,
              child: _buildCrystal(color, isFilled, opacity),
            );
          },
        ),
      );
      
      if (i < max - 1) {
        crystals.add(const SizedBox(width: 2));
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: crystals,
    );
  }

  Widget _buildCrystal(Color color, bool isFilled, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 12,
        height: 16,
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.grey[300],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(2),
          ),
          border: Border.all(
            color: isFilled ? Colors.blue[700]! : Colors.grey[400]!,
          ),
          boxShadow: isFilled
              ? [
                  BoxShadow(
                    color: Colors.blue.withAlpha(76),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isFilled
            ? CustomPaint(
                painter: _CrystalHighlightPainter(),
              )
            : null,
      ),
    );
  }
}

/// 水晶高光绘制器
class _CrystalHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(76)
      ..style = PaintingStyle.fill;
    
    // 顶部高光
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.1)
      ..lineTo(size.width * 0.6, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.3, size.height * 0.35)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 法力水晶组件（紧凑版）- 用于显示在英雄头像旁边
class CompactManaCrystals extends StatelessWidget {

  const CompactManaCrystals({
    super.key,
    required this.currentMana,
    required this.maxMana,
    this.animationState = ManaAnimationState.idle,
  });
  final int currentMana;
  final int maxMana;
  final ManaAnimationState animationState;

  @override
  Widget build(BuildContext context) {
    final effectiveMax = maxMana.clamp(0, 10);
    final effectiveCurrent = currentMana.clamp(0, effectiveMax);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(76),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            '$effectiveCurrent/$effectiveMax',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}