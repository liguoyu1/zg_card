import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter/material.dart' as mat show Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/models/card.dart' as domain;
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

/// 英雄选择界面
class HeroSelectScreen extends ConsumerStatefulWidget {
  const HeroSelectScreen({super.key});

  @override
  ConsumerState<HeroSelectScreen> createState() => _HeroSelectScreenState();
}

class _HeroSelectScreenState extends ConsumerState<HeroSelectScreen> {
  String _selectedClass = 'all';

  @override
  Widget build(BuildContext context) {
    final allHeroes = getAllHeroes();
    final filteredHeroes = _selectedClass == 'all'
        ? allHeroes
        : allHeroes.where((hero) => hero.className == _selectedClass).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择英雄'),
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildClassTabs(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHeroes.length,
              itemBuilder: (context, index) {
                final hero = filteredHeroes[index];
                return _HeroCard(
                  hero: hero,
                  onTap: () => _showDifficultyDialog(context, hero),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTabs() {
    final classes = ['all', 'bing', 'fa', 'ru', 'mo', 'dao', 'yin', 'zong'];
    final names = {'all': '全部', 'bing': '兵家', 'fa': '法家', 'ru': '儒家', 'mo': '墨家', 'dao': '道家', 'yin': '阴阳家', 'zong': '纵横家'};
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];
          final isSelected = _selectedClass == cls;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(names[cls]!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedClass = cls);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context, h.Hero hero) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择难度 - ${hero.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DifficultyButton(
              label: '简单',
              color: Colors.green,
              onTap: () => _startGame(context, hero, AIDifficulty.simple),
            ),
            const SizedBox(height: 8),
            _DifficultyButton(
              label: '普通',
              color: Colors.blue,
              onTap: () => _startGame(context, hero, AIDifficulty.normal),
            ),
            const SizedBox(height: 8),
            _DifficultyButton(
              label: '困难',
              color: Colors.orange,
              onTap: () => _startGame(context, hero, AIDifficulty.hard),
            ),
            const SizedBox(height: 8),
            _DifficultyButton(
              label: '深渊',
              color: Colors.red,
              onTap: () => _startGame(context, hero, AIDifficulty.abyss),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, h.Hero hero, AIDifficulty difficulty) {
    Navigator.pop(context); // 关闭对话框
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          playerId: 'player_1',
          playerHero: hero,
          difficulty: difficulty,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final h.Hero hero;
  final VoidCallback onTap;

  const _HeroCard({required this.hero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return mat.Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getKingdomColor(hero.kingdom),
                child: Text(
                  hero.name[0],
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_getClassName(hero.className)} · ${hero.kingdom}国',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                        const SizedBox(width: 4),
                        Text('${hero.health}'),
                        const SizedBox(width: 12),
                        Icon(Icons.bolt, size: 16, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        Text(hero.heroPowerName),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _getKingdomColor(String kingdom) {
    final colors = {
      '秦': Colors.black87,
      '齐': Colors.purple,
      '楚': Colors.red,
      '赵': Colors.orange,
      '魏': Colors.blue,
      '韩': Colors.green,
      '燕': Colors.teal,
    };
    return colors[kingdom] ?? Colors.brown;
  }

  String _getClassName(String className) {
    final names = {
      'bing': '兵家',
      'fa': '法家',
      'ru': '儒家',
      'mo': '墨家',
      'dao': '道家',
      'yin': '阴阳家',
      'zong': '纵横家',
    };
    return names[className] ?? className;
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }
}