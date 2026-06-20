import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/asset_style.dart';
import '../../domain/models/hero.dart' as hero;
import '../../domain/services/purchase_service.dart';
import '../../data/persistence/save_manager.dart';
import '../../l10n/locale_service.dart';
import '../../domain/services/card_data_provider.dart';
import '../../domain/services/hero_data_provider.dart';
import '../../domain/models/card.dart' as domain;
import '../widgets/tutorial_overlay.dart';
import '../widgets/theme_widgets.dart';
import 'hero_select_screen.dart';
import 'training_screen.dart';
import 'adventure_screen.dart';
import 'pack_screen.dart';
import 'card_library_screen.dart';
import 'leaderboard_screen.dart';

/// 主界面 — 战国风炉石式主菜单
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final data = await SaveManager.loadPlayerData();
    if (data != null && data.firstRun) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => TutorialOverlay(onComplete: _onTutorialDone),
        );
      });
    }
  }

  Future<void> _onTutorialDone() async {
    final data = await SaveManager.loadPlayerData();
    if (data != null) {
      await SaveManager.savePlayerData(data.copyWith(firstRun: false));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WThemeBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildGoldDivider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Column(
                    children: [
                      _buildMenuButton(
                        icon: Icons.shield_outlined,
                        label: LocaleService.I.t('home.btn_battle'),
                        color: AppTheme.healthRed,
                        onTap: () => _startGame(context),
                      ),
                      _buildMenuButton(
                        icon: Icons.sports_esports_outlined,
                        label: LocaleService.I.t('home.btn_training'),
                        color: AppTheme.manaBlue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TrainingScreen()),
                        ),
                      ),
                      _buildMenuButton(
                        icon: Icons.explore_outlined,
                        label: LocaleService.I.t('home.btn_adventure'),
                        color: AppTheme.damageOrange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdventureScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuButton(
                        icon: Icons.card_giftcard_outlined,
                        label: LocaleService.I.t('home.btn_pack'),
                        color: AppTheme.healGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PackScreen(
                                playerId: 'player_1',
                                cardPool: CardDataProvider.getAllCards(),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuButton(
                        icon: Icons.collections_bookmark_outlined,
                        label: LocaleService.I.t('home.btn_collection'),
                        color: AppTheme.daojia,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CardLibraryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuButton(
                        icon: Icons.leaderboard_outlined,
                        label: LocaleService.I.t('home.btn_leaderboard'),
                        color: AppTheme.goldAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                        ),
                      ),
                      if (!PurchaseService.I.isPurchased('starter_bundle'))
                        _buildStarterBanner(),
                      const SizedBox(height: 24),
                      _buildVersionText(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderGold.withAlpha(60)),
        ),
      ),
      child: Row(
        children: [
          // 学派图标装饰
          _buildSchoolEmblem(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '战国卡牌',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'Warring States',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXs,
                    color: AppTheme.textMuted,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          // 画风切换
          _buildStyleToggle(),
        ],
      ),
    );
  }

  Widget _buildSchoolEmblem() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderGold, width: 1.5),
        gradient: RadialGradient(
          colors: [
            AppTheme.goldAccent.withAlpha(30),
            AppTheme.bgMedium,
          ],
        ),
      ),
      child: Center(
        child: Text(
          '戰',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildStyleToggle() {
    final isChibi = AssetStyle.current == AssetStyle.chibiCute;
    return GestureDetector(
      onTap: () {
        setState(() {
          AssetStyle.current = isChibi ? AssetStyle.fantasyRpg : AssetStyle.chibiCute;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgMedium.withAlpha(150),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderLight.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isChibi ? Icons.auto_awesome : Icons.auto_fix_high,
              size: 16,
              color: AppTheme.goldAccent,
            ),
            const SizedBox(width: 4),
            Text(
              isChibi ? 'Q版' : '写实',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldDivider() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.borderGold.withAlpha(60),
            AppTheme.borderGold.withAlpha(120),
            AppTheme.borderGold.withAlpha(60),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return WMenuPlaque(
      icon: icon,
      label: label,
      accentColor: color,
      onTap: onTap,
    );
  }

  Widget _buildStarterBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.goldAccent.withAlpha(40),
              AppTheme.bgLight.withAlpha(200),
              AppTheme.goldAccent.withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.goldAccent.withAlpha(120),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.card_giftcard, color: AppTheme.goldBright, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleService.I.t('home.starter_title'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeMd,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    LocaleService.I.t('home.starter_desc'),
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXs,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final ok = await PurchaseService.I.purchase('starter_bundle');
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('购买成功！'),
                      backgroundColor: AppTheme.healGreen,
                    ),
                  );
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('\$0.99'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionText() {
    return Text(
      LocaleService.I.t('home.version'),
      style: TextStyle(
        fontSize: AppTheme.fontSizeXs,
        color: AppTheme.textMuted.withAlpha(120),
      ),
    );
  }

  void _startGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HeroSelectScreen(),
      ),
    );
  }
}
