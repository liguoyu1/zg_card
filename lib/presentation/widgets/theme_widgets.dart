import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 全屏战国纹理背景
class WThemeBackground extends StatelessWidget {

  const WThemeBackground({
    super.key,
    required this.child,
    this.useRadial = false,
  });
  final Widget child;
  final bool useRadial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: useRadial ? AppTheme.boardDecoration : AppTheme.bgDecoration,
      child: child,
    );
  }
}

/// 金色装饰边框容器
class WGoldFrame extends StatelessWidget {

  const WGoldFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderWidth = 1.5,
    this.borderRadius = 8,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGold, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

/// 战国牌匾容器（漆面面板）
class WPlaque extends StatelessWidget {
  const WPlaque({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.highlighted = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: highlighted ? AppTheme.goldAccent : AppTheme.borderLight,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          if (highlighted) AppTheme.glowShadow(AppTheme.goldAccent),
          const BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// 按压反馈：按下缩小 + 悬停微抬（所有自绘按钮共用）
class WPressable extends StatefulWidget {
  const WPressable({super.key, required this.child, this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<WPressable> createState() => _WPressableState();
}

class _WPressableState extends State<WPressable> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : (_hover && enabled ? 1.015 : 1),
          duration: AppTheme.durFast,
          curve: AppTheme.curveOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 列表式菜单按钮：左侧徽章 + 标题/副标题 + 箭头
class WMenuPlaque extends StatelessWidget {
  const WMenuPlaque({
    super.key,
    required this.icon,
    required this.label,
    this.accentColor,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final Color? accentColor;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.goldAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: WPressable(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            gradient: AppTheme.panelGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(children: [
            WIconMedal(icon: icon, color: color, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withAlpha(200), size: 22),
          ]),
        ),
      ),
    );
  }
}

/// 圆角方形图标徽章（同色系渐变 + 内描边）
class WIconMedal extends StatelessWidget {
  const WIconMedal({super.key, required this.icon, required this.color, this.size = 40, this.dim = false});
  final IconData icon;
  final Color color;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = dim ? AppTheme.textMuted : color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withAlpha(dim ? 30 : 70), c.withAlpha(dim ? 12 : 22)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: c.withAlpha(dim ? 60 : 140)),
      ),
      child: Icon(icon, color: c, size: size * 0.52),
    );
  }
}

/// 主行动大按钮（金/朱砂渐变，带光泽与外发光）
class WPrimaryButton extends StatelessWidget {
  const WPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
    this.height = 52,
    this.trailing,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool danger;
  final double height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = danger ? Colors.white : const Color(0xFF1A1206);
    return WPressable(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: AppTheme.durFast,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: danger ? AppTheme.cinnabarGradient : AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                  color: (danger ? AppTheme.cinnabar : AppTheme.goldAccent).withAlpha(enabled ? 90 : 0),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ]),
        ),
      ),
    );
  }
}

/// 金色渐变进度条
class WProgressBar extends StatelessWidget {
  const WProgressBar({super.key, required this.value, this.height = 8, this.color, this.done = false});
  final double value;
  final double height;
  final Color? color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = done ? AppTheme.healGreen : (color ?? AppTheme.goldAccent);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF14100D),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: const Color(0xFF3A3029), width: 0.8),
      ),
      child: LayoutBuilder(builder: (_, bc) {
        return Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: AppTheme.curveOut,
            builder: (_, v, __) => Container(
              width: bc.maxWidth * v,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(colors: [c.withAlpha(170), c, Color.lerp(c, Colors.white, 0.35)!]),
                boxShadow: [if (v > 0) BoxShadow(color: c.withAlpha(110), blurRadius: 6)],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 货币显示：金币/钻石用绘制图标替代 emoji（跨平台一致）
class WCurrency extends StatelessWidget {
  const WCurrency({super.key, required this.amount, this.diamond = false, this.size = 14, this.prefix = ''});
  final Object amount;
  final bool diamond;
  final double size;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final c = diamond ? const Color(0xFF7FD3F0) : AppTheme.goldBright;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size + 2,
        height: size + 2,
        decoration: BoxDecoration(
          shape: diamond ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: diamond ? BorderRadius.circular(3) : null,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: diamond
                ? const [Color(0xFFBDF0FF), Color(0xFF3FA7D6)]
                : const [Color(0xFFFFE08A), Color(0xFFC88A1E)],
          ),
          boxShadow: [BoxShadow(color: c.withAlpha(90), blurRadius: 4)],
        ),
        child: Icon(diamond ? Icons.diamond : Icons.circle, size: (size + 2) * (diamond ? 0.62 : 0.42),
            color: diamond ? Colors.white : const Color(0xFF8A5A10)),
      ),
      const SizedBox(width: 4),
      Text('$prefix$amount',
          style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

/// 单个筛选胶囊（选中为金色渐变）
class WChip extends StatelessWidget {
  const WChip({super.key, required this.label, required this.selected, required this.onTap, this.compact = false, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  /// 未选中时的强调色（例如稀有度）
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return WPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMed,
        curve: AppTheme.curveOut,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 5 : 7),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.goldGradient : null,
          color: selected ? null : AppTheme.bgMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.goldBright : (color?.withAlpha(140) ?? AppTheme.borderLight)),
          boxShadow: [if (selected) BoxShadow(color: AppTheme.goldAccent.withAlpha(70), blurRadius: 10)],
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? const Color(0xFF1A1206) : (color ?? AppTheme.textSecondary),
            )),
      ),
    );
  }
}

/// 横向筛选胶囊（替代默认 ChoiceChip）
class WFilterBar<T> extends StatelessWidget {
  const WFilterBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(children: [
        for (final v in values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WPressable(
              onTap: () => onSelected(v),
              child: AnimatedContainer(
                duration: AppTheme.durMed,
                curve: AppTheme.curveOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: v == selected ? AppTheme.goldGradient : null,
                  color: v == selected ? null : AppTheme.bgMedium,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: v == selected ? AppTheme.goldBright : AppTheme.borderLight),
                  boxShadow: [if (v == selected) BoxShadow(color: AppTheme.goldAccent.withAlpha(70), blurRadius: 10)],
                ),
                child: Text(label(v),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: v == selected ? FontWeight.w800 : FontWeight.w600,
                      color: v == selected ? const Color(0xFF1A1206) : AppTheme.textSecondary,
                    )),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 列表入场：淡入 + 上浮，按 index 错开（上限 8 个避免长列表等待）
class WStaggerIn extends StatelessWidget {
  const WStaggerIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 0.06;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (delay * 1000).round()),
      curve: Interval(delay / (0.38 + delay), 1, curve: AppTheme.curveOut),
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// 战国小节标题
class WSectionTitle extends StatelessWidget {

  const WSectionTitle({
    super.key,
    required this.label,
    this.icon,
  });
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.goldAccent, size: 18),
            const SizedBox(width: 8),
          ],
          Container(
            height: 1,
            width: 24,
            color: AppTheme.borderLight.withAlpha(100),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.goldAccent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.borderLight.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }
}

/// 战国风装饰性 AppBar（无阴影/自定义）
class WAppBar extends StatelessWidget implements PreferredSizeWidget {

  const WAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.bgDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGold.withAlpha(80),
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: leading!,
            )
          else
            const SizedBox(width: 16),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (actions != null) ...[
            ...actions!,
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}

/// 黄金分割线
class WDivider extends StatelessWidget {

  const WDivider({super.key, this.thickness = 1});
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.borderGold.withAlpha(100),
            AppTheme.borderGold.withAlpha(150),
            AppTheme.borderGold.withAlpha(100),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// 带金色轮廓的圆形头像容器
class WAvatarFrame extends StatelessWidget {

  const WAvatarFrame({
    super.key,
    required this.child,
    this.size = 64,
    this.glowColor,
  });
  final Widget child;
  final double size;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppTheme.goldAccent).withAlpha(50),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}
