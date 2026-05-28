import 'package:flutter/material.dart';
import 'package:warring_states_card/domain/services/training_manager.dart';
import 'package:warring_states_card/domain/services/adventure_manager.dart';

/// 训练模式界面
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = TrainingManager();
    final trainings = manager.getUnlockedTrainings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('训练模式'),
        backgroundColor: Colors.amber[700],
      ),
      body: ListView.builder(
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final training = trainings[index];
          final progress = manager.getProgress(training.id);
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: _getMedalIcon(progress.medal?.level),
              title: Text(training.name),
              subtitle: Text(training.description),
              trailing: _buildStatusBadge(progress.status),
              onTap: () => _startTraining(context, training),
            ),
          );
        },
      ),
    );
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

class TrainingDetailScreen extends StatelessWidget {
  final TrainingMission training;
  const TrainingDetailScreen({super.key, required this.training});

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

/// 冒险模式界面
class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key});

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