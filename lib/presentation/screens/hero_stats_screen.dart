import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../core/theme/app_theme.dart';
import 'package:warring_states_card/l10n/locale_service.dart';

/// 英雄全平台统计：学派+英雄 对局/胜率/伤害
class HeroStatsScreen extends StatefulWidget {
  const HeroStatsScreen({super.key});

  @override
  State<HeroStatsScreen> createState() => _HeroStatsScreenState();
}

class _HeroStatsScreenState extends State<HeroStatsScreen> {
  String _scope = 'all';
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _err = ''; });
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/hero-stats?scope=$_scope'));
      if (res.statusCode == 200) {
        _data = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        _err = 'HTTP ${res.statusCode}';
      }
    } catch (e) {
      _err = '$e';
    }
    if (mounted) setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService.I;
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(loc.t('hero_stats.title'), style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.bgDark,
        iconTheme: const IconThemeData(color: AppTheme.parchment),
      ),
      body: Column(
        children: [
          // 范围切换
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final (k, label) in [('all', loc.t('hero_stats.scope_all')), ('day', loc.t('hero_stats.scope_day')), ('week', loc.t('hero_stats.scope_week')), ('month', loc.t('hero_stats.scope_month'))])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _chip(k, label),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_err.isNotEmpty
                    ? Center(child: Text('加载失败: $_err', style: const TextStyle(color: AppTheme.textMuted)))
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView(
                          children: [
                            _buildClasses(),
                            const SizedBox(height: 8),
                            _buildHeroes(),
                          ],
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  Widget _chip(String k, String label) {
    final active = _scope == k;
    return InkWell(
      onTap: () { setState(() { _scope = k; }); _fetch(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.goldAccent.withAlpha(60) : AppTheme.cardBack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppTheme.goldAccent : AppTheme.borderLight),
        ),
        child: Center(child: Text(label, style: TextStyle(color: active ? AppTheme.goldAccent : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildClasses() {
    final loc = LocaleService.I;
    final classes = (_data?['classes'] as List?) ?? const [];
    if (classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(loc.t('hero_stats.empty'), style: const TextStyle(color: AppTheme.textMuted))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Text(loc.t('hero_stats.by_school'), style: const TextStyle(color: AppTheme.goldAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        for (final c in classes) _classTile(c),
      ],
    );
  }

  Widget _classTile(Map<String, dynamic> c) {
    final loc = LocaleService.I;
    final cls = c['heroClass'] as String? ?? '';
    final matches = (c['matches'] as int?) ?? 0;
    final winRate = (c['winRate'] as num?)?.toDouble() ?? 0;
    final damage = (c['totalDamage'] as int?) ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.cardBack, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.t('owner.$cls', fallback: cls), style: const TextStyle(color: AppTheme.parchment, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('${loc.t('hero_stats.matches')} $matches · ${loc.t('hero_stats.winrate')} $winRate%',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$damage', style: const TextStyle(color: AppTheme.goldBright, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(loc.t('hero_stats.damage'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeroes() {
    final loc = LocaleService.I;
    final heroes = (_data?['heroes'] as List?) ?? const [];
    if (heroes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Text(loc.t('hero_stats.by_hero'), style: const TextStyle(color: AppTheme.goldAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        for (final h in heroes) _heroTile(h),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _heroTile(Map<String, dynamic> h) {
    final loc = LocaleService.I;
    final heroId = h['heroId'] as String? ?? '';
    final cls = h['heroClass'] as String? ?? '';
    final matches = (h['matches'] as int?) ?? 0;
    final wins = (h['wins'] as int?) ?? 0;
    final losses = (h['losses'] as int?) ?? 0;
    final winRate = (h['winRate'] as num?)?.toDouble() ?? 0;
    final damage = (h['totalDamage'] as int?) ?? 0;
    final heroName = loc.t('hero.$heroId.name', fallback: heroId);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.cardBack.withAlpha(150), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(heroName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.parchment, fontSize: 12))),
          Expanded(flex: 3, child: Text('$wins/$losses', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
          Expanded(flex: 2, child: Text('$winRate%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
          Expanded(flex: 3, child: Text('$damage', textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.goldBright, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}