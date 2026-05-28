import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/services/services.dart';
import 'hero_select_screen.dart';
import 'training_screen.dart';
import 'online_game_screen.dart';
import 'game_screen.dart';

/// 主界面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('战国卡牌'),
        centerTitle: true,
        backgroundColor: Colors.amber[800],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 游戏标题
                const Text(
                  '🎴 战国卡牌',
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
                
                // 主菜单按钮
                _buildMenuButton(
                  context,
                  icon: Icons.play_arrow,
                  label: '开始对战',
                  color: Colors.red[600]!,
                  onTap: () => _startGame(context),
                ),
                const SizedBox(height: 16),
                
                _buildMenuButton(
                  context,
                  icon: Icons.sports_esports,
                  label: '训练模式',
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
                  label: '冒险模式',
                  color: Colors.orange[600]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdventureScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildMenuButton(
                  context,
                  icon: Icons.leaderboard,
                  label: '排行榜',
                  color: Colors.purple[600]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                  ),
                ),
                const SizedBox(height: 32),
                
                // 版本信息
                Text(
                  'v1.0.0 | Phase 14',
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