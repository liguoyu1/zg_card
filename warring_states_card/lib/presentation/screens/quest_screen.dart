import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/quest.dart';
import '../../domain/services/quest_manager.dart';
import '../../l10n/locale_service.dart';

/// 每日任务界面
class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  final QuestManager _qm = QuestManager.I;

  @override
  void initState() {
    super.initState();
  }

  void _claim(int index) async {
    final reward = _qm.claimReward(index);
    if (reward.isEmpty) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${LocaleService.I.t('quest.claimed')} +${reward['gold']}💰')),
    );
  }

  void _refreshQuest(int index) {
    _qm.refreshQuest(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final quests = _qm.quests;
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('quest.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: quests.isEmpty
          ? Center(child: Text(LocaleService.I.t('quest.empty'), style: const TextStyle(color: AppTheme.parchment)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quests.length + 1,
              itemBuilder: (_, i) {
                if (i == quests.length) return _buildRefreshInfo();
                return _buildQuestCard(quests[i], i);
              },
            ),
    );
  }

  Widget _buildQuestCard(DailyQuest q, int idx) {
    return Card(
      color: AppTheme.agedWood,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.parchment)),
                      const SizedBox(height: 4),
                      Text(q.description, style: TextStyle(color: AppTheme.parchment.withAlpha(150))),
                    ],
                  ),
                ),
                if (q.completed && !q.claimed)
                  ElevatedButton(
                    onPressed: () => _claim(idx),
                    child: Text(LocaleService.I.t('quest.claim')),
                  ),
                if (q.claimed)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: q.progressPercent,
                minHeight: 8,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(
                  q.completed ? Colors.green : AppTheme.goldAccent,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${q.progress}/${q.target}', style: TextStyle(color: AppTheme.parchment.withAlpha(150))),
                const Spacer(),
                const Icon(Icons.monetization_on, size: 16, color: AppTheme.goldAccent),
                const SizedBox(width: 4),
                Text('+${q.goldReward}', style: const TextStyle(color: AppTheme.goldAccent)),
                if (q.dustReward > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                  Text('+${q.dustReward}', style: const TextStyle(color: Colors.purple)),
                ],
              ],
            ),
            if (!q.completed && !q.claimed && _qm.canRefresh)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _refreshQuest(idx),
                  child: Text(LocaleService.I.t('quest.refresh'), style: TextStyle(color: Colors.blue[300])),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshInfo() {
    return Center(
      child: Text(
        '${LocaleService.I.t('quest.refresh_count')}: ${_qm.canRefresh ? 1 : 0}/1',
        style: TextStyle(color: AppTheme.parchment.withAlpha(120)),
      ),
    );
  }
}
