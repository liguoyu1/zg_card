import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/quest.dart';
import '../../domain/services/battle_pass_service.dart';
import '../../domain/services/purchase_service.dart';
import '../../l10n/locale_service.dart';

/// Battle Pass 界面
class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({super.key});

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen> {
  final BattlePassService _bp = BattlePassService.I;

  @override
  Widget build(BuildContext context) {
    final bp = _bp.bp;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('bp.title')),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: Column(
        children: [
          _buildHeader(bp),
          _buildLevelBar(bp),
          Expanded(child: _buildRewardList(bp)),
          if (!bp.premium) _buildPremiumUpsell(),
        ],
      ),
    );
  }

  Widget _buildHeader(BattlePass bp) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('${LocaleService.I.t('bp.level', args: {'level': '${bp.level}'})} ${bp.level}/30',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
          const SizedBox(height: 8),
          Text(bp.premium ? LocaleService.I.t('bp.premium') : LocaleService.I.t('bp.free'),
              style: TextStyle(color: bp.premium ? AppTheme.goldAccent : AppTheme.parchment.withAlpha(150))),
        ],
      ),
    );
  }

  Widget _buildLevelBar(BattlePass bp) {
    final pct = bp.xpToNext > 0 ? bp.xp / bp.xpToNext : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LocaleService.I.t('battle_pass.xp_progress', args: {'xp': '${bp.xp}', 'xpToNext': '${bp.xpToNext}'}), style: TextStyle(color: AppTheme.parchment.withAlpha(150))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(AppTheme.goldAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardList(BattlePass bp) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 30,
      itemBuilder: (_, i) {
        final level = i + 1;
        final freeRewards = BPReward.getFreeRewards(level);
        final premiumRewards = BPReward.getPremiumRewards(level);
        final unlocked = bp.level >= level;

        if (freeRewards.isEmpty && premiumRewards.isEmpty) return const SizedBox.shrink();

        return Card(
          color: AppTheme.agedWood,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: unlocked ? AppTheme.goldAccent : Colors.grey[700],
              child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Row(
              children: [
                ...freeRewards.map((r) => _rewardChip(r, unlocked)),
                ...premiumRewards.map((r) => _rewardChip(r, unlocked)),
              ],
            ),
            trailing: _buildClaimButton(bp, level, freeRewards, premiumRewards),
          ),
        );
      },
    );
  }

  Widget _rewardChip(BPReward r, bool unlocked) {
    final label = r.type == 'gold' ? '💰${r.amount}'
        : r.type == 'pack' ? '📦x${r.amount}'
        : r.name ?? r.type;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        backgroundColor: r.isFree ? Colors.green[800] : AppTheme.goldAccent.withAlpha(100),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget? _buildClaimButton(BattlePass bp, int level, List<BPReward> freeRewards, List<BPReward> premiumRewards) {
    final canClaimFree = freeRewards.any((r) => bp.claimedFreeRewards.contains(r.level));
    final canClaimPremium = premiumRewards.any((r) => bp.claimedPremiumRewards.contains(r.level));
    if (canClaimFree || canClaimPremium) return null;

    final hasFree = freeRewards.isNotEmpty && !bp.claimedFreeRewards.contains(level);
    final hasPremium = premiumRewards.isNotEmpty && !bp.claimedPremiumRewards.contains(level);

    if (!hasFree && !hasPremium) return null;

    return ElevatedButton(
      onPressed: bp.level >= level ? () {
        if (hasFree) _bp.claimFreeReward(level);
        if (hasPremium) _bp.claimPremiumReward(level);
        setState(() {});
      } : null,
      child: Text(LocaleService.I.t('bp.claim')),
    );
  }

  Widget _buildPremiumUpsell() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.star),
          label: Text(LocaleService.I.t('bp.unlock_premium')),
          onPressed: () async {
            // 简单内购
            final purchased = await PurchaseService.I.purchase('battle_pass_premium');
            if (purchased.success) {
              _bp.unlockPremium();
              setState(() {});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
