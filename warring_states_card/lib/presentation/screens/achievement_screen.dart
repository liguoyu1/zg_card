import 'package:flutter/material.dart';
import '../../domain/models/quest.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/models/models.dart' as domain_model;
import '../../data/persistence/save_manager.dart';
import '../../l10n/locale_service.dart';
import '../../core/theme/app_theme.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});
  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  late Future<PlayerData?> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = SaveManager.loadPlayerData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('achievement.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: FutureBuilder<PlayerData?>(
        future: _dataFuture,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!;
          final achieved = data.achievedMedals;
          final stats = _buildStats(data);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: AchievementService.allAchievements.length,
            itemBuilder: (_, i) {
              final ach = AchievementService.allAchievements[i];
              final unlocked = achieved.contains(ach.id);
              return Card(
                color: AppTheme.agedWood, margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(unlocked ? Icons.emoji_events : Icons.lock, color: unlocked ? AppTheme.goldAccent : Colors.grey, size: 32),
                  title: Text(ach.title, style: TextStyle(color: unlocked ? AppTheme.goldAccent : AppTheme.parchment)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ach.description, style: TextStyle(color: AppTheme.parchment.withAlpha(150))),
                    if (ach.goldReward > 0) Text('+${ach.goldReward}💰', style: const TextStyle(color: AppTheme.goldAccent)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, int> _buildStats(PlayerData data) {
    return { 'winCount': data.winCount, 'cardsCollected': data.unlockedCards.length, 'chaptersCleared': data.achievedMedals.where((m) => m.startsWith('ach_adventure_')).length, 'fusionCount': 0, 'totalDamage': 0 };
  }
}
