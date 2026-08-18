// 游戏法律法规与相关声明页（从「头像菜单 → 法律法规」进入）。
// 内容含用户协议 / 隐私政策 / 内容合规 / 适龄提示 / 免责声明。
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/locale_service.dart';

/// 线上隐私政策页（应用商店申报 / 原生端固定地址）。
const String kPrivacyPolicyUrl = 'https://wscard.games/privacy';

/// 当前运行环境下的隐私政策页地址：
/// - Web 端：使用当前站点同源 `/privacy`（本地预览跳本地、线上跳线上）；
/// - 原生端（Android/iOS）：固定线上 `https://wscard.games/privacy`。
String get privacyPolicyUrl {
  if (kIsWeb) {
    final base = Uri.base;
    final origin = '${base.scheme}://${base.authority}';
    return '$origin/privacy';
  }
  return kPrivacyPolicyUrl;
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

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
        title: Text(LocaleService.I.t('home.legal'),
            style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleService.I.t('legal.title'),
                style: const TextStyle(
                    color: AppTheme.goldAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(LocaleService.I.t('legal.subtitle'),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),
            // 标题与正文之间：广告横幅（全局横幅已由 ResponsiveShell 统一提供，此处移除）
            _section(context, Icons.privacy_tip_outlined,
                LocaleService.I.t('legal.privacy'),
                LocaleService.I.t('legal.privacy_body')),
            // 查看完整隐私政策网页版（用于应用商店申报 & 用户查阅）
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(privacyPolicyUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('查看完整隐私政策 · 用户协议（网页）',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldAccent,
                  side: const BorderSide(color: AppTheme.goldAccent, width: 1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            _section(context, Icons.verified_outlined,
                LocaleService.I.t('legal.content'),
                LocaleService.I.t('legal.content_body')),
            _section(context, Icons.child_care_outlined,
                LocaleService.I.t('legal.age'),
                LocaleService.I.t('legal.age_body')),
            _section(context, Icons.gavel_outlined,
                LocaleService.I.t('legal.disclaimer'),
                LocaleService.I.t('legal.disclaimer_body')),
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
}