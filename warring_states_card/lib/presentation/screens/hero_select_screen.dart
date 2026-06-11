import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter/material.dart' as mat show Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/models/card.dart' as domain;
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

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
        title: Text(LocaleService.I.t('hero_select.title')),
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
    final classMap = {
      'all': LocaleService.I.t('hero_select.all'),
      'bingjia': LocaleService.I.t('owner.bingjia'),
      'fajia': LocaleService.I.t('owner.fajia'),
      'rujia': LocaleService.I.t('owner.rujia'),
      'mojia': LocaleService.I.t('owner.mojia'),
      'daojia': LocaleService.I.t('owner.daojia'),
      'yinyangjia': LocaleService.I.t('owner.yinyangjia'),
      'zonghengjia': LocaleService.I.t('owner.zonghengjia'),
    };
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: classMap.length,
        itemBuilder: (context, index) {
          final cls = classMap.keys.elementAt(index);
          final isSelected = _selectedClass == cls;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(classMap[cls]!),
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
        title: Text('${LocaleService.I.t('hero_select.select_difficulty')} - ${hero.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DifficultyButton(
              label: LocaleService.I.t('difficulty.easy'),
              color: Colors.green,
              onTap: () => _startGame(context, hero, AIDifficulty.simple),
            ),
            const SizedBox(height: 8),
            _DifficultyButton(
              label: LocaleService.I.t('difficulty.normal'),
              color: Colors.blue,
              onTap: () => _startGame(context, hero, AIDifficulty.normal),
            ),
            const SizedBox(height: 8),
            _DifficultyButton(
              label: LocaleService.I.t('difficulty.hard'),
              color: Colors.orange,
              onTap: () => _startGame(context, hero, AIDifficulty.hard),
            ),
            const SizedBox(height: 8),
            _DifficultyButton(
              label: LocaleService.I.t('difficulty.abyss'),
              color: Colors.red,
              onTap: () => _startGame(context, hero, AIDifficulty.abyss),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, h.Hero hero, AIDifficulty difficulty) {
    Navigator.pop(context);
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
                backgroundImage: hero.artAsset.isNotEmpty
                    ? AssetImage(hero.artAsset) as ImageProvider
                    : null,
                backgroundColor: _getKingdomColor(hero.kingdom),
                child: hero.artAsset.isEmpty
                    ? Text(
                        hero.name[0],
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      )
                    : null,
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
                      LocaleService.I.t('hero_select.class_and_kingdom', args: {
                        'className': _getClassName(hero.className),
                        'kingdom': hero.kingdom,
                      }),
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
    switch (className) {
      case 'bingjia': return LocaleService.I.t('owner.bingjia');
      case 'fajia': return LocaleService.I.t('owner.fajia');
      case 'rujia': return LocaleService.I.t('owner.rujia');
      case 'mojia': return LocaleService.I.t('owner.mojia');
      case 'daojia': return LocaleService.I.t('owner.daojia');
      case 'yinyangjia': return LocaleService.I.t('owner.yinyangjia');
      case 'zonghengjia': return LocaleService.I.t('owner.zonghengjia');
      default: return className;
    }
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
