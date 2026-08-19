// 隐私政策与用户数据管理说明页（/privacy）。
// 用于应用商店申报 & 用户查阅：本应用收集哪些数据、如何管理、如何删除。
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/locale_service.dart';

/// 客服邮箱（用户申请导出/删除个人数据、投诉渠道）
const String kDataRequestEmail = 'support@wscard.games';

/// 数据管理说明页
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t('privacy.title'),
            style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleService.I.t('privacy.title'),
                style: const TextStyle(
                    color: AppTheme.goldAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(LocaleService.I.t('privacy.updated'),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            _section(context, Icons.manage_search_outlined,
                LocaleService.I.t('privacy.collect'),
                LocaleService.I.t('privacy.collect_body')),
            _section(context, Icons.rule_outlined,
                LocaleService.I.t('privacy.use'),
                LocaleService.I.t('privacy.use_body')),
            _section(context, Icons.manage_accounts_outlined,
                LocaleService.I.t('privacy.manage'),
                LocaleService.I.t('privacy.manage_body')),
            _section(context, Icons.delete_forever_outlined,
                LocaleService.I.t('privacy.delete'),
                LocaleService.I.t('privacy.delete_body')),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                    Uri.parse('mailto:$kDataRequestEmail?subject=Data%20Request'),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.mail_outline, size: 16),
                label: Text(LocaleService.I.t('privacy.contact_btn'),
                    style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldAccent,
                  side: const BorderSide(color: AppTheme.goldAccent, width: 1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
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
}