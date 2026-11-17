import 'package:flutter/material.dart' hide Card;
import '../../../data/card_image_service.dart';
import '../../../domain/models/card.dart';
import '../../../l10n/locale_service.dart';
import '../../../shared/widgets/queued_asset_image.dart';
import '../../../core/theme/app_theme.dart';
import 'card_visuals.dart';

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
  bool _hover = false;

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
      end: const Offset(0, -8),
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
    final isSelected = widget.cardState == HandCardState.selected;
    return AnimatedBuilder(
      animation: Listenable.merge([_enteringController, _selectionController, _tooltipController]),
      builder: (context, child) {
        final hoverLift = _hover && !isSelected ? -6.0 : 0.0;
        return AnimatedContainer(
          duration: AppTheme.durFast,
          curve: AppTheme.curveOut,
          transform: Matrix4.translationValues(0, _selectionLift.value.dy + hoverLift, 0)
            ..scale(isSelected ? 1.08 : (_hover ? 1.04 : 1.0)),
          transformAlignment: Alignment.bottomCenter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                child: GestureDetector(
                  onTap: widget.onTap,
                  onLongPressStart: _onLongPressStart,
                  onLongPressEnd: _onLongPressEnd,
                  child: _buildCardBody(),
                ),
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
    final rarity = rarityFrameColor(widget.card.rarity);
    final selected = widget.cardState == HandCardState.selected;
    final playable = widget.cardState == HandCardState.playable;
    final dim = widget.cardState == HandCardState.unplayable;
    final frame = selected ? AppTheme.goldBright : rarity;

    final body = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: frame, width: selected ? 2.4 : 1.6),
        color: const Color(0xFF15100C),
        boxShadow: [
          if (selected)
            BoxShadow(color: AppTheme.goldBright.withAlpha(150), blurRadius: 16, spreadRadius: 1)
          else if (playable)
            BoxShadow(color: AppTheme.healGreen.withAlpha(_hover ? 170 : 110), blurRadius: _hover ? 14 : 9),
          const BoxShadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            // 底部渐暗，托住名字与数值
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.45, 1],
                  colors: [Colors.transparent, Color(0xE6000000)],
                ),
              ),
            ),
            if (widget.card.rarity == Rarity.legendary) const ShimmerSweep(),
            // 卡名
            Positioned(
              left: 3,
              right: 3,
              bottom: widget.card.isMinion && widget.showAttackHealth ? 20 : 4,
              child: Text(
                widget.card.lname,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF7EBD6),
                  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            // 关键词
            if (widget.card.keywords.isNotEmpty)
              Positioned(left: 2, top: 24, child: _buildKeywordIcons()),
            // 不可打出：压暗
            if (dim) Container(color: Colors.black.withAlpha(110)),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: _enteringOpacity.value,
      child: Transform.translate(
        offset: Offset(0, _enteringSlide.value * 24),
        child: Transform.scale(
          scale: 1 - _enteringSlide.value * 0.15,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: body),
            // 费用宝石
            Positioned(left: -4, top: -4, child: CostGem(cost: widget.card.cost, dim: !widget.canAfford)),
            // 攻 / 血
            if (widget.card.isMinion && widget.showAttackHealth) ...[
              Positioned(left: -3, bottom: -3, child: StatBadge(value: widget.card.attack, attack: true)),
              Positioned(right: -3, bottom: -3, child: StatBadge(value: widget.card.health, attack: false)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final imagePath = widget.card.imageAsset.isNotEmpty
        ? widget.card.imageAsset
        : CardImageService.getImageAsset(widget.card.id);

    if (imagePath.isNotEmpty) {
      return QueuedAssetImage(
        path: imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholderColor: _getRarityColor(),
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
                    LocaleService.I.t('hand_card.cost_fee', args: {'cost': '${widget.card.cost}'}),
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
                    widget.card.lname,
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
              widget.card.ldescription,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            // 描述
            if (widget.card.lflavor.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.card.lflavor,
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


  Widget _buildKeywordIcons() {
    final icons = <Widget>[];

    if (widget.card.keywords.contains(Keyword.charge)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: const Color(0xCC14100D), borderRadius: BorderRadius.circular(3), border: Border.all(color: AppTheme.goldAccent.withAlpha(140), width: 0.6)),
        child: Text(LocaleService.I.t('basic_card.keyword_charge'), style: const TextStyle(color: AppTheme.goldBright, fontSize: 7, fontWeight: FontWeight.w700)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.taunt)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: const Color(0xCC14100D), borderRadius: BorderRadius.circular(3), border: Border.all(color: AppTheme.goldAccent.withAlpha(140), width: 0.6)),
        child: Text(LocaleService.I.t('basic_card.keyword_taunt'), style: const TextStyle(color: AppTheme.goldBright, fontSize: 7, fontWeight: FontWeight.w700)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.divineShield)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: const Color(0xCC14100D), borderRadius: BorderRadius.circular(3), border: Border.all(color: AppTheme.goldAccent.withAlpha(140), width: 0.6)),
        child: Text(LocaleService.I.t('basic_card.keyword_divine_shield'), style: const TextStyle(color: AppTheme.goldBright, fontSize: 7, fontWeight: FontWeight.w700)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.windfury)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: const Color(0xCC14100D), borderRadius: BorderRadius.circular(3), border: Border.all(color: AppTheme.goldAccent.withAlpha(140), width: 0.6)),
        child: Text(LocaleService.I.t('basic_card.keyword_windfury'), style: const TextStyle(color: AppTheme.goldBright, fontSize: 7, fontWeight: FontWeight.w700)),
      ));
    }
    if (widget.card.keywords.contains(Keyword.lifesteal)) {
      icons.add(Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: const Color(0xCC14100D), borderRadius: BorderRadius.circular(3), border: Border.all(color: AppTheme.goldAccent.withAlpha(140), width: 0.6)),
        child: Text(LocaleService.I.t('basic_card.keyword_lifesteal'), style: const TextStyle(color: AppTheme.goldBright, fontSize: 7, fontWeight: FontWeight.w700)),
      ));
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final w in icons.take(3)) Padding(padding: const EdgeInsets.only(bottom: 2), child: w)],
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
        return (name: LocaleService.I.t('basic_card.keyword_charge'), color: Colors.yellow);
      case Keyword.taunt:
        return (name: LocaleService.I.t('basic_card.keyword_taunt'), color: Colors.grey);
      case Keyword.divineShield:
        return (name: LocaleService.I.t('basic_card.keyword_divine_shield'), color: Colors.white);
      case Keyword.windfury:
        return (name: LocaleService.I.t('basic_card.keyword_windfury'), color: AppTheme.jade);
      case Keyword.lifesteal:
        return (name: LocaleService.I.t('basic_card.keyword_lifesteal'), color: Colors.red);
      case Keyword.poisonous:
        return (name: LocaleService.I.t('basic_card.keyword_poisonous'), color: Colors.green);
      case Keyword.battlecry:
        return (name: LocaleService.I.t('basic_card.keyword_battlecry'), color: Colors.blue);
      case Keyword.deathrattle:
        return (name: LocaleService.I.t('basic_card.keyword_deathrattle'), color: Colors.brown);
      case Keyword.stealth:
        return (name: LocaleService.I.t('basic_card.keyword_stealth'), color: Colors.purple);
      case Keyword.silence:
        return (name: LocaleService.I.t('basic_card.keyword_silence'), color: Colors.grey);
      case Keyword.inspire:
        return (name: LocaleService.I.t('basic_card.keyword_inspire'), color: Colors.orange);
      case Keyword.combo:
        return (name: LocaleService.I.t('basic_card.keyword_combo'), color: Colors.red);
      case Keyword.draw:
        return (name: LocaleService.I.t('basic_card.keyword_draw'), color: Colors.blue);
    }
  }
}
