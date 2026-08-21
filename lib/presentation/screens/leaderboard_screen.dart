import 'dart:async';
import 'package:flutter/material.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/balance_service.dart';
import '../../domain/services/balance_sync_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _period = 'day';
  String _metric = 'wins'; // wins | gold
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final d = await BalanceService.fetchRankings(
        metric: _metric,
        period: _period,
        myId: BalanceSyncService.playerId,
      );
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _switchPeriod(String p) {
    if (p == _period) return;
    setState(() { _period = p; _data = null; });
    _fetch();
  }

  void _switchMetric(String m) {
    if (m == _metric) return;
    setState(() { _metric = m; _data = null; });
    _fetch();
  }

  String _schoolLabel(String cls) => LocaleService.I.t('owner.$cls', fallback: cls);

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService.I;
    final board = _data?['board'] as Map<String, dynamic>?;
    final list = (board?['list'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final myRank = board?['myRank'] as int?;
    final myScore = board?['myScore'] as int?;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(loc.t('leaderboard.title'),
            style: const TextStyle(color: AppTheme.parchment, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.agedWood,
        iconTheme: const IconThemeData(color: AppTheme.goldAccent),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.goldAccent),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
          : RefreshIndicator(
              color: AppTheme.goldAccent,
              onRefresh: _fetch,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // 周期选择
                  _buildPeriodSelector(),
                  const SizedBox(height: 10),
                  // 维度切换
                  _buildMetricToggle(),
                  const SizedBox(height: 12),
                  // 奖励说明
                  _buildRewardInfo(),
                  const SizedBox(height: 16),
                  // 榜单
                  if (list.isEmpty)
                    _emptyCard()
                  else ...[
                    ...list.map((e) => _buildRankTile(e)),
                    const SizedBox(height: 12),
                    // 我的排名
                    _buildMyRank(myRank, myScore),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    final loc = LocaleService.I;
    final periods = [
      ('day', loc.t('leaderboard.tab_day')),
      ('week', loc.t('leaderboard.tab_week')),
      ('month', loc.t('leaderboard.tab_month')),
    ];
    return Row(
      children: periods.map((e) {
        final sel = _period == e.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => _switchPeriod(e.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: sel ? AppTheme.goldAccent : AppTheme.cardBack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sel ? AppTheme.goldBright : AppTheme.borderLight, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(e.$2,
                  style: TextStyle(
                      color: sel ? Colors.white : AppTheme.parchment,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricToggle() {
    final loc = LocaleService.I;
    return Row(
      children: [
        Expanded(
          child: _chip(
            loc.t('leaderboard.metric_wins'),
            _metric == 'wins',
            () => _switchMetric('wins'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            loc.t('leaderboard.metric_gold'),
            _metric == 'gold',
            () => _switchMetric('gold'),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? AppTheme.goldAccent : AppTheme.cardBack,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: sel ? AppTheme.goldBright : AppTheme.borderLight),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : AppTheme.parchment,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildRewardInfo() {
    final loc = LocaleService.I;
    final key = 'leaderboard.reward_$_period';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.goldBright, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.t(key, fallback: ''),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    final loc = LocaleService.I;
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.leaderboard, color: AppTheme.goldAccent, size: 48),
          const SizedBox(height: 12),
          Text(loc.t('leaderboard.empty_list'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRankTile(Map<String, dynamic> entry) {
    final rank = entry['rank'] as int;
    final name = entry['name'] as String? ?? '';
    final score = entry['score'] as int? ?? 0;
    final isMe = entry['isMe'] == true;
    final heroClass = (_metric == 'wins') ? entry['heroClass'] as String? : null;

    // 排名颜色
    Color rankColor;
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 22);
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 20);
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20);
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankWidget = Text('$rank', style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 14));
      rankColor = AppTheme.textMuted;
    }

    final unit = _metric == 'wins' ? LocaleService.I.t('leaderboard.wins') : LocaleService.I.t('leaderboard.gold');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.bgLight.withAlpha(200) : AppTheme.cardBack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: rank <= 3 ? rankColor.withAlpha(100) : AppTheme.borderLight, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(width: 36, child: Center(child: rankWidget)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: isMe ? AppTheme.goldBright : AppTheme.parchment,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          if (heroClass != null && heroClass.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderLight)),
              child: Text(_schoolLabel(heroClass),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ),
            const SizedBox(width: 8),
          ],
          Text('$score $unit',
              style: TextStyle(
                  color: rank <= 3 ? rankColor : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMyRank(int? myRank, int? myScore) {
    final loc = LocaleService.I;
    final unit = _metric == 'wins' ? loc.t('leaderboard.wins') : loc.t('leaderboard.gold');
    final name = BalanceSyncService.playerName ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldAccent, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppTheme.goldAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              myRank != null
                  ? '${loc.t('leaderboard.my_rank')}: #$myRank — $myScore $unit'
                  : loc.t('leaderboard.not_in_list'),
              style: const TextStyle(color: AppTheme.parchment, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (name.isNotEmpty)
            Text(name,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}