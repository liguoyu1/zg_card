import 'package:flutter/material.dart';

/// 伤害指示器动画状态
enum DamageIndicatorState {
  damage,
  heal,
  armor,
}

/// 伤害/治疗数值指示器组件 - 飞起并淡出的动画数字
class DamageIndicator extends StatefulWidget {

  const DamageIndicator({
    super.key,
    required this.value,
    required this.state,
    this.startPosition = Offset.zero,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });
  final int value;
  final DamageIndicatorState state;
  final Offset startPosition;
  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<DamageIndicator> createState() => _DamageIndicatorState();
}

class _DamageIndicatorState extends State<DamageIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 透明度动画：淡入然后淡出
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 8),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 位置动画：向上飘动
    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: Offset(widget.startPosition.dx, widget.startPosition.dy - 40),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 缩放动画：先放大后缩小
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 3),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.6), weight: 5),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return Colors.red;
      case DamageIndicatorState.heal:
        return Colors.green;
      case DamageIndicatorState.armor:
        return Colors.grey;
    }
  }

  String _getPrefix() {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return '-';
      case DamageIndicatorState.heal:
        return '+';
      case DamageIndicatorState.armor:
        return '🛡';
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return Icons.bolt;
      case DamageIndicatorState.heal:
        return Icons.favorite;
      case DamageIndicatorState.armor:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColor().withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _getColor().withAlpha(128),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getPrefix()}${widget.value.abs()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 伤害指示器管理器 - 用于在屏幕上显示多个伤害指示器
class DamageIndicatorOverlay extends StatefulWidget {

  const DamageIndicatorOverlay({
    super.key,
    required this.indicators,
    required this.overlayBuilder,
    required this.onUpdate,
  });
  final List<DamageIndicatorData> indicators;
  final OverlayEntry Function(Widget) overlayBuilder;
  final VoidCallback onUpdate;

  @override
  State<DamageIndicatorOverlay> createState() => _DamageIndicatorOverlayState();
}

class _DamageIndicatorOverlayState extends State<DamageIndicatorOverlay> {
  final List<OverlayEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _showIndicators();
  }

  @override
  void didUpdateWidget(DamageIndicatorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.indicators != oldWidget.indicators) {
      _clearEntries();
      _showIndicators();
    }
  }

  void _showIndicators() {
    for (final indicator in widget.indicators) {
      _addIndicator(indicator);
    }
  }

  OverlayEntry _addIndicator(DamageIndicatorData indicator) {
    late final OverlayEntry entry;
    entry = widget.overlayBuilder(
      _DamageIndicatorWidget(
        value: indicator.value,
        state: indicator.state,
        offset: indicator.offset,
        onComplete: () {
          entry.remove();
          _entries.remove(entry);
          widget.onUpdate();
        },
      ),
    );
    _entries.add(entry);
    Overlay.of(context).insert(entry);
    return entry;
  }

  void _removeEntry(OverlayEntry entry) {
    entry.remove();
    _entries.remove(entry);
  }

  void _clearEntries() {
    for (final entry in _entries) {
      entry.remove();
    }
    _entries.clear();
  }

  @override
  void dispose() {
    _clearEntries();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 伤害指示器数据结构
class DamageIndicatorData {

  const DamageIndicatorData({
    required this.value,
    required this.state,
    required this.offset,
    this.duration = const Duration(milliseconds: 800),
  });
  final int value;
  final DamageIndicatorState state;
  final Offset offset;
  final Duration duration;
}

/// 内部伤害指示器组件
class _DamageIndicatorWidget extends StatefulWidget {

  const _DamageIndicatorWidget({
    required this.value,
    required this.state,
    required this.offset,
    required this.onComplete,
  });
  final int value;
  final DamageIndicatorState state;
  final Offset offset;
  final VoidCallback onComplete;

  @override
  State<_DamageIndicatorWidget> createState() => _DamageIndicatorWidgetState();
}

class _DamageIndicatorWidgetState extends State<_DamageIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 8),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -40),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.8), weight: 3),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.5), weight: 5),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return Colors.red;
      case DamageIndicatorState.heal:
        return Colors.green;
      case DamageIndicatorState.armor:
        return Colors.grey;
    }
  }

  String _getPrefix() {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return '-';
      case DamageIndicatorState.heal:
        return '+';
      case DamageIndicatorState.armor:
        return '';
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return Icons.bolt;
      case DamageIndicatorState.heal:
        return Icons.favorite;
      case DamageIndicatorState.armor:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx - 40,
      top: widget.offset.dy - 20,
      child: Transform.translate(
        offset: _positionAnimation.value,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getColor().withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _getColor().withAlpha(128),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIcon(), color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_prefix${widget.value.abs()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _prefix {
    switch (widget.state) {
      case DamageIndicatorState.damage:
        return '-';
      case DamageIndicatorState.heal:
        return '+';
      case DamageIndicatorState.armor:
        return '';
    }
  }
}