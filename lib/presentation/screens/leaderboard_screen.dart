import '../widgets/theme_widgets.dart';
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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(loc.t('leaderboard.title')),
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
                    ...list.asMap().entries.map((e) => WStaggerIn(index: e.key, child: _buildRankTile(e.value))),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14100D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: periods.map((e) {
          final sel = _period == e.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchPeriod(e.$1),
              child: AnimatedContainer(
                duration: AppTheme.durMed,
                curve: AppTheme.curveOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: sel ? AppTheme.goldGradient : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [if (sel) BoxShadow(color: AppTheme.goldAccent.withAlpha(80), blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: Text(e.$2,
                    style: TextStyle(
                        color: sel ? const Color(0xFF1A1206) : AppTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
          );
        }).toList(),
      ),
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

  Widget _chip(String label, bool sel, VoidCallback onTap) =>
      Center(child: WChip(label: label, selected: sel, onTap: onTap, compact: true));

  Widget _buildRewardInfo() {
    final loc = LocaleService.I;
    final key = 'leaderboard.reward_$_period';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.goldAccent.withAlpha(36), AppTheme.goldAccent.withAlpha(8)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withAlpha(70)),
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

    const medals = [Color(0xFFF2C46B), Color(0xFFC9D1D9), Color(0xFFD08A4E)];
    final top = rank <= 3;
    final rankColor = top ? medals[rank - 1] : AppTheme.textMuted;
    final rankWidget = top
        ? Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color.lerp(rankColor, Colors.white, 0.4)!, rankColor, Color.lerp(rankColor, Colors.black, 0.4)!]),
              boxShadow: [BoxShadow(color: rankColor.withAlpha(110), blurRadius: 8)],
            ),
            alignment: Alignment.center,
            child: Text('$rank', style: const TextStyle(color: Color(0xFF2A1A08), fontWeight: FontWeight.w900, fontSize: 14)),
          )
        : Text('$rank', style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 14));

    // wins=ELO 综合分（PK 对局胜场加分），gold=对局金币
    final unit = _metric == 'wins' ? LocaleService.I.t('leaderboard.elo_pt') : LocaleService.I.t('leaderboard.gold');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: top ? 11 : 8),
      decoration: BoxDecoration(
        gradient: top
            ? LinearGradient(colors: [rankColor.withAlpha(40), AppTheme.bgMedium])
            : AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isMe ? AppTheme.goldAccent : (top ? rankColor.withAlpha(120) : AppTheme.borderLight),
            width: isMe ? 1.5 : 1),
      ),
      child: Row(
        children: [
          SizedBox(width: 36, child: Center(child: rankWidget)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isMe ? AppTheme.goldBright : AppTheme.textPrimary,
                    fontWeight: top ? FontWeight.w800 : FontWeight.w600,
                    fontSize: top ? 14.5 : 13)),
          ),
          Text('$score $unit',
              style: TextStyle(
                  color: top ? rankColor : AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _buildMyRank(int? myRank, int? myScore) {
    final loc = LocaleService.I;
    final unit = _metric == 'wins' ? loc.t('leaderboard.elo_pt') : loc.t('leaderboard.gold');
    // 优先展示服务端下发的昵称（未设置昵称时服务端随机生成）；本地保留名兜底
    String name = BalanceSyncService.playerName ?? '';
    final list = (_data?['list'] as List?) ?? const [];
    if (myRank != null) {
      for (final e in list) {
        if (e['isMe'] == true && e['name'] is String && (e['name'] as String).isNotEmpty) {
          name = e['name'] as String;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.goldAccent.withAlpha(50), AppTheme.bgMedium]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldAccent, width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.goldAccent.withAlpha(50), blurRadius: 12)],
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
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 13.5),
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