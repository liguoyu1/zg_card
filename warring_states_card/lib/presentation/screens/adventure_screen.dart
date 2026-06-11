import 'package:flutter/material.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/domain/services/adventure_manager.dart';
import 'package:warring_states_card/domain/services/roguelite_service.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/domain/models/roguelite_run.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import '../widgets/path_map.dart';
import '../widgets/reward_picker.dart';
import 'game_screen.dart';
import '../../core/theme/app_theme.dart';

class AdventureScreen extends StatefulWidget {
  const AdventureScreen({super.key});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  final AdventureManager _manager = AdventureManager();
  final RogueliteService _roguelite = RogueliteService();

  int _selectedChapterIdx = 0;
  RogueliteRun? _run;

  List<AdventureChapter> get _chapters => _manager.chapters;
  AdventureChapter? get _currentChapter =>
      _chapters.isNotEmpty ? _chapters[_selectedChapterIdx] : null;

  @override
  Widget build(BuildContext context) {
    if (_chapters.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          title: Text(LocaleService.I.t('adventure.title')),
          backgroundColor: AppTheme.agedWood,
          foregroundColor: AppTheme.parchment,
        ),
        body: Center(
          child: Text(LocaleService.I.t('adventure.no_missions'),
              style: const TextStyle(color: AppTheme.parchment)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('adventure.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
        actions: [
          if (_run != null)
            TextButton(
              onPressed: _confirmEndRun,
              child: Text(LocaleService.I.t('roguelite.end_run'),
                  style: TextStyle(color: Colors.red[300])),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildChapterTabs(),
          _buildRunStatus(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildChapterTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _chapters.asMap().entries.map((entry) {
          final isSelected = entry.key == _selectedChapterIdx;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChapterIdx = entry.key),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.goldAccent.withAlpha(40) : AppTheme.agedWood,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.goldAccent : AppTheme.parchment.withAlpha(60),
                  ),
                ),
                child: Center(
                  child: Text(
                    entry.value.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.goldAccent : AppTheme.parchment,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRunStatus() {
    if (_run == null) return const SizedBox.shrink();
    final hpPercent = _run!.currentHp / _run!.maxHp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.red, size: 18),
          const SizedBox(width: 6),
          Text('${_run!.currentHp}/${_run!.maxHp}',
              style: TextStyle(color: Colors.red[300], fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: hpPercent.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(
                  hpPercent > 0.5
                      ? Colors.green
                      : (hpPercent > 0.25 ? Colors.orange : Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 18),
          const SizedBox(width: 4),
          Text('${_run!.gold}',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 14)),
          const SizedBox(width: 8),
          Text('${LocaleService.I.t('roguelite.layer')} ${_run!.currentLayer + 1}/${_run!.layers.length}',
              style: TextStyle(color: AppTheme.parchment.withAlpha(150), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_run != null) return _buildRunView();
    return _buildChapterOverview();
  }

  Widget _buildChapterOverview() {
    final chapter = _currentChapter;
    if (chapter == null) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 32),
        Text(chapter.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.parchment.withAlpha(180), fontSize: 14)),
        const SizedBox(height: 48),
        _buildChapterStat('roguelite.missions_total', '${chapter.missions.length}'),
        const SizedBox(height: 8),
        _buildChapterStat('roguelite.segments', '2'),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(LocaleService.I.t('roguelite.start_run')),
              onPressed: _pickHeroForRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterStat(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${LocaleService.I.t(key)}: ',
            style: TextStyle(color: AppTheme.parchment.withAlpha(150))),
        Text(value,
            style: const TextStyle(color: AppTheme.parchment, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRunView() {
    final run = _run!;
    if (!run.isActive) return _buildRunResult();

    return Column(
      children: [
        Expanded(child: PathMap(run: run, onNodeTap: _handleNodeTap)),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(LocaleService.I.t('roguelite.tap_hint'),
              style: TextStyle(color: AppTheme.parchment.withAlpha(120), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRunResult() {
    final won = _run?.result == RunResult.won;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 64,
            color: won ? AppTheme.goldAccent : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            won ? LocaleService.I.t('roguelite.run_won') : LocaleService.I.t('roguelite.run_lost'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: won ? AppTheme.goldAccent : Colors.red[300],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${LocaleService.I.t("roguelite.gold_earned")}: ${_run?.gold ?? 0}',
            style: TextStyle(color: AppTheme.parchment.withAlpha(150)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _run = null),
            child: Text(LocaleService.I.t('roguelite.back_to_chapter')),
          ),
        ],
      ),
    );
  }

  void _pickHeroForRun() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: Text(LocaleService.I.t('roguelite.pick_hero'),
            style: const TextStyle(color: AppTheme.parchment)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _rogueliteHeroes.length,
            itemBuilder: (_, i) {
              final hero = _rogueliteHeroes[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.goldAccent,
                  child: Text(hero.name[0],
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(hero.name,
                    style: const TextStyle(color: AppTheme.parchment)),
                onTap: () {
                  Navigator.pop(ctx);
                  _startRun(hero);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<h.Hero> get _rogueliteHeroes {
    // 简化：取前 4 个学派各 1 个英雄
    return _manager.getAvailableHeroes();
  }

  void _startRun(h.Hero hero) {
    final chapter = _currentChapter;
    if (chapter == null) return;

    setState(() {
      _run = _roguelite.startRun(hero.id, chapter.id, 0);
    });
  }

  void _handleNodeTap(RogueliteNode node) {
    final run = _run;
    if (run == null || !run.isActive) return;

    switch (node.type) {
      case RogueliteNodeType.battle:
      case RogueliteNodeType.boss:
        _startBattle(node);
        break;
      case RogueliteNodeType.rest:
        _doRest();
        break;
      case RogueliteNodeType.shop:
        _showShop(node);
        break;
    }
  }

  void _startBattle(RogueliteNode node) {
    final run = _run;
    final chapter = _currentChapter;
    if (run == null || chapter == null) return;

    // 查找任务对应的对手英雄
    final mission = chapter.missions.where((m) => m.id == node.missionId).firstOrNull;
    if (mission == null) return;

    final opponentHero = getHeroById(mission.enemyHero);
    if (opponentHero == null) return;

    final aiDifficulty = switch (mission.difficulty) {
      Difficulty.easy => AIDifficulty.simple,
      Difficulty.normal => AIDifficulty.normal,
      Difficulty.hard => AIDifficulty.hard,
      Difficulty.extreme => AIDifficulty.abyss,
    };

    // 进入节点
    run.enterNode(node);

    Navigator.push<RogueliteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          playerId: 'player_1',
          playerHero: _getHeroById(run.heroId),
          opponentHero: opponentHero,
          difficulty: aiDifficulty,
          runHp: run.currentHp,
        ),
      ),
    ).then((result) {
      if (result == null || !mounted) return;
      _handleBattleResult(result, node);
    });
  }

  void _handleBattleResult(RogueliteResult result, RogueliteNode node) {
    final run = _run;
    if (run == null) return;

    final isBoss = node.type == RogueliteNodeType.boss;

    if (result.victory) {
      run.applyBattleResult(result.remainingHp, result.goldEarned);

      if (isBoss) {
        // Boss战胜利：征途完成
        run.result = RunResult.won;
        setState(() {});
        return;
      }

      // 选牌奖励
      _showRewardPicker(run);
    } else {
      // 战败
      run.applyBattleResult(0, 0);
      setState(() {});
    }
  }

  void _showRewardPicker(RogueliteRun run) {
    final chapter = _currentChapter;
    if (chapter == null) return;

    // 根据英雄学派筛选奖励卡
    final hero = _getHeroById(run.heroId);
    final rewardCards = _roguelite.getRandomRewardCards(
      owner: hero?.owner,
    );

    if (rewardCards.isEmpty) {
      setState(() {});
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => RewardPicker(
        cards: rewardCards,
        onSelected: (card) {
          run.tempDeck.add(card);
          setState(() {});
        },
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _doRest() {
    final run = _run;
    if (run == null) return;

    run.rest();
    run.currentLayer++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${LocaleService.I.t("roguelite.restored")} (${run.currentHp}/${run.maxHp})',
        ),
      ),
    );
    setState(() {});
  }

  void _showShop(RogueliteNode node) {
    final run = _run;
    if (run == null) return;

    // 简单版商店：用 10 金币换一张随机卡
    if (run.gold < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleService.I.t('roguelite.gold_insufficient'))),
      );
      return;
    }

    final rewardCards = _roguelite.getRandomRewardCards();
    if (rewardCards.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: Text(LocaleService.I.t('roguelite.shop_title'),
            style: const TextStyle(color: AppTheme.parchment)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${LocaleService.I.t("roguelite.shop_hint")} (10💰)',
                style: TextStyle(color: AppTheme.parchment.withAlpha(180))),
            const SizedBox(height: 16),
            ...rewardCards.take(3).map((card) => ListTile(
                  title: Text(card.name,
                      style: const TextStyle(color: AppTheme.parchment)),
                  subtitle: Text(
                    '💰${card.cost} ⚔${card.attack} ❤${card.health}',
                    style: TextStyle(color: AppTheme.parchment.withAlpha(150)),
                  ),
                  onTap: () {
                    run.gold -= 10;
                    run.tempDeck.add(card);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                )),
          ],
        ),
      ),
    );
  }

  h.Hero _getHeroById(String id) {
    return _manager.getAvailableHeroes().firstWhere(
      (h) => h.id == id,
      orElse: () => _manager.getAvailableHeroes().first,
    );
  }

  void _confirmEndRun() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: Text(LocaleService.I.t('roguelite.confirm_end'),
            style: const TextStyle(color: AppTheme.parchment)),
        content: Text(LocaleService.I.t('roguelite.confirm_end_desc'),
            style: TextStyle(color: AppTheme.parchment.withAlpha(180))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.I.t('dialog.cancel'),
                style: const TextStyle(color: AppTheme.parchment)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _run = null);
            },
            child: Text(LocaleService.I.t('dialog.confirm'),
                style: TextStyle(color: Colors.red[300])),
          ),
        ],
      ),
    );
  }
}
