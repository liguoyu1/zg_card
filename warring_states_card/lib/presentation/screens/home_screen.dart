import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/domain/services/purchase_service.dart';
import 'package:warring_states_card/domain/services/card_data_provider.dart';
import 'package:warring_states_card/domain/models/models.dart' as domain;
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import 'package:warring_states_card/presentation/screens/adventure_screen.dart';
import 'package:warring_states_card/presentation/screens/pack_screen.dart';
import 'package:warring_states_card/presentation/screens/card_library_screen.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import 'hero_select_screen.dart';
import 'training_screen.dart' show TrainingScreen;
import 'online_game_screen.dart' hide LeaderboardScreen;
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/core/asset_style.dart';
import 'quest_screen.dart';
import 'achievement_screen.dart';
import 'battle_pass_screen.dart';
import '../widgets/tutorial_overlay.dart';

/// 主界面
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
      appBar: AppBar(
        title: Text(LocaleService.I.t('home.title')),
        centerTitle: true,
        backgroundColor: Colors.amber[800],
        actions: [
          IconButton(
            icon: Icon(
              AssetStyle.current == AssetStyle.chibiCute
                  ? Icons.auto_awesome
                  : Icons.auto_fix_high,
            ),
            tooltip: '切换画风',
            onPressed: () {
              setState(() {
                AssetStyle.current = AssetStyle.current == AssetStyle.chibiCute
                    ? AssetStyle.fantasyRpg
                    : AssetStyle.chibiCute;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber[100]!,
              Colors.amber[50]!,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎴 ${LocaleService.I.t('home.title')}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Warring States Card',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown[400],
                  ),
                ),
                const SizedBox(height: 48),
                _buildMenuButton(
                  context,
                  icon: Icons.play_arrow,
                  label: LocaleService.I.t('home.btn_battle'),
                  color: Colors.red[600]!,
                  onTap: () => _startGame(context),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  icon: Icons.sports_esports,
                  label: LocaleService.I.t('home.btn_training'),
                  color: Colors.blue[600]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrainingScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  icon: Icons.explore,
                  label: LocaleService.I.t('home.btn_adventure'),
                  color: Colors.orange[600]!,
                  onTap: () {
                    final heroes = getAllHeroes();
                    if (heroes.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdventureScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  icon: Icons.card_giftcard,
                  label: LocaleService.I.t('home.btn_pack'),
                  color: Colors.teal[600]!,
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
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  icon: Icons.collections_bookmark,
                  label: LocaleService.I.t('home.btn_collection'),
                  color: Colors.indigo[600]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CardLibraryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  icon: Icons.leaderboard,
                  label: LocaleService.I.t('home.btn_leaderboard'),
                  color: Colors.purple[600]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                if (!PurchaseService.I.isPurchased('starter_bundle'))
                  _buildStarterBundleBanner(),
                const SizedBox(height: 16),
                Text(
                  LocaleService.I.t('home.version'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarterBundleBanner() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LocaleService.I.t('home.starter_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown)),
                Text(LocaleService.I.t('home.starter_desc'),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final ok = await PurchaseService.I.purchase('starter_bundle');
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('购买成功！')),
                  );
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              child: const Text('\$0.99'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
        ),
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
