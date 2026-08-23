import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/theme/app_theme.dart';
import '../../data/card_image_service.dart';
import '../../l10n/locale_service.dart';
import '../../shared/widgets/queued_asset_image.dart';
import 'home_screen.dart';

/// 战国卡牌启动画面
/// Warring States themed splash screen with branded design
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // 战国主题色

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // 启动动画
    _controller.forward();

    // 预初始化音频（非阻塞）
    _initAudio();

    // 启动全局预加载：全部英雄 + 前一半卡牌进入队列（后台 3 并发，进度可观察）。
    // 不一次加载全部卡牌，避免启动带宽压力；剩余卡牌由卡牌页进入时按展示顺序补齐。
    AssetPreloadQueue.I.queueAll(const []);

    // 进入首页策略：素材加载达标(90%) 或 超时(8秒) 才进入，避免固定秒数闪屏。
    _enterTimer = Timer(const Duration(seconds: 8), _goHome);
    AssetPreloadQueue.I.progress.addListener(_onProgress);
    _checkReadyToEnter();
  }

  Timer? _enterTimer;
  bool _entered = false;

  void _onProgress() => _checkReadyToEnter();

  /// 素材进度达标即进入；由 [progress] 监听驱动。
  void _checkReadyToEnter() {
    if (_entered || !mounted) return;
    if (AssetPreloadQueue.I.progress.value >= 0.9) _goHome();
  }

  void _goHome() {
    if (_entered || !mounted) return;
    _entered = true;
    _enterTimer?.cancel();
    AssetPreloadQueue.I.progress.removeListener(_onProgress);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _initAudio() async {
    try {
      await AudioManager.instance.init();
    } catch (e) {
      // 静默失败，不阻塞启动
      debugPrint('AudioManager init skipped: $e');
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    AssetPreloadQueue.I.progress.removeListener(_onProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [
              Color(0xFF3D2B1F),
              AppTheme.bgDark,
              Color(0xFF1A0F0A),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 主字符 "戰"
                _buildCalligraphyCharacter(),
                const SizedBox(height: 24),

                // 副标题
                _buildSubtitle(),
                const SizedBox(height: 48),

                // 加载指示器
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 书法风格大字
  Widget _buildCalligraphyCharacter() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.goldAccent.withAlpha(51),
            AppTheme.goldAccent.withAlpha(26),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withAlpha(76),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '戰',
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldAccent,
            shadows: [
              Shadow(
                color: AppTheme.goldAccent.withAlpha(128),
                blurRadius: 20,
              ),
              Shadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 副标题
  Widget _buildSubtitle() {
    return Column(
      children: [
        Text(
          LocaleService.I.t('splash.title'),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.parchment,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(128),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Warring States',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppTheme.goldAccent.withAlpha(204),
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  /// 加载指示器
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          // 自定义加载条
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF3D2B1F),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppTheme.goldAccent.withAlpha(76),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const _LoadingProgressBar(),
            ),
          ),
          const SizedBox(height: 12),
          // 百分比 + 已加载 n/总
          ValueListenableBuilder<double>(
            valueListenable: AssetPreloadQueue.I.progress,
            builder: (_, v, __) {
              final pct = (v * 100).clamp(0, 100).toStringAsFixed(0);
              final loaded = AssetPreloadQueue.I.targetLoaded;
              final total = AssetPreloadQueue.I.targetCount;
              final percentText = LocaleService.I.t('splash.loading', args: {'pct': pct});
              final countText = total > 0
                  ? LocaleService.I.t('splash.loading_count', args: {'done': '$loaded', 'total': '$total'})
                  : '';
              return Column(
                children: [
                  Text(
                    percentText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.parchment.withAlpha(153),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countText,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.parchment.withAlpha(102),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          // 当前正在加载的资源名
          ValueListenableBuilder<String>(
            valueListenable: AssetPreloadQueue.I.currentPath,
            builder: (_, path, __) {
              final name = CardImageService.displayNameFor(path);
              if (name.isEmpty) return const SizedBox(height: 14);
              return Text(
                LocaleService.I.t('splash.loading_item', args: {'name': name}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.parchment.withAlpha(102),
                  letterSpacing: 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 加载进度条动画
class _LoadingProgressBar extends StatefulWidget {
  const _LoadingProgressBar();

  @override
  State<_LoadingProgressBar> createState() => _LoadingProgressBarState();
}

class _LoadingProgressBarState extends State<_LoadingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller
      ..stop()
      ..forward(from: AssetPreloadQueue.I.progress.value);
    return ValueListenableBuilder<double>(
      valueListenable: AssetPreloadQueue.I.progress,
      builder: (_, v, __) {
        _controller.value = v;
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldAccent.withAlpha(128),
                  AppTheme.goldAccent,
                  AppTheme.goldAccent.withAlpha(128),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldAccent.withAlpha(128),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
