import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/quest.dart';
import '../../domain/services/quest_manager.dart';
import '../../l10n/locale_service.dart';
import '../widgets/theme_widgets.dart';

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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(LocaleService.I.t('quest.title'))),
      body: quests.isEmpty
          ? Center(child: Text(LocaleService.I.t('quest.empty'), style: const TextStyle(color: AppTheme.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quests.length + 1,
              itemBuilder: (_, i) {
                if (i == quests.length) return _buildRefreshInfo();
                return WStaggerIn(index: i, child: _buildQuestCard(quests[i], i));
              },
            ),
    );
  }

  Widget _buildQuestCard(DailyQuest q, int idx) {
    final ready = q.completed && !q.claimed;
    final c = q.claimed ? AppTheme.healGreen : (ready ? AppTheme.goldBright : AppTheme.goldAccent);
    return Opacity(
      opacity: q.claimed ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ready ? AppTheme.goldAccent : AppTheme.borderLight, width: ready ? 1.5 : 1),
          boxShadow: [if (ready) BoxShadow(color: AppTheme.goldAccent.withAlpha(70), blurRadius: 16)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WIconMedal(icon: q.claimed ? Icons.check_rounded : Icons.flag_rounded, color: c, size: 44, dim: !ready && !q.claimed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(LocaleService.I.t('quest.${q.id}.title'),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text(LocaleService.I.t('quest.${q.id}.desc'),
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: WProgressBar(value: q.progressPercent, done: q.completed)),
                const SizedBox(width: 8),
                Text('${q.progress}/${q.target}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                WCurrency(amount: q.goldReward, prefix: '+'),
                if (q.dustReward > 0) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.auto_awesome, size: 14, color: AppTheme.rarityEpic),
                  const SizedBox(width: 3),
                  Text('+${q.dustReward}',
                      style: const TextStyle(color: AppTheme.rarityEpic, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
                const Spacer(),
                if (ready)
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(onPressed: () => _claim(idx), child: Text(LocaleService.I.t('quest.claim'))),
                  )
                else if (!q.completed && !q.claimed && _qm.canRefresh)
                  TextButton.icon(
                    onPressed: () => _refreshQuest(idx),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(LocaleService.I.t('quest.refresh')),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.jade),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildRefreshInfo() {
    return Center(
      child: Text(
        '${LocaleService.I.t('quest.refresh_count', args: {'remaining': '${_qm.canRefresh ? 1 : 0}'})}: ${_qm.canRefresh ? 1 : 0}/1',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
    );
  }
}
