import 'dart:math';

import 'package:flutter/material.dart' as mat show Card;
import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warring_states_card/core/theme/app_theme.dart';
import 'package:warring_states_card/data/card_image_service.dart';
import 'package:warring_states_card/data/data_version.dart';
import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/domain/services/balance_sync_service.dart';
import 'package:warring_states_card/domain/models/card.dart' as domain;
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/services/card_pool.dart';
import 'package:warring_states_card/domain/services/hero_data_provider.dart' as provider;
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import 'package:warring_states_card/shared/widgets/queued_asset_image.dart';

import '../providers/auth_provider.dart';
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
    dataVersionNotifier.addListener(_load);
    _load(syncFirst: true);
  }

  @override
  void dispose() {
    dataVersionNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load({bool syncFirst = false}) async {
    if (syncFirst) await BalanceSyncService.refreshNow();
    // 游客：随机开放一名各家基础英雄，持久化到游客档，可随时开玩。
    // 不参与首抽（首抽仅注册用户），纯本地临时可玩。
    final auth = ref.read(authProvider);
    final isGuest = auth?.email == null;
    if (isGuest) {
      var gpd = await SaveManager.loadPlayerData();
      String heroId;
      if (gpd == null || gpd.unlockedHeroes.isEmpty) {
        final pool = CardPool.starterHeroPool;
        heroId = pool[_rng.nextInt(pool.length)];
        gpd ??= PlayerData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Player');
        await SaveManager.savePlayerData(gpd.copyWith(unlockedHeroes: [heroId]));
      } else {
        heroId = gpd.unlockedHeroes.first;
      }
      if (mounted) setState(() { _unlockedHeroes = {heroId}; _loading = false; });
      return;
    }
    final pd = await SaveManager.loadPlayerData();
    if (pd == null) { if (mounted) setState(() => _loading = false); return; }
    var ids = Set<String>.from(pd.unlockedHeroes);
    // 首次使用：从各家基础英雄中随机分配一个初始英雄
    if (ids.isEmpty && pd.firstRun) {
      final pool = CardPool.starterHeroPool;
      ids = {pool[_rng.nextInt(pool.length)]};
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

    final allHeroes = provider.HeroDataProvider.getAllHeroes();
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
                    // 在线匹配（PK）仅注册登录用户可用；游客固定单机体验
                    // （固定英雄+预设卡组，不记档不同步服务端）。
                    final isGuest = ref.read(authProvider)?.email == null;
                    if (widget.isPkMode && isGuest) {
                      _showGuestPkLock(context);
                      return;
                    }
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

  /// 游客点击在线匹配（PK）时的提示：需注册登录后可用。
  void _showGuestPkLock(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: Text(LocaleService.I.t('matchmaking.need_login_title', fallback: '在线匹配需登录'),
            style: const TextStyle(color: AppTheme.parchment, fontSize: 16)),
        content: Text(LocaleService.I.t('matchmaking.need_login', fallback: '游客模式暂不支持在线匹配。注册登录后可与其他玩家对战，并保存进度。'),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.I.t('common.cancel', fallback: '取消'),
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/auth/login');
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.goldAccent, foregroundColor: Colors.black),
            child: Text(LocaleService.I.t('home.guest_register'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context, h.Hero hero) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: const BorderSide(color: AppTheme.borderLight, width: 1),
        ),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.emoji_events_outlined, color: AppTheme.goldAccent, size: 22),
          const SizedBox(height: 8),
          Text(hero.lname, style: const TextStyle(color: AppTheme.parchment, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(LocaleService.I.t('difficulty.select', fallback: '选择难度'),
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 2)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DifficultyButton(
            label: LocaleService.I.t('difficulty.easy'),
            color: AppTheme.healGreen,
            icon: Icons.shield_outlined,
            onTap: () => _startGame(ctx, hero, AIDifficulty.simple),
          ),
          const SizedBox(height: 8),
          _DifficultyButton(
            label: LocaleService.I.t('difficulty.normal'),
            color: AppTheme.manaBlue,
            icon: Icons.sports_martial_arts,
            onTap: () => _startGame(ctx, hero, AIDifficulty.normal),
          ),
          const SizedBox(height: 8),
          _DifficultyButton(
            label: LocaleService.I.t('difficulty.hard'),
            color: AppTheme.damageOrange,
            icon: Icons.local_fire_department_outlined,
            onTap: () => _startGame(ctx, hero, AIDifficulty.hard),
          ),
          const SizedBox(height: 8),
          _DifficultyButton(
            label: LocaleService.I.t('difficulty.extreme'),
            color: AppTheme.healthRed,
            icon: Icons.bolt,
            onTap: () => _startGame(ctx, hero, AIDifficulty.abyss),
          ),
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
                      ? QueuedAssetImage(path: p,
                          placeholderColor: _kingdomColor(hero.kingdom),
                          placeholderBuilder: (_) => Container(color: _kingdomColor(hero.kingdom),
                              child: Center(child: Text(hero.lname[0], style: const TextStyle(fontSize: 32, color: Colors.white)))))
                      : Container(color: _kingdomColor(hero.kingdom),
                          child: Center(child: Text(hero.lname[0], style: const TextStyle(fontSize: 32, color: Colors.white))));
                }()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: [
                    Flexible(child: Text(hero.lname, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
                    if (!unlocked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock, color: Colors.grey, size: 14),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(LocaleService.I.t('hero_select.class_and_kingdom', args: {'className': _className(hero.className), 'kingdom': hero.lkingdom}),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.favorite, size: 14, color: AppTheme.healthRed),
                    const SizedBox(width: 3),
                    Text('${hero.health}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.bolt, size: 14, color: AppTheme.manaBlue),
                    const SizedBox(width: 3),
                    Flexible(child: Text(hero.lpowerName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
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
  const _DifficultyButton({required this.label, required this.color, required this.icon, required this.onTap});
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withAlpha(36),
                  AppTheme.bgMedium.withAlpha(220),
                  color.withAlpha(22),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: color.withAlpha(110), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: 2,
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
}
