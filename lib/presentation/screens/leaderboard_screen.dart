import 'package:flutter/material.dart';
import 'package:warring_states_card/l10n/locale_service.dart';
import '../../core/theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('leaderboard.title'),
            style: const TextStyle(color: AppTheme.parchment, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.agedWood,
        iconTheme: const IconThemeData(color: AppTheme.goldAccent),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard, color: AppTheme.goldAccent, size: 64),
            const SizedBox(height: 16),
            Text(LocaleService.I.t('leaderboard.coming_soon'),
                style: const TextStyle(color: AppTheme.parchment, fontSize: 18)),
            const SizedBox(height: 8),
            Text(LocaleService.I.t('leaderboard.hint'),
                style: TextStyle(color: AppTheme.parchment.withAlpha(120), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
