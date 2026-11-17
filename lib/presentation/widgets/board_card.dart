import 'package:flutter/material.dart' hide Card;
import 'card_visuals.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/card_image_service.dart';
import '../../../domain/models/card.dart';
import '../../../l10n/locale_service.dart';

/// 卡牌动画状态枚举
enum CardAnimationState {
  idle,
  entering,
  attacking,
  damaged,
  healed,
  dying,
}

/// 卡牌选择状态
enum CardSelectionState {
  none,
  canAttack,
  hasAttacked,
  selected,
  targetable,
}

/// 战场卡牌组件 - ~72x98px，用于战场显示
class BoardCard extends StatefulWidget {

  const BoardCard({
    super.key,
    required this.card,
    this.animationState = CardAnimationState.idle,
    this.selectionState = CardSelectionState.none,
    this.onTap,
    this.onLongPress,
    this.showKeywordIcons = true,
  });
  final Card card;
  final CardAnimationState animationState;
  final CardSelectionState selectionState;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showKeywordIcons;

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> with TickerProviderStateMixin {
  late AnimationController _enteringController;
  late AnimationController _attackingController;
  late AnimationController _damageController;
  late AnimationController _healingController;
  late AnimationController _dyingController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  late Animation<double> _enteringScale;
  late Animation<double> _enteringOpacity;
  late Animation<Offset> _attackingSlide;
  late Animation<double> _attackingScale;
  late Animation<Offset> _damageOffset;
  late Animation<double> _damageOpacity;
  late Animation<double> _healingScale;
  late Animation<double> _dyingScale;
  late Animation<double> _dyingOpacity;
  late Animation<double> _dyingRotation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _shakeOffset;

  final bool _isDamaged = false;
  final bool _isHealed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationIfNeeded();
  }

  void _initAnimations() {
    // 入场动画控制器
    _enteringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _enteringScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _enteringController, curve: Curves.elasticOut),
    );
    _enteringOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enteringController, curve: Curves.easeIn),
    );

    // 攻击动画控制器
    _attackingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _attackingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.15, 0),
    ).animate(CurvedAnimation(
      parent: _attackingController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    _attackingScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _attackingController,
      curve: Curves.easeInOut,
    ));

    // 伤害动画控制器
    _damageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _damageOffset = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.05, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _damageController, curve: Curves.easeInOut));
    _damageOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _damageController, curve: Curves.easeInOut));

    // 治疗动画控制器
    _healingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _healingScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _healingController, curve: Curves.easeInOut));

    // 死亡动画控制器
    _dyingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _dyingScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dyingController, curve: Curves.easeIn),
    );
    _dyingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dyingController, curve: Curves.easeIn),
    );
    _dyingRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _dyingController, curve: Curves.easeIn),
    );

    // 可攻击脉冲动画
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 震动动画
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shakeOffset = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  void _startAnimationIfNeeded() {
    switch (widget.animationState) {
      case CardAnimationState.entering:
        _enteringController.forward();
        break;
      case CardAnimationState.attacking:
        _attackingController.forward().then((_) => _attackingController.reverse());
        break;
      case CardAnimationState.damaged:
        _damageController.forward();
        _shakeController.forward();
        break;
      case CardAnimationState.healed:
        _healingController.forward();
        break;
      case CardAnimationState.dying:
        _dyingController.forward();
        break;
      case CardAnimationState.idle:
        // 检查是否需要脉冲
        if (widget.selectionState == CardSelectionState.canAttack) {
          _pulseController.repeat(reverse: true);
        }
        break;
    }
  }

  @override
  void didUpdateWidget(BoardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 动画状态变化
    if (widget.animationState != oldWidget.animationState) {
      _resetAnimations();
      _startAnimationIfNeeded();
    }
    
    // 脉冲状态变化
    if (widget.selectionState == CardSelectionState.canAttack && 
        oldWidget.selectionState != CardSelectionState.canAttack) {
      _pulseController.repeat(reverse: true);
    } else if (widget.selectionState != CardSelectionState.canAttack) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _resetAnimations() {
    _enteringController.reset();
    _attackingController.reset();
    _damageController.reset();
    _healingController.reset();
    _dyingController.reset();
    _shakeController.reset();
  }

  @override
  void dispose() {
    _enteringController.dispose();
    _attackingController.dispose();
    _damageController.dispose();
    _healingController.dispose();
    _dyingController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color _getRarityColor() {
    switch (widget.card.rarity) {
      case Rarity.common:
        return const Color(0xFFD4C5A9); // 羊皮纸色
      case Rarity.rare:
        return const Color(0xFF4A7C59); // 玉色
      case Rarity.epic:
        return const Color(0xFF8B4513); // 铜褐色
      case Rarity.legendary:
        return const Color(0xFFC59538); // 金色
    }
  }


  Color _getBorderColor() {
    switch (widget.selectionState) {
      case CardSelectionState.none:
        return rarityFrameColor(widget.card.rarity);
      case CardSelectionState.canAttack:
        final pulse = _pulseAnimation.value;
        return Color.lerp(AppTheme.healGreen, const Color(0xFFA6F0BE), pulse)!;
      case CardSelectionState.hasAttacked:
        return const Color(0xFF5A5048);
      case CardSelectionState.selected:
        return AppTheme.goldBright;
      case CardSelectionState.targetable:
        return AppTheme.healthRed;
    }
  }

  double _getBorderWidth() {
    switch (widget.selectionState) {
      case CardSelectionState.canAttack:
      case CardSelectionState.selected:
      case CardSelectionState.targetable:
        return 2.4;
      default:
        return 1.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _enteringController,
          _attackingController,
          _damageController,
          _healingController,
          _dyingController,
          _pulseController,
          _shakeController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: _shakeOffset.value,
            child: Transform.rotate(
              angle: _dyingRotation.value,
              child: Transform.scale(
                scale: _dyingController.isAnimating
                    ? _dyingScale.value
                    : _enteringController.isAnimating
                        ? _enteringScale.value
                        : _attackingController.isAnimating
                            ? _attackingScale.value
                            : _healingController.isAnimating
                                ? _healingScale.value
                                : 1.0,
                child: Opacity(
                  opacity: _dyingController.isAnimating
                      ? _dyingOpacity.value
                      : _enteringController.isAnimating
                          ? _enteringOpacity.value
                          : 1.0,
                  child: Transform.translate(
                    offset: _attackingController.isAnimating
                        ? _attackingSlide.value
                        : Offset.zero,
                    child: _buildCardContent(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent() {
    final borderColor = _getBorderColor();
    final borderWidth = _getBorderWidth();
    final isDormant = widget.card.isDormant;
    final hasAttacked = widget.card.hasAttackedThisTurn;
    final sel = widget.selectionState;
    final glow = switch (sel) {
      CardSelectionState.canAttack => AppTheme.healGreen.withAlpha((90 + 90 * _pulseAnimation.value).toInt()),
      CardSelectionState.selected => AppTheme.goldBright.withAlpha(170),
      CardSelectionState.targetable => AppTheme.healthRed.withAlpha(150),
      _ => null,
    };
    final taunt = widget.card.keywords.contains(Keyword.taunt);
    final shield = widget.card.hasDivineShield;

    final body = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(taunt ? 4 : 10),
        border: Border.all(color: borderColor, width: taunt ? borderWidth + 1 : borderWidth),
        color: const Color(0xFF15100C),
        boxShadow: [
          if (glow != null) BoxShadow(color: glow, blurRadius: 14, spreadRadius: 1),
          if (shield) BoxShadow(color: const Color(0xFFFFE9A0).withAlpha(200), blurRadius: 10, spreadRadius: 2),
          const BoxShadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(taunt ? 2.5 : 8.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.55, 1],
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            if (widget.card.rarity == Rarity.legendary) const ShimmerSweep(),
            if (widget.showKeywordIcons && widget.card.keywords.isNotEmpty)
              Positioned(left: 2, top: 2, child: _buildKeywordIcons()),
            if (hasAttacked) Container(color: Colors.black.withAlpha(110)),
            if (isDormant) Container(color: Colors.black.withAlpha(160)),
            if (sel == CardSelectionState.selected) Container(color: AppTheme.goldBright.withAlpha(40)),
            // 受伤：红色闪光
            if (_damageController.isAnimating && !_dyingController.isAnimating)
              Container(color: AppTheme.healthRed.withAlpha((_damageOpacity.value * 120).toInt())),
            // 治疗：绿色光晕
            if (_healingController.isAnimating && !_dyingController.isAnimating)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [
                    AppTheme.healGreen.withAlpha((_healingController.value * 110).toInt()),
                    Colors.transparent,
                  ]),
                ),
              ),
            if (isDormant)
              Center(
                child: Text('Zzz',
                    style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 13, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );

    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: body),
      if (widget.card.isMinion) ...[
        Positioned(left: -4, bottom: -4, child: StatBadge(value: widget.card.attack, attack: true, size: 22)),
        Positioned(
            right: -4,
            bottom: -4,
            child: StatBadge(
                value: widget.card.health,
                attack: false,
                size: 22,
                state: widget.card.health < widget.card.maxHealth ? -1 : 0)),
      ],
    ]);
  }

  Widget _buildBackground() {
    final imagePath = widget.card.imageAsset.isNotEmpty
        ? widget.card.imageAsset
        : CardImageService.getImageAsset(widget.card.id);

    if (imagePath.isNotEmpty) {
      // cover保持比例, alignment偏左上让右下AI水印(10%-15%)被容器裁掉
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        alignment: const Alignment(-0.1, -0.15),
        errorBuilder: (_, __, ___) => Container(color: _getRarityColor()),
      );
    }
    return Container(color: _getRarityColor());
  }

  Widget _buildKeywordIcons() {
    final icons = <Widget>[];

    if (widget.card.keywords.contains(Keyword.charge)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.orange.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: Text(LocaleService.I.t('basic_card.keyword_charge'), style: const TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.taunt)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.brown.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: Text(LocaleService.I.t('basic_card.keyword_taunt'), style: const TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.divineShield)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: AppTheme.jade.withAlpha(200), borderRadius: BorderRadius.circular(3)),
        child: Text(LocaleService.I.t('basic_card.keyword_divine_shield'), style: const TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.windfury)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.lime.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: Text(LocaleService.I.t('basic_card.keyword_windfury'), style: const TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.lifesteal)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.pink.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: Text(LocaleService.I.t('basic_card.keyword_lifesteal'), style: const TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons.take(3).toList(),
    );
  }
}