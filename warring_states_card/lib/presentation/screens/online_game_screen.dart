import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';
import 'package:warring_states_card/data/online_game_service.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;

import '../../core/theme/app_theme.dart';
import '../../l10n/locale_service.dart';
import '../../data/balance_service.dart';
import '../../data/persistence/save_manager.dart';
import '../../domain/services/services.dart' show AIDifficulty;
import '../providers/online_game_provider.dart';
import 'game_screen_args.dart';

/// 联机对战服务提供者
final onlineGameServiceProvider = Provider((ref) => OnlineGameService());

/// 匹配状态
enum MatchQueueStatus { idle, searching, matched, error, timeout }

/// 匹配界面
class MatchmakingScreen extends ConsumerStatefulWidget {

  const MatchmakingScreen({super.key, required this.selectedHero});
  final h.Hero selectedHero;

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  MatchQueueStatus _status = MatchQueueStatus.idle;
  String? _errorMessage;
  OnlineGameService get _service => ref.read(onlineGameServiceProvider);

  String? _opponentId;
  String? _opponentName;
  String? _opponentHeroId;
  String? _matchId;
  String _playerName = '';
  bool _loggedIn = false;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _startMatching();
  }

  Future<void> _startMatching() async {
    setState(() => _status = MatchQueueStatus.searching);

    try {
      if (!_loggedIn) {
        _playerName = '玩家${DateTime.now().millisecondsSinceEpoch % 10000}';
        final loginResult = await _service.guestLogin(_playerName);
        if (!loginResult) {
          setState(() {
            _status = MatchQueueStatus.error;
            _errorMessage = LocaleService.I.t('matchmaking.login_fail');
          });
          return;
        }
        _loggedIn = true;
        if (_service.myId != null) {}
      }

      final joined = await _service.joinMatchQueue(
        odID: _service.myId ?? '',
        odName: _playerName,
        odHeroId: widget.selectedHero.id,
        rating: 1000,
      );
      if (!joined) {
        setState(() {
          _status = MatchQueueStatus.error;
          _errorMessage = LocaleService.I.t('matchmaking.queue_fail');
        });
        return;
      }

      _pollMatchStatus();
    } catch (e) {
      setState(() {
        _status = MatchQueueStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _pollMatchStatus() async {
    const maxWait = 10; // 最多等10轮（20秒）
    for (int i = 0; mounted && i < maxWait && _status == MatchQueueStatus.searching; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _elapsed = (i + 1) * 2);

      final result = await _service.checkMatchStatus(
        odID: _service.myId ?? '',
        odHeroId: widget.selectedHero.id,
        rating: 1000,
      );

      if (result != null && result.opponentId != null && mounted) {
        setState(() {
          _status = MatchQueueStatus.matched;
          _matchId = result.matchId;
          _opponentId = result.opponentId;
          _opponentName = result.opponentName;
          _opponentHeroId = result.opponentHeroId;
        });
        return;
      }
    }
    // 超时
    if (mounted && _status == MatchQueueStatus.searching) {
      _service.leaveMatchQueue(_service.myId ?? '');
      setState(() => _status = MatchQueueStatus.timeout);
    }
  }

  void _cancelMatching() {
    setState(() => _status = MatchQueueStatus.idle);
    if (_service.myId != null) {
      _service.leaveMatchQueue(_service.myId!);
    }
    Navigator.pop(context);
  }

  void _startOnlineGame() {
    if (_matchId == null || _opponentId == null || _opponentHeroId == null) return;

    // 查找对手英雄
    final allHeroes = getAllHeroes();
    final opponentHero = allHeroes.firstWhere(
      (h) => h.id == _opponentHeroId,
      orElse: () => allHeroes.first,
    );

    // 初始化联机游戏
    final onlineNotifier = ref.read(onlineGameProvider.notifier);
    onlineNotifier.startOnlineGame(
      myId: _service.myId ?? 'player',
      opponentId: _opponentId!,
      myHero: widget.selectedHero,
      opponentHero: opponentHero,
      // ponytail: matchId & service pass — add when online backend is wired up
    );

    // 导航到对战页
    context.pushReplacement('/battle/online-game', extra: GameScreenArgs(
      playerId: _service.myId ?? 'player',
      playerHero: widget.selectedHero,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('matchmaking.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: Center(child: _buildContent()),
    );
  }

  void _playOffline() async {
    // 根据玩家战绩自适应 AI 难度
    final pd = await SaveManager.loadPlayerData();
    final wins = pd?.winCount ?? 0;
    // 0-5→简单 6-20→普通 21-50→困难 50+→地狱
    final difficulty = wins <= 5 ? AIDifficulty.simple
        : wins <= 20 ? AIDifficulty.normal
        : wins <= 50 ? AIDifficulty.hard
        : AIDifficulty.abyss;

    if (!mounted) return;
    Navigator.pop(context);
    context.push('/battle/game', extra: GameScreenArgs(
      playerId: 'player_1',
      playerHero: widget.selectedHero,
      difficulty: difficulty,
    ));
  }

  Widget _buildContent() {
    switch (_status) {
      case MatchQueueStatus.idle:
        return Text(LocaleService.I.t('matchmaking.connecting'), style: const TextStyle(color: AppTheme.parchment));

      case MatchQueueStatus.searching:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80,
                child: CircularProgressIndicator(strokeWidth: 4, color: AppTheme.goldAccent)),
            const SizedBox(height: 24),
            Text(LocaleService.I.t('matchmaking.searching'),
                style: const TextStyle(color: AppTheme.parchment, fontSize: 18)),
            const SizedBox(height: 8),
            Text('${LocaleService.I.t('matchmaking.current_hero', args: {'name': widget.selectedHero.name})}',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(LocaleService.I.t('matchmaking.waiting', args: {'seconds': '$_elapsed'}),
                  style: const TextStyle(color: AppTheme.goldAccent, fontSize: 13)),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _cancelMatching,
              child: Text(LocaleService.I.t('matchmaking.cancel')),
            ),
          ],
        );

      case MatchQueueStatus.timeout:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(LocaleService.I.t('matchmaking.timeout_title'),
                style: const TextStyle(color: AppTheme.parchment, fontSize: 20)),
            const SizedBox(height: 8),
            Text(LocaleService.I.t('matchmaking.timeout_desc'),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _elapsed = 0);
                _startMatching();
              },
              icon: const Icon(Icons.refresh),
              label: Text(LocaleService.I.t('matchmaking.retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _playOffline,
              icon: const Icon(Icons.android),
              label: Text(LocaleService.I.t('matchmaking.play_ai')),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.parchment),
            ),
          ],
        );

      case MatchQueueStatus.matched:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(LocaleService.I.t('matchmaking.matched'),
                style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(LocaleService.I.t('matchmaking.opponent', args: {'name': _opponentName ?? LocaleService.I.t('matchmaking.opponent_unknown')}),
                style: const TextStyle(color: AppTheme.parchment, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startOnlineGame,
              icon: const Icon(Icons.play_arrow),
              label: Text(LocaleService.I.t('matchmaking.start')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        );

      case MatchQueueStatus.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(_errorMessage ?? LocaleService.I.t('matchmaking.error'),
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _startMatching, child: Text(LocaleService.I.t('matchmaking.retry_btn'))),
          ],
        );
    }
  }
}
