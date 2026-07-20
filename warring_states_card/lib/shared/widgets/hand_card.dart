import 'package:flutter/material.dart' hide Card;
import 'package:warring_states_card/data/card_image_service.dart';
import 'package:warring_states_card/domain/models/card.dart';

/// 手牌选择状态
enum HandCardState {
  normal,
  playable,
  selected,
  unplayable,
}

/// 手牌组件 - ~80px宽，用于手牌区域显示
class HandCard extends StatefulWidget {

  const HandCard({
    super.key,
    required this.card,
    this.cardState = HandCardState.normal,
    this.canAfford = false,
    this.onTap,
    this.onLongPress,
    this.showAttackHealth = true,
  });
  final Card card;
  final HandCardState cardState;
  final bool canAfford;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAttackHealth;

  @override
  State<HandCard> createState() => _HandCardState();
}

class _HandCardState extends State<HandCard> with TickerProviderStateMixin {
  late AnimationController _enteringController;
  late AnimationController _selectionController;
  late AnimationController _tooltipController;
  
  late Animation<double> _enteringSlide;
  late Animation<double> _enteringOpacity;
  late Animation<Offset> _selectionLift;
  late Animation<double> _tooltipOpacity;

  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _enteringController.forward();
  }

  void _initAnimations() {
    // 入场动画控制器
    _enteringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _enteringSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _enteringController, curve: Curves.easeOut),
    );
    _enteringOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enteringController, curve: Curves.easeIn),
    );

    // 选中动画控制器
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _selectionLift = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -4),
    ).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeOut),
    );

    // 提示框动画控制器
    _tooltipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tooltipOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tooltipController, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(HandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 选中状态变化
    if (widget.cardState == HandCardState.selected && 
        oldWidget.cardState != HandCardState.selected) {
      _selectionController.forward();
    } else if (widget.cardState != HandCardState.selected) {
      _selectionController.reverse();
    }
  }

  @override
  void dispose() {
    _enteringController.dispose();
    _selectionController.dispose();
    _tooltipController.dispose();
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
    switch (widget.cardState) {
      case HandCardState.selected:
        return Colors.orange;
      case HandCardState.playable:
        return Colors.green;
      case HandCardState.unplayable:
        return Colors.grey;
      case HandCardState.normal:
        return _getRarityColor().withAlpha(128);
    }
  }

  double _getBorderWidth() {
    return widget.cardState == HandCardState.selected ? 3 : 2;
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() => _showTooltip = true);
    _tooltipController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _tooltipController.reverse().then((_) {
      if (mounted) setState(() => _showTooltip = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enteringController, _selectionController, _tooltipController]),
      builder: (context, child) {
        return Transform.translate(
          offset: _selectionLift.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: widget.onTap,
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                child: _buildCardBody(),
              ),
              // 长按提示框
              if (_showTooltip)
                Positioned(
                  bottom: 110,
                  left: 0,
                  right: 0,
                  child: _buildTooltip(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardBody() {
    final rarityColor = _getRarityColor();
    final borderColor = _getBorderColor();
    final borderWidth = _getBorderWidth();
    final costColor = widget.canAfford ? Colors.blue : Colors.grey;

    return Opacity(
      opacity: _enteringOpacity.value,
      child: Transform.translate(
        offset: Offset(0, _enteringSlide.value * 20),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: borderWidth),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                borderColor.withAlpha(30),
                borderColor.withAlpha(8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.cardState == HandCardState.selected
                    ? Colors.orange.withAlpha(76)
                    : Colors.black.withAlpha(38),
                blurRadius: widget.cardState == HandCardState.selected ? 6 : 3,
                offset: Offset(0, widget.cardState == HandCardState.selected ? 4 : 2),
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
                
                // 费用角标 - 左上角
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: costColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                          color: costColor.withAlpha(128),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.card.cost}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 稀有度宝石指示器 - 右上角
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getGemColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getGemColor().withAlpha(128),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 卡牌名称
                Positioned(
                  left: 2,
                  right: 2,
                  top: 24,
                  child: Text(
                    widget.card.name,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // 攻击/血量
                if (widget.card.isMinion && widget.showAttackHealth)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange[800]!.withAlpha(200),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${widget.card.attack}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red[800]!.withAlpha(200),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${widget.card.health}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 关键词图标
                if (widget.card.keywords.isNotEmpty)
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: _buildKeywordIcons(),
                  ),
              ],
            ),
          ),
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

  Widget _buildTooltip() {
    return Opacity(
      opacity: _tooltipOpacity.value,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(230),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getRarityColor()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRarityColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.card.cost}费',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 攻击/血量
            if (widget.card.isMinion)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTooltipStat('\u2694', '${widget.card.attack}', Colors.orange),
                  const SizedBox(width: 12),
                  _buildTooltipStat('\u2764', '${widget.card.health}', Colors.red),
                ],
              ),
            const SizedBox(height: 4),
            // 关键词
            if (widget.card.keywords.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: widget.card.keywords.map((k) => _buildKeywordBadge(k)).toList(),
              ),
            const SizedBox(height: 4),
            // 描述
            Text(
              widget.card.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            // 描述
            if (widget.card.flavor.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.card.flavor,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipStat(String iconText, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(iconText, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getGemColor() {
    switch (widget.card.rarity) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.rare:
        return Colors.blue;
      case Rarity.epic:
        return Colors.purple;
      case Rarity.legendary:
        return Colors.orange;
    }
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

  Widget _buildKeywordBadge(Keyword keyword) {
    final info = _getKeywordInfo(keyword);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: info.color.withAlpha(51),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: info.color.withAlpha(128)),
      ),
      child: Text(
        info.name,
        style: TextStyle(
          color: info.color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ({String name, Color color}) _getKeywordInfo(Keyword keyword) {
    switch (keyword) {
      case Keyword.charge:
        return (name: '冲锋', color: Colors.yellow);
      case Keyword.taunt:
        return (name: '嘲讽', color: Colors.grey);
      case Keyword.divineShield:
        return (name: '圣盾', color: Colors.white);
      case Keyword.windfury:
        return (name: '风怒', color: Colors.cyan);
      case Keyword.lifesteal:
        return (name: '吸血', color: Colors.red);
      case Keyword.poisonous:
        return (name: '剧毒', color: Colors.green);
      case Keyword.battlecry:
        return (name: '战吼', color: Colors.blue);
      case Keyword.deathrattle:
        return (name: '亡语', color: Colors.brown);
      case Keyword.stealth:
        return (name: '潜行', color: Colors.purple);
      case Keyword.silence:
        return (name: '沉默', color: Colors.grey);
      case Keyword.inspire:
        return (name: '激励', color: Colors.orange);
      case Keyword.combo:
        return (name: '连击', color: Colors.red);
      case Keyword.draw:
        return (name: '抽牌', color: Colors.blue);
    }
  }
}