import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 全屏战国纹理背景
class WThemeBackground extends StatelessWidget {
  final Widget child;
  final bool useRadial;

  const WThemeBackground({
    super.key,
    required this.child,
    this.useRadial = false,
  });

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
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double borderRadius;

  const WGoldFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderWidth = 1.5,
    this.borderRadius = 8,
  });

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

/// 战国牌匾容器（炉石式面板）
class WPlaque extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const WPlaque({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.goldAccent.withAlpha(30)
            : AppTheme.bgMedium.withAlpha(180),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: highlighted ? AppTheme.goldAccent : AppTheme.borderLight.withAlpha(100),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? AppTheme.goldAccent.withAlpha(30)
                : Colors.black.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 战国风格菜单按钮（炉石式大题板）
class WMenuPlaque extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;
  final VoidCallback onTap;
  final String? subtitle;

  const WMenuPlaque({
    super.key,
    required this.icon,
    required this.label,
    this.accentColor,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.goldAccent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withAlpha(40),
              AppTheme.bgMedium.withAlpha(200),
              color.withAlpha(20),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: color.withAlpha(120),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXs,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 战国小节标题
class WSectionTitle extends StatelessWidget {
  final String label;
  final IconData? icon;

  const WSectionTitle({
    super.key,
    required this.label,
    this.icon,
  });

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
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
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
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  const WAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

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
            width: 1,
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
            style: TextStyle(
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
  final double thickness;

  const WDivider({super.key, this.thickness = 1});

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
  final Widget child;
  final double size;
  final Color? glowColor;

  const WAvatarFrame({
    super.key,
    required this.child,
    this.size = 64,
    this.glowColor,
  });

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
