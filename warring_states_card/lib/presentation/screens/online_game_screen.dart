import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter/material.dart' as mat show Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warring_states_card/domain/models/hero.dart' as h;
import 'package:warring_states_card/data/online_game_service.dart';

/// 联机对战服务提供者
final onlineGameServiceProvider = Provider((ref) => OnlineGameService());

/// 匹配状态
enum MatchQueueStatus { idle, searching, matched, error }

/// 匹配界面
class MatchmakingScreen extends ConsumerStatefulWidget {
  final h.Hero selectedHero;
  
  const MatchmakingScreen({super.key, required this.selectedHero});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  MatchQueueStatus _status = MatchQueueStatus.idle;
  String? _errorMessage;
  OnlineGameService get _service => ref.read(onlineGameServiceProvider);
  
  @override
  void initState() {
    super.initState();
    _startMatching();
  }

  Future<void> _startMatching() async {
    setState(() => _status = MatchQueueStatus.searching);
    
    try {
      // 游客登录
      final loginResult = await _service.guestLogin('玩家${DateTime.now().millisecond}');
      if (!loginResult) {
        setState(() {
          _status = MatchQueueStatus.error;
          _errorMessage = '登录失败，请重试';
        });
        return;
      }
      
      // 加入匹配队列
      final matchResult = await _service.joinMatchQueue(
        odID: 'temp_odID',
        odName: '玩家',
        odHeroId: widget.selectedHero.id,
        rating: 1000,
      );
      
      if (matchResult != null && matchResult.opponentId != null) {
        setState(() => _status = MatchQueueStatus.matched);
      } else {
        _pollMatchStatus();
      }
    } catch (e) {
      setState(() {
        _status = MatchQueueStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _pollMatchStatus() async {
    while (_status == MatchQueueStatus.searching) {
      await Future.delayed(const Duration(seconds: 2));
      
      final result = await _service.checkMatchStatus(
        odID: 'temp_odID',
        odHeroId: widget.selectedHero.id,
        rating: 1000,
      );
      
      if (result != null && result.opponentId != null) {
        setState(() => _status = MatchQueueStatus.matched);
        break;
      }
    }
  }

  void _cancelMatching() {
    setState(() => _status = MatchQueueStatus.idle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('匹配对手'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case MatchQueueStatus.idle:
        return const Text('准备中...');
        
      case MatchQueueStatus.searching:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            const SizedBox(height: 24),
            Text(
              '正在为您匹配对手...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '当前英雄: ${widget.selectedHero.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _cancelMatching,
              child: const Text('取消匹配'),
            ),
          ],
        );
        
      case MatchQueueStatus.matched:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
            const SizedBox(height: 24),
            Text(
              '匹配成功！',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('开始对战'),
            ),
          ],
        );
        
      case MatchQueueStatus.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? '发生错误',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startMatching,
              child: const Text('重试'),
            ),
          ],
        );
    }
  }
}

/// 排行榜界面
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(onlineGameServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        backgroundColor: Colors.amber[800],
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: service.getLeaderboard(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('无法连接服务器'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {}, // 触发重绘
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          
          final entries = snapshot.data ?? [];
          
          if (entries.isEmpty) {
            return const Center(child: Text('暂无数据'));
          }
          
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildLeaderboardItem(context, entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, LeaderboardEntry entry) {
    Color rankColor;
    IconData? rankIcon;
    
    switch (entry.rank) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey[400]!;
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.brown[400]!;
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.grey;
        rankIcon = null;
    }
    
    return mat.Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor,
          child: rankIcon != null
              ? Icon(rankIcon, color: Colors.white)
              : Text('#${entry.rank}', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(entry.odName),
        subtitle: Text(_getRankDisplayName(entry.rankName)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.rating}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text('ELO', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _getRankDisplayName(String rank) {
    final names = {
      'bronze': '青铜',
      'silver': '白银',
      'gold': '黄金',
      'diamond': '钻石',
      'legend': '传说',
    };
    return names[rank] ?? rank;
  }
}