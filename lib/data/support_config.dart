import 'package:url_launcher/url_launcher.dart';

import '../l10n/locale_service.dart';

/// 客服邮箱 —— 上线前替换为真实客服邮箱
const String kSupportEmail = 'support@warring-states.example.com';

/// 打开客服邮件（mailto），可附带玩家 ID 便于客服定位
Future<void> openSupportMail({String? playerId}) async {
  final subject = LocaleService.I.t('support.mail_subject');
  final body = LocaleService.I.t('support.mail_body',
      args: {'playerId': playerId ?? '-'});
  final uri = Uri(
    scheme: 'mailto',
    path: kSupportEmail,
    queryParameters: {'subject': subject, 'body': body},
  );
  await launchUrl(uri);
}
