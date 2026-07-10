import 'package:flutter/material.dart';
import 'package:warring_states_card/data/card_image_service.dart';
import 'package:warring_states_card/domain/models/hero.dart' as domain;

/// 英雄头像动画状态
enum HeroAnimationState {
  idle,
  damaged,
  healed,
}

/// 英雄头像组件 - 圆形~52px
class HeroAvatar extends StatefulWidget {

  const HeroAvatar({
    super.key,
    required this.hero,
    required this.health,
    this.armor = 0,
    this.animationState = HeroAnimationState.idle,
    this.hasWeapon = false,
    this.onTap,
    this.weaponName,
  });
  final domain.Hero hero;
  final int health;
  final int armor;
  final HeroAnimationState animationState;
  final bool hasWeapon;
  final VoidCallback? onTap;
  final String? weaponName;

  @override
  State<HeroAvatar> createState() => _HeroAvatarState();
}

class _HeroAvatarState extends State<HeroAvatar> with TickerProviderStateMixin {
  late AnimationController _damageController;
  late AnimationController _healingController;
  late AnimationController _pulseController;
  
  late Animation<double> _damageShake;
  late Animation<double> _damageOpacity;
  late Animation<double> _healingGlow;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    
    if (widget.animationState != HeroAnimationState.idle) {
      _startAnimationIfNeeded();
    }
  }

  void _initAnimations() {
    // 伤害动画控制器
    _damageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _damageShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _damageController, curve: Curves.easeInOut));
    _damageOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _damageController, curve: Curves.easeInOut));

    // 治疗动画控制器
    _healingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _healingGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _healingController, curve: Curves.easeInOut),
    );

    // 生命值脉冲动画
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationIfNeeded() {
    switch (widget.animationState) {
      case HeroAnimationState.damaged:
        _damageController.forward();
        break;
      case HeroAnimationState.healed:
        _healingController.forward();
        break;
      case HeroAnimationState.idle:
        break;
    }
  }

  @override
  void didUpdateWidget(HeroAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.animationState != oldWidget.animationState) {
      _damageController.reset();
      _healingController.reset();
      _startAnimationIfNeeded();
    }
    
    // 低血量时的脉冲警告
    if (widget.health <= 10 && widget.health > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.health > 10 || widget.health <= 0) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _damageController.dispose();
    _healingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getHeroColor() {
    switch (widget.hero.className) {
      case 'bingjia':
        return Colors.red[700]!;
      case 'fajia':
        return Colors.blue[700]!;
      case 'rujia':
        return Colors.green[700]!;
      case 'daojia':
        return Colors.teal[700]!;
      case 'mojia':
        return Colors.orange[700]!;
      case 'yinyangjia':
        return Colors.purple[700]!;
      case 'zonghengjia':
        return Colors.indigo[700]!;
      default:
        return Colors.brown[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_damageController, _healingController, _pulseController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_damageShake.value * 20, 0),
            child: Transform.scale(
              scale: _pulseController.isAnimating ? _pulseAnimation.value : 1.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAvatarBody(),
                  // 武器图标
                  if (widget.hasWeapon)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: _buildWeaponIndicator(),
                    ),
                  // 治疗光晕
                  if (_healingController.isAnimating)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withAlpha((_healingGlow.value * 200).toInt()),
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  // 伤害闪烁
                  if (_damageController.isAnimating)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha((_damageOpacity.value * 128).toInt()),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarBody() {
    final heroColor = _getHeroColor();
    final firstChar = widget.hero.name.isNotEmpty ? widget.hero.name[0] : '?';
    final artPath = CardImageService.getHeroImageAsset(widget.hero.id);
    final hasArt = artPath.isNotEmpty;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: heroColor.withAlpha(179), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 英雄素材图片（优先）
            if (hasArt)
              Image.asset(
                artPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    firstChar,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  firstChar,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          // 生命值显示
          if (widget.health > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(220),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.health}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 护甲显示
          if (widget.armor > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[600]!.withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.armor}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponIndicator() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.gavel,
        color: Colors.white,
        size: 12,
      ),
    );
  }
}