// 服务条款页（/terms）— 与 /legal 分开，提供独立的《服务条款》内容。
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/locale_service.dart';

/// 服务条款页：账号、充值、行为规范、免责等
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('terms.title'),
            style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleService.I.t('terms.title'),
                style: const TextStyle(
                    color: AppTheme.goldAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(LocaleService.I.t('terms.updated'),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            _section(context, Icons.assignment_outlined,
                LocaleService.I.t('terms.account'),
                LocaleService.I.t('terms.account_body')),
            _section(context, Icons.currency_exchange_outlined,
                LocaleService.I.t('terms.payment'),
                LocaleService.I.t('terms.payment_body')),
            _section(context, Icons.rule_outlined,
                LocaleService.I.t('terms.conduct'),
                LocaleService.I.t('terms.conduct_body')),
            _section(context, Icons.sync_problem_outlined,
                LocaleService.I.t('terms.liability'),
                LocaleService.I.t('terms.liability_body')),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© ${DateTime.now().year} Warring States Card',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withAlpha(90), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.goldAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: AppTheme.parchment,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}