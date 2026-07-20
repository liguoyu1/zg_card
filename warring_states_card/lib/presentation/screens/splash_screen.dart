import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/theme/app_theme.dart';
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

    // 2秒后自动跳转
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
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
    });
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
          '战国卡牌',
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
      width: 200,
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
              child: _LoadingProgressBar(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.parchment.withAlpha(153),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载进度条动画
class _LoadingProgressBar extends StatefulWidget {
  @override
  State<_LoadingProgressBar> createState() => _LoadingProgressBarState();
}

class _LoadingProgressBarState extends State<_LoadingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _controller.value,
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
