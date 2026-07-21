import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/persistence/save_manager.dart';
import '../../domain/models/quest.dart';
import '../../domain/services/achievement_service.dart';
import '../../l10n/locale_service.dart';

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
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final d = await SaveManager.loadPlayerData();
    final col = await SaveManager.loadCollection();
    final h = await SaveManager.loadMatchHistory();
    if (mounted) setState(() { _data = d; _collection = col; _history = h; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('achievement.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.goldAccent,
          labelColor: AppTheme.goldAccent,
          unselectedLabelColor: AppTheme.parchment.withAlpha(153),
          tabs: [
            Tab(text: '${LocaleService.I.t('achievement.title')} (${_data?.achievedMedals.length ?? 0}/${AchievementService.allAchievements.length})'),
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
    final data = _data;
    if (data == null) return _buildEmptyState();
    final achieved = data.achievedMedals;
    final col = _collection ?? Collection();
    final stats = AchievementService.buildStats(data, col, _history);
    final achList = AchievementService.allAchievements;

    final filtered = _category == _AchCategory.all
        ? achList
        : achList.where((a) => _categoryFilter(a.id)).toList();

    return Column(children: [
      // 分类栏
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.cardBack,
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: _AchCategory.values.map((cat) {
                final sel = _category == cat;
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: Text(_catLabel(cat), style: TextStyle(fontSize: 11, color: sel ? Colors.white : AppTheme.parchment)),
                      selected: sel, selectedColor: AppTheme.goldAccent,
                      backgroundColor: Colors.grey[800],
                      onSelected: (_) => setState(() => _category = cat),
                      visualDensity: VisualDensity.compact,
                    ));
              }).toList()))),
      // 统计摘要 + 称号
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.bgMedium.withAlpha(120),
          child: Row(children: [
            Text(LocaleService.I.t('achievement.unlocked_count', args: {'unlocked': '${achieved.length}', 'total': '${achList.length}'}),
                style: const TextStyle(color: AppTheme.goldAccent, fontSize: 13)),
            const Spacer(),
            Text(LocaleService.I.t('achievement.level_label', args: {'level': '${data.level}'}), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
      // 称号行
      if (_titleText(data, achList) != '')
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.goldAccent.withAlpha(25),
            child: Row(children: [
              const Icon(Icons.emoji_events, color: AppTheme.goldAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_titleText(data, achList),
                  style: const TextStyle(color: AppTheme.goldAccent, fontSize: 13, fontWeight: FontWeight.bold))),
            ])),
      // 列表
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final ach = filtered[i];
          final unlocked = achieved.contains(ach.id);
          final pi = AchievementService.progressInfo(ach.id);
          var current = pi != null ? (stats[pi.statKey] ?? 0) : 0;
          final maxVal = pi?.threshold ?? 100;
          final isRate = pi?.isRate ?? false;
          // 胜率成就：不足20场样本时 UI 显示 0% 避免假满条
          if (isRate && (stats['totalMatches'] ?? 0) < 20) current = 0;
          return _AchCard(
            ach: ach, unlocked: unlocked,
            current: current, maxVal: maxVal, isRate: isRate,
          );
        },
      )),
    ]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        LocaleService.I.t('achievement.no_data'),
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  String _titleText(PlayerData data, List<Achievement> achList) {
    final titles = achList
        .where((a) => a.titleReward != null && data.achievedMedals.contains(a.id))
        .map((a) => a.titleReward!).toList();
    if (titles.isEmpty) return '';
    return '${LocaleService.I.t('achievement.reward_title', args: {'title': titles.last})}'
        '${titles.length > 1 ? ' (+${titles.length - 1})' : ''}';
  }

  bool _categoryFilter(String achId) {
    switch (_category) {
      case _AchCategory.battle: return achId.contains('win') || achId.contains('match') || achId.contains('damage') || achId.contains('winrate');
      case _AchCategory.collection: return achId.contains('collect');
      case _AchCategory.adventure: return achId.contains('adventure');
      case _AchCategory.gold: return achId.contains('gold');
      case _AchCategory.streak: return achId.contains('streak');
      case _AchCategory.hero: return achId.contains('hero');
      case _AchCategory.all: return true;
    }
  }

  String _catLabel(_AchCategory cat) {
    switch (cat) {
      case _AchCategory.all: return LocaleService.I.t('achievement.categories.all');
      case _AchCategory.battle: return LocaleService.I.t('achievement.categories.battle');
      case _AchCategory.collection: return LocaleService.I.t('achievement.categories.collection');
      case _AchCategory.adventure: return LocaleService.I.t('achievement.categories.adventure');
      case _AchCategory.gold: return LocaleService.I.t('achievement.categories.gold');
      case _AchCategory.streak: return LocaleService.I.t('achievement.categories.streak');
      case _AchCategory.hero: return LocaleService.I.t('achievement.categories.hero');
    }
  }

  // ───── 统计页 ─────
  Widget _buildStatsTab() {
    final data = _data;
    if (data == null) return _buildEmptyState();
    final history = _history;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _st(Icons.sports_kabaddi, LocaleService.I.t('achievement.stats_battle'),
            LocaleService.I.t('achievement.stats_battle_format', args: {
              'matches': '${data.totalMatches}', 'wins': '${data.winCount}',
              'winrate': '${data.totalMatches > 0 ? (data.winCount * 100 ~/ data.totalMatches) : 0}',
            })),
        _st(Icons.local_fire_department, LocaleService.I.t('achievement.stats_damage'),
            LocaleService.I.t('achievement.stats_total_damage', args: {'value': '${data.stats['totalDamage'] ?? 0}'})),
        _st(Icons.monetization_on, LocaleService.I.t('achievement.stats_gold'),
            LocaleService.I.t('achievement.stats_total_gold', args: {'value': '${data.stats['totalGoldEarned'] ?? 0}'})),
        _st(Icons.auto_awesome, LocaleService.I.t('achievement.stats_win_streak'),
            LocaleService.I.t('achievement.stats_max_streak', args: {'value': '${data.stats['maxWinStreak'] ?? 0}'})),
        _st(Icons.collections_bookmark, LocaleService.I.t('achievement.stats_collection'),
            LocaleService.I.t('achievement.stats_collection_count', args: {'value': '${data.unlockedCards.length}'})),
        if (data.stats['heroAnyWins'] != null && data.stats['heroAnyWins']! > 0)
          _st(Icons.person, LocaleService.I.t('achievement.stats_hero'),
              LocaleService.I.t('achievement.stats_hero_wins', args: {'value': '${data.stats['heroAnyWins']}'})),
        const SizedBox(height: 16),
        if (history.isNotEmpty) ...[
          Text(LocaleService.I.t('achievement.recent_matches'), style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...history.reversed.take(10).map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: AppTheme.panelDecoration(),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(r.isWin ? LocaleService.I.t('achievement.match_win') : LocaleService.I.t('achievement.match_lose'),
                  style: TextStyle(color: r.isWin ? AppTheme.healGreen : AppTheme.healthRed)),
              Text(LocaleService.I.t('achievement.match_duration', args: {'duration': '${r.duration}'}), style: const TextStyle(color: AppTheme.textMuted)),
            ]),
          )),
        ],
      ],
    ));
  }

  Widget _st(IconData ic, String l, String v) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: AppTheme.panelDecoration(),
        child: Row(children: [
          Icon(ic, color: AppTheme.goldAccent, size: 22), const SizedBox(width: 12),
          Text('$l: $v', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ]));
  }
}

class _AchCard extends StatelessWidget {

  const _AchCard({required this.ach, required this.unlocked,
      required this.current, required this.maxVal, required this.isRate});
  final Achievement ach;
  final bool unlocked;
  final int current;
  final int maxVal;
  final bool isRate;

  @override
  Widget build(BuildContext context) {
    final pct = unlocked ? 1.0 : (maxVal > 0 ? (current / maxVal).clamp(0.0, 1.0) : 0.0);
    final label = isRate ? '$current%' : '${current.clamp(0, maxVal)}/$maxVal';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.panelDecoration(),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(unlocked ? Icons.emoji_events : Icons.lock,
                color: unlocked ? AppTheme.goldAccent : Colors.grey, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ach.title, style: TextStyle(
                  color: unlocked ? AppTheme.goldAccent : AppTheme.parchment,
                  fontWeight: FontWeight.bold, fontSize: 14)),
              Text(ach.description, style: TextStyle(
                  color: AppTheme.parchment.withAlpha(150), fontSize: 12)),
            ])),
            if (ach.titleReward != null)
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.goldAccent.withAlpha(80)),
                  ),
                  child: Text('🏆 ${ach.titleReward}',
                      style: const TextStyle(color: AppTheme.goldAccent, fontSize: 10))),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                    unlocked ? AppTheme.healGreen : AppTheme.goldAccent),
                minHeight: 6,
              )),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(unlocked ? LocaleService.I.t('achievement.completed') : label,
                style: TextStyle(color: unlocked ? AppTheme.healGreen : AppTheme.textMuted, fontSize: 11)),
            if (!unlocked && ach.goldReward > 0)
              Text('+${ach.goldReward}💰', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11)),
            if (unlocked && ach.goldReward > 0)
              Text('✅ +${ach.goldReward}💰', style: const TextStyle(color: AppTheme.healGreen, fontSize: 11)),
          ]),
        ],
      )),
    );
  }
}