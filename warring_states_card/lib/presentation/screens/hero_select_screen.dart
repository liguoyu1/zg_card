import 'dart:math';

import 'package:flutter/material.dart' as mat show Card;
import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warring_states_card/core/theme/app_theme.dart';
import 'package:warring_states_card/data/card_image_service.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/domain/models/card.dart' as domain;
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/l10n/locale_service.dart';

import 'game_screen_args.dart';

class HeroSelectScreen extends ConsumerStatefulWidget {
  final bool isPkMode;
  const HeroSelectScreen({super.key, this.isPkMode = false});
  @override
  ConsumerState<HeroSelectScreen> createState() => _HeroSelectScreenState();
}

class _HeroSelectScreenState extends ConsumerState<HeroSelectScreen> {
  String _selectedClass = 'all';
  Set<String> _unlockedHeroes = {};
  bool _loading = true;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pd = await SaveManager.loadPlayerData();
    if (pd == null) { if (mounted) setState(() => _loading = false); return; }
    var ids = Set<String>.from(pd.unlockedHeroes);
    // 首次使用：随机分配一个初始英雄
    if (ids.isEmpty && pd.firstRun) {
      final all = getAllHeroes();
      ids = {all[_rng.nextInt(all.length)].id};
      await SaveManager.savePlayerData(pd.copyWith(unlockedHeroes: ids.toList(), firstRun: false));
    }
    if (mounted) setState(() { _unlockedHeroes = ids; _loading = false; });
  }

  String _schoolName(domain.CardOwner o) => switch (o) {
    domain.CardOwner.bingjia => LocaleService.I.t('owner.bingjia'), domain.CardOwner.fajia => LocaleService.I.t('owner.fajia'),
    domain.CardOwner.rujia => LocaleService.I.t('owner.rujia'), domain.CardOwner.daojia => LocaleService.I.t('owner.daojia'),
    domain.CardOwner.mojia => LocaleService.I.t('owner.mojia'), domain.CardOwner.yinyangjia => LocaleService.I.t('owner.yinyangjia'),
    domain.CardOwner.zonghengjia => LocaleService.I.t('owner.zonghengjia'), domain.CardOwner.neutral => LocaleService.I.t('owner.neutral'),
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()));
    }

    final allHeroes = getAllHeroes();
    final filteredHeroes = _selectedClass == 'all'
        ? allHeroes
        : allHeroes.where((hero) => hero.className == _selectedClass).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('hero_select.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
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
                final unlocked = _unlockedHeroes.contains(hero.id);
                return _HeroCard(
                  hero: hero,
                  unlocked: unlocked,
                  onTap: unlocked ? () {
                    if (widget.isPkMode) {
                      context.push('/battle/online-match', extra: hero);
                    } else {
                      _showDifficultyDialog(context, hero);
                    }
                  } : null,
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
      'all': LocaleService.I.t('hero_select.all'), 'bingjia': LocaleService.I.t('owner.bingjia'), 'fajia': LocaleService.I.t('owner.fajia'), 'rujia': LocaleService.I.t('owner.rujia'),
      'mojia': LocaleService.I.t('owner.mojia'), 'daojia': LocaleService.I.t('owner.daojia'), 'yinyangjia': LocaleService.I.t('owner.yinyangjia'), 'zonghengjia': LocaleService.I.t('owner.zonghengjia'),
    };
    return Container(
      height: 50, padding: const EdgeInsets.symmetric(vertical: 8),
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
              onSelected: (s) { if (s) setState(() => _selectedClass = cls); },
              selectedColor: AppTheme.goldAccent,
              backgroundColor: AppTheme.agedWood,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.parchment, fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context, h.Hero hero) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: Text(hero.name, style: const TextStyle(color: AppTheme.parchment)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DifficultyButton(label: LocaleService.I.t('difficulty.easy'), color: Colors.green, onTap: () => _startGame(ctx, hero, AIDifficulty.simple)),
          const SizedBox(height: 6),
          _DifficultyButton(label: LocaleService.I.t('difficulty.normal'), color: Colors.blue, onTap: () => _startGame(ctx, hero, AIDifficulty.normal)),
          const SizedBox(height: 6),
          _DifficultyButton(label: LocaleService.I.t('difficulty.hard'), color: Colors.orange, onTap: () => _startGame(ctx, hero, AIDifficulty.hard)),
          const SizedBox(height: 6),
          _DifficultyButton(label: LocaleService.I.t('difficulty.extreme'), color: Colors.red, onTap: () => _startGame(ctx, hero, AIDifficulty.abyss)),
        ]),
      ),
    );
  }

  void _startGame(BuildContext ctx, h.Hero hero, AIDifficulty difficulty) {
    Navigator.pop(ctx);
    context.push('/battle/game', extra: GameScreenArgs(
      playerId: 'player_1', playerHero: hero, difficulty: difficulty,
    ));
  }
}

class _HeroCard extends StatelessWidget {

  const _HeroCard({required this.hero, required this.unlocked, this.onTap});
  final h.Hero hero;
  final bool unlocked;
  final VoidCallback? onTap;

  Color _kingdomColor(String k) {
    const colors = {'秦': Colors.black87, '齐': Colors.purple, '楚': Colors.red,
      '赵': Colors.orange, '魏': Colors.blue, '韩': Colors.green, '燕': Colors.teal};
    return colors[k] ?? Colors.brown;
  }

  String _className(String c) {
    final m = {'bingjia': LocaleService.I.t('owner.bingjia'), 'fajia': LocaleService.I.t('owner.fajia'), 'rujia': LocaleService.I.t('owner.rujia'), 'daojia': LocaleService.I.t('owner.daojia'),
      'mojia': LocaleService.I.t('owner.mojia'), 'yinyangjia': LocaleService.I.t('owner.yinyangjia'), 'zonghengjia': LocaleService.I.t('owner.zonghengjia')};
    return m[c] ?? c;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;
    final imgW = isSmall ? 72.0 : 100.0;
    final cardH = isSmall ? 96.0 : 120.0;
    final nameSize = isSmall ? 15.0 : 18.0;
    final opacity = unlocked ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: mat.Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: unlocked ? AppTheme.cardBack : AppTheme.cardBack.withAlpha(100),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: cardH,
            child: Row(children: [
              // 英雄上半身
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                child: SizedBox(width: imgW, height: cardH, child: () {
                  final p = CardImageService.getHeroImageAsset(hero.id);
                  return p.isNotEmpty
                      ? Image.asset(p, fit: BoxFit.cover, alignment: Alignment.topCenter)
                      : Container(color: _kingdomColor(hero.kingdom),
                          child: Center(child: Text(hero.name[0], style: const TextStyle(fontSize: 32, color: Colors.white))));
                }()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: [
                    Flexible(child: Text(hero.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
                    if (!unlocked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock, color: Colors.grey, size: 14),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(LocaleService.I.t('hero_select.class_and_kingdom', args: {'className': _className(hero.className), 'kingdom': hero.kingdom}),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.favorite, size: 14, color: AppTheme.healthRed),
                    const SizedBox(width: 3),
                    Text('${hero.health}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.bolt, size: 14, color: AppTheme.manaBlue),
                    const SizedBox(width: 3),
                    Flexible(child: Text(hero.heroPowerName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                  ]),
                ]),
              ),
              Padding(padding: const EdgeInsets.all(4),
                  child: Icon(unlocked ? Icons.chevron_right : Icons.lock, color: AppTheme.goldAccent, size: isSmall ? 18 : 24)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({required this.label, required this.color, required this.onTap});
  final String label; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
        child: Text(label),
      ),
    );
  }
}