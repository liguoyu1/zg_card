import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/data_version.dart';
import '../../data/persistence/save_manager.dart';
import '../../domain/services/balance_sync_service.dart';
import '../../domain/models/quest.dart';
import '../../domain/services/achievement_service.dart';
import '../../l10n/locale_service.dart';
import '../../shared/widgets/ad_banner_slot.dart';
import '../widgets/theme_widgets.dart';

enum _AchCategory { all, battle, collection, adventure, gold, streak, hero }

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});
  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  PlayerData? _data;
  Collection? _collection;
  List<MatchRecord> _history = [];
  bool _loading = true;
  _AchCategory _category = _AchCategory.all;

  @override
  void initState() {
    super.initState();
    dataVersionNotifier.addListener(_load);
    _tabCtrl = TabController(length: 2, vsync: this);
    _load(syncFirst: true);
  }

  @override
  void dispose() {
    dataVersionNotifier.removeListener(_load);
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool syncFirst = false}) async {
    if (syncFirst) await BalanceSyncService.refreshNow();
    final d = await SaveManager.loadPlayerData();
    final col = await SaveManager.loadCollection();
    final h = await SaveManager.loadMatchHistory();
    if (mounted)
      setState(() {
        _data = d;
        _collection = col;
        _history = h;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(LocaleService.I.t('achievement.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined, color: AppTheme.goldAccent),
            tooltip: LocaleService.I.t('leaderboard.title'),
            onPressed: () => context.push('/progress/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppTheme.goldAccent),
            tooltip: LocaleService.I.t('hero_stats.title'),
            onPressed: () => context.push('/progress/hero-stats'),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: LocaleService.I.t('achievement.title')),
            Tab(text: LocaleService.I.t('achievement.stats_title')),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildAchievementList(),
        _buildStatsTab(),
      ]),
    );
  }

  Widget _buildAchievementList() {
    // 游客/无存档：用默认档兜底，保证成就项目仍完整显示（已解锁 0、进度 0）
    final data = _data ?? _defaultPlayerData();
    final achieved = data.achievedMedals;
    final col = _collection ?? Collection();
    final stats = AchievementService.buildStats(data, col, _history);
    final achList = AchievementService.allAchievements;

    final filtered = _category == _AchCategory.all
        ? achList
        : achList.where((a) => _categoryFilter(a.id)).toList();

    final total = achList.length;
    final done = achieved.length;
    final title = _titleText(data, achList);
    return Column(children: [
      // 总览：完成度环 + 等级 + 称号
      Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.goldAccent.withAlpha(46), const Color(0xFF1C1612)],
          ),
          border: Border.all(color: AppTheme.goldAccent.withAlpha(110)),
        ),
        child: Row(children: [
          SizedBox(
            width: 64,
            height: 64,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total == 0 ? 0 : done / total),
              duration: const Duration(milliseconds: 900),
              curve: AppTheme.curveOut,
              builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: AppTheme.goldBright,
                    backgroundColor: Colors.black.withAlpha(90),
                  ),
                ),
                Text('${(v * 100).round()}%',
                    style: const TextStyle(color: AppTheme.goldBright, fontSize: 15, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  LocaleService.I.t('achievement.unlocked_count',
                      args: {'unlocked': '$done', 'total': '$total'}),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(LocaleService.I.t('achievement.level_label', args: {'level': '${data.level}'}),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
              if (title != '') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF1A1206), fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          ),
        ]),
      ),
      // 分类栏
      WFilterBar<_AchCategory>(
        values: _AchCategory.values,
        selected: _category,
        label: _catLabel,
        onSelected: (c) => setState(() => _category = c),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      ),
      // 列表
      Expanded(
          child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
            final ach = filtered[i];
            final unlocked = achieved.contains(ach.id);
            final pi = AchievementService.progressInfo(ach.id);
            var current = pi != null ? (stats[pi.statKey] ?? 0) : 0;
            final maxVal = pi?.threshold ?? 100;
            final isRate = pi?.isRate ?? false;
            // 胜率成就：不足20场样本时 UI 显示 0% 避免假满条
            if (isRate && (stats['totalMatches'] ?? 0) < 20) current = 0;
            return WStaggerIn(index: i, child: _AchCard(
              ach: ach,
              unlocked: unlocked,
              current: current,
              maxVal: maxVal,
              isRate: isRate,
            ));
          }, childCount: filtered.length)),
        ),
        // 列表末尾：广告横幅
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child:
                SizedBox(width: double.infinity, child: const AdBannerSlot()),
          ),
        ),
      ])),
    ]);
  }

  /// 游客/无本地存档时的兜底档：全部成就锁定、进度为 0。
  PlayerData _defaultPlayerData() => PlayerData(
        id: 'guest',
        name: 'Player',
      );

  String _titleText(PlayerData data, List<Achievement> achList) {
    final titles = achList
        .where(
            (a) => a.titleReward != null && data.achievedMedals.contains(a.id))
        .map((a) => LocaleService.I.t('achievement.${a.id}.reward'))
        .toList();
    if (titles.isEmpty) return '';
    return '${LocaleService.I.t('achievement.reward_title', args: {
          'title': titles.last
        })}'
        '${titles.length > 1 ? ' (+${titles.length - 1})' : ''}';
  }

  bool _categoryFilter(String achId) {
    switch (_category) {
      case _AchCategory.battle:
        return achId.contains('win') ||
            achId.contains('match') ||
            achId.contains('damage') ||
            achId.contains('winrate');
      case _AchCategory.collection:
        return achId.contains('collect');
      case _AchCategory.adventure:
        return achId.contains('adventure');
      case _AchCategory.gold:
        return achId.contains('gold');
      case _AchCategory.streak:
        return achId.contains('streak');
      case _AchCategory.hero:
        return achId.contains('hero');
      case _AchCategory.all:
        return true;
    }
  }

  String _catLabel(_AchCategory cat) {
    switch (cat) {
      case _AchCategory.all:
        return LocaleService.I.t('achievement.categories.all');
      case _AchCategory.battle:
        return LocaleService.I.t('achievement.categories.battle');
      case _AchCategory.collection:
        return LocaleService.I.t('achievement.categories.collection');
      case _AchCategory.adventure:
        return LocaleService.I.t('achievement.categories.adventure');
      case _AchCategory.gold:
        return LocaleService.I.t('achievement.categories.gold');
      case _AchCategory.streak:
        return LocaleService.I.t('achievement.categories.streak');
      case _AchCategory.hero:
        return LocaleService.I.t('achievement.categories.hero');
    }
  }

  // ───── 统计页 ─────
  Widget _buildStatsTab() {
    final data = _data ?? _defaultPlayerData();
    final history = _history;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _st(
                Icons.sports_kabaddi,
                LocaleService.I.t('achievement.stats_battle'),
                LocaleService.I.t('achievement.stats_battle_format', args: {
                  'matches': '${data.totalMatches}',
                  'wins': '${data.winCount}',
                  'winrate':
                      '${data.totalMatches > 0 ? (data.winCount * 100 ~/ data.totalMatches) : 0}',
                })),
            _st(
                Icons.local_fire_department,
                LocaleService.I.t('achievement.stats_damage'),
                LocaleService.I.t('achievement.stats_total_damage',
                    args: {'value': '${data.stats['totalDamage'] ?? 0}'})),
            _st(
                Icons.monetization_on,
                LocaleService.I.t('achievement.stats_gold'),
                LocaleService.I.t('achievement.stats_total_gold',
                    args: {'value': '${data.stats['totalGoldEarned'] ?? 0}'})),
            _st(
                Icons.auto_awesome,
                LocaleService.I.t('achievement.stats_win_streak'),
                LocaleService.I.t('achievement.stats_max_streak',
                    args: {'value': '${data.stats['maxWinStreak'] ?? 0}'})),
            _st(
                Icons.collections_bookmark,
                LocaleService.I.t('achievement.stats_collection'),
                LocaleService.I.t('achievement.stats_collection_count',
                    args: {'value': '${data.unlockedCards.length}'})),
            if (data.stats['heroAnyWins'] != null &&
                data.stats['heroAnyWins']! > 0)
              _st(
                  Icons.person,
                  LocaleService.I.t('achievement.stats_hero'),
                  LocaleService.I.t('achievement.stats_hero_wins',
                      args: {'value': '${data.stats['heroAnyWins']}'})),
            const SizedBox(height: 16),
            if (history.isNotEmpty) ...[
              Text(LocaleService.I.t('achievement.recent_matches'),
                  style: const TextStyle(
                      color: AppTheme.goldAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...history.reversed.take(10).map((r) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: AppTheme.panelDecoration(),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              r.isWin
                                  ? LocaleService.I.t('achievement.match_win')
                                  : LocaleService.I.t('achievement.match_lose'),
                              style: TextStyle(
                                  color: r.isWin
                                      ? AppTheme.healGreen
                                      : AppTheme.healthRed)),
                          Text(
                              LocaleService.I.t('achievement.match_duration',
                                  args: {'duration': '${r.duration}'}),
                              style:
                                  const TextStyle(color: AppTheme.textMuted)),
                        ]),
                  )),
            ],
            const SizedBox(height: 16),
            // 统计页末尾：广告横幅
            const SizedBox(width: double.infinity, child: AdBannerSlot()),
            const SizedBox(height: 16),
          ],
        ));
  }

  Widget _st(IconData ic, String l, String v) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: AppTheme.panelDecoration(),
        child: Row(children: [
          WIconMedal(icon: ic, color: AppTheme.goldAccent, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(v, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]));
  }
}

class _AchCard extends StatelessWidget {
  const _AchCard(
      {required this.ach,
      required this.unlocked,
      required this.current,
      required this.maxVal,
      required this.isRate});
  final Achievement ach;
  final bool unlocked;
  final int current;
  final int maxVal;
  final bool isRate;

  /// 按奖励分档：铜 / 银 / 金（越难的成就越亮）
  Color get _tier => ach.goldReward >= 500
      ? AppTheme.goldBright
      : ach.goldReward >= 150
          ? const Color(0xFFCBD5DE)
          : const Color(0xFFC98B5A);

  IconData get _icon {
    final id = ach.id;
    if (id.contains('collect')) return Icons.collections_bookmark_rounded;
    if (id.contains('adventure')) return Icons.explore_rounded;
    if (id.contains('gold')) return Icons.savings_rounded;
    if (id.contains('streak')) return Icons.local_fire_department_rounded;
    if (id.contains('hero')) return Icons.person_rounded;
    if (id.contains('damage')) return Icons.flash_on_rounded;
    return Icons.emoji_events_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final pct = unlocked
        ? 1.0
        : (maxVal > 0 ? (current / maxVal).clamp(0.0, 1.0) : 0.0);
    final label = isRate ? '$current%' : '${current.clamp(0, maxVal)}/$maxVal';
    final tier = _tier;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: unlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tier.withAlpha(40), const Color(0xFF1E1813)])
            : AppTheme.panelGradient,
        border: Border.all(color: unlocked ? tier.withAlpha(160) : AppTheme.borderLight),
        boxShadow: [
          if (unlocked) BoxShadow(color: tier.withAlpha(50), blurRadius: 14),
          const BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(children: [
        // 奖章
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? RadialGradient(colors: [Color.lerp(tier, Colors.white, 0.35)!, tier, tier.withAlpha(140)])
                  : const RadialGradient(colors: [Color(0xFF3A3029), Color(0xFF241D18)]),
              border: Border.all(color: unlocked ? Colors.white.withAlpha(120) : AppTheme.borderLight, width: 1.5),
              boxShadow: [if (unlocked) BoxShadow(color: tier.withAlpha(110), blurRadius: 12)],
            ),
            child: Icon(_icon, size: 26, color: unlocked ? const Color(0xFF2A1A08) : AppTheme.textMuted),
          ),
          if (!unlocked)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF14100D),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Icon(Icons.lock_rounded, size: 11, color: AppTheme.textMuted),
              ),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(LocaleService.I.t('achievement.${ach.id}.name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: unlocked ? AppTheme.goldBright : AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5)),
              ),
              if (ach.titleReward != null)
                Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.cinnabar.withAlpha(unlocked ? 200 : 60),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(LocaleService.I.t('achievement.${ach.id}.reward', args: {}),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 2),
            Text(LocaleService.I.t('achievement.${ach.id}.desc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: WProgressBar(value: pct, height: 7, done: unlocked)),
              const SizedBox(width: 10),
              unlocked
                  ? const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.healGreen)
                  : Text(label,
                      style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()])),
              if (ach.goldReward > 0) ...[
                const SizedBox(width: 10),
                Opacity(
                    opacity: unlocked ? 0.55 : 1,
                    child: WCurrency(amount: ach.goldReward, prefix: '+', size: 12)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}
