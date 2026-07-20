import 'package:flutter/material.dart' hide Card;
import 'package:warring_states_card/data/card_image_service.dart';
import 'package:warring_states_card/domain/models/card.dart';

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

  String _getGemAsset() {
    switch (widget.card.rarity) {
      case Rarity.common:
        return 'assets/gems/common.png';
      case Rarity.rare:
        return 'assets/gems/rare.png';
      case Rarity.epic:
        return 'assets/gems/epic.png';
      case Rarity.legendary:
        return 'assets/gems/legendary.png';
    }
  }

  Color _getBorderColor() {
    switch (widget.selectionState) {
      case CardSelectionState.none:
        return Colors.black54;
      case CardSelectionState.canAttack:
        final pulse = _pulseAnimation.value;
        return Color.lerp(Colors.green, Colors.lightGreen, pulse)!;
      case CardSelectionState.hasAttacked:
        return Colors.grey;
      case CardSelectionState.selected:
        return Colors.orange;
      case CardSelectionState.targetable:
        return Colors.red;
    }
  }

  double _getBorderWidth() {
    switch (widget.selectionState) {
      case CardSelectionState.canAttack:
      case CardSelectionState.selected:
      case CardSelectionState.targetable:
        return 3;
      default:
        return 1;
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
    final rarityColor = _getRarityColor();
    final borderColor = _getBorderColor();
    final borderWidth = _getBorderWidth();
    final isDormant = widget.card.isDormant;
    final hasAttacked = widget.card.hasAttackedThisTurn;

    return Container(
      width: 72,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: borderWidth),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withAlpha(30),
            rarityColor.withAlpha(8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.selectionState == CardSelectionState.selected
                ? Colors.orange.withAlpha(76)
                : Colors.black.withAlpha(38),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 卡牌背景（图片优先）
            _buildBackground(),

            // 卡牌框装饰层
            Positioned.fill(
              child: Image.asset(
                'assets/frame/card_frame.png',
                fit: BoxFit.fill,
              ),
            ),

            // 稀有度宝石 - 右上角
            Positioned(
              right: 0,
              top: 0,
              child: Image.asset(
                _getGemAsset(),
                width: 14,
                height: 14,
              ),
            ),

            // 关键词图标 - 左上角
            if (widget.showKeywordIcons && widget.card.keywords.isNotEmpty)
              Positioned(
                left: 2,
                top: 2,
                child: _buildKeywordIcons(),
              ),
            
            // 已攻击遮罩
            if (hasAttacked)
              Container(color: Colors.black.withAlpha(128)),
            
            // 休眠遮罩
            if (isDormant)
              Container(color: Colors.black.withAlpha(160)),
            
            // 选中遮罩
            if (widget.selectionState == CardSelectionState.selected)
              Container(color: Colors.yellow.withAlpha(76)),
            
            // 伤害闪烁遮罩
            if (_damageController.isAnimating && !_dyingController.isAnimating)
              Container(color: Colors.red.withAlpha((_damageOpacity.value * 76).toInt())),
            
            // 治疗光晕
            if (_healingController.isAnimating && !_dyingController.isAnimating)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.withAlpha((_healingController.value * 200).toInt()),
                    width: 2,
                  ),
                ),
              ),
            
            // 攻击/血量底部信息栏
            if (widget.card.isMinion)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '\u2694${widget.card.attack}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\u2764${widget.card.health}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // 休眠Zzz指示器
            if (isDormant)
              Positioned(
                right: 2,
                bottom: 20,
                child: Text(
                  'Zzz',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final imagePath = widget.card.imageAsset.isNotEmpty 
        ? widget.card.imageAsset 
        : CardImageService.getImageAsset(widget.card.id);

    if (imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
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
        child: const Text('\u51B2\u950B', style: TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.taunt)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.brown.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: const Text('\u8BBD\u8BAE', style: TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.divineShield)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.cyan.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: const Text('\u5723\u76FE', style: TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.windfury)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.lime.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: const Text('\u98CE\u6012', style: TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.lifesteal)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Colors.pink.withAlpha(180), borderRadius: BorderRadius.circular(2)),
        child: const Text('\u5438\u8840', style: TextStyle(color: Colors.white, fontSize: 7)),
      ));
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons.take(3).toList(),
    );
  }
}