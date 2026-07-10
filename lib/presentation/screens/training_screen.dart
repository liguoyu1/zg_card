import 'package:flutter/material.dart';
import 'package:warring_states_card/domain/services/adventure_manager.dart';
import 'package:warring_states_card/domain/services/training_manager.dart';

import 'basic_card_screen.dart';

/// 训练模式界面
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => TrainingScreenState();
}

class TrainingScreenState extends State<TrainingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练模式'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基础出牌 — 认识所有卡牌
          _TrainingCard(
            icon: Icons.collections_bookmark,
            title: '基础出牌',
            subtitle: '浏览所有卡牌，了解卡牌属性与效果',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicCardScreen()),
            ),
          ),
          const SizedBox(height: 12),
          // 原有训练内容
          ..._buildClassicTrainings(),
        ],
      ),
    );
  }

  List<Widget> _buildClassicTrainings() {
    try {
      final manager = TrainingManager();
      final trainings = manager.getUnlockedTrainings();
      return trainings.map((t) {
        final progress = manager.getProgress(t.id);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: _getMedalIcon(progress.medal?.level),
            title: Text(t.name),
            subtitle: Text(t.description),
            trailing: _buildStatusBadge(progress.status),
            onTap: () => _startTraining(context, t),
          ),
        );
      }).toList();
    } catch (_) {
      return [const SizedBox.shrink()];
    }
  }

  Widget _getMedalIcon(MedalLevel? level) {
    if (level == null) return const CircleAvatar(child: Icon(Icons.lock));
    Color color;
    switch (level) {
      case MedalLevel.bronze: color = Colors.brown; break;
      case MedalLevel.silver: color = Colors.grey; break;
      case MedalLevel.gold: color = Colors.amber; break;
      case MedalLevel.special: color = Colors.purple; break;
    }
    return CircleAvatar(backgroundColor: color, child: const Icon(Icons.star, color: Colors.white));
  }

  Widget _buildStatusBadge(TrainingStatus status) {
    Color color;
    String text;
    switch (status) {
      case TrainingStatus.locked:
        color = Colors.grey; text = '锁定'; break;
      case TrainingStatus.unlocked:
        color = Colors.green; text = '可玩'; break;
      case TrainingStatus.inProgress:
        color = Colors.orange; text = '进行中'; break;
      case TrainingStatus.completed:
        color = Colors.blue; text = '已完成'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  void _startTraining(BuildContext context, TrainingMission training) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingDetailScreen(training: training),
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {

  const _TrainingCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class TrainingDetailScreen extends StatelessWidget {
  const TrainingDetailScreen({super.key, required this.training});
  final TrainingMission training;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(training.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(training.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('奖励:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...training.rewards.map((r) => Text('• $r')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 启动训练
                  Navigator.pop(context);
                },
                child: const Text('开始训练'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 冒险模式界面（训练入口）
class TrainingAdventureScreen extends StatelessWidget {
  const TrainingAdventureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AdventureManager();

    return Scaffold(
      appBar: AppBar(
        title: const Text('冒险模式'),
        backgroundColor: Colors.deepOrange[700],
      ),
      body: ListView.builder(
        itemCount: manager.chapters.length,
        itemBuilder: (context, index) {
          final chapter = manager.chapters[index];
          return _buildChapterCard(context, chapter);
        },
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, AdventureChapter chapter) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: Text(chapter.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('进度: ${chapter.clearedCount}/${chapter.totalMissions}'),
        children: chapter.missions.map((m) => _buildMissionTile(context, m)).toList(),
      ),
    );
  }

  Widget _buildMissionTile(BuildContext context, AdventureMission mission) {
    Color difficultyColor;
    switch (mission.difficulty) {
      case Difficulty.easy: difficultyColor = Colors.green; break;
      case Difficulty.normal: difficultyColor = Colors.blue; break;
      case Difficulty.hard: difficultyColor = Colors.orange; break;
      case Difficulty.extreme: difficultyColor = Colors.red; break;
    }

    return ListTile(
      leading: Icon(
        mission.isBoss ? Icons.whatshot : Icons.flag,
        color: mission.isBoss ? Colors.red : Colors.grey,
      ),
      title: Text(mission.name),
      subtitle: Text('奖励: ${mission.rewardGold}金币 + ${mission.rewardCards.length}张卡'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: difficultyColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          mission.difficulty.name.toUpperCase(),
          style: TextStyle(color: difficultyColor, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
      onTap: () {
        if (mission.status != MissionStatus.locked) {
          // TODO: 启动冒险战斗
        }
      },
    );
  }
}