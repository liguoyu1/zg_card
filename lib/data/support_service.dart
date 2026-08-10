import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/locale_service.dart';

/// 客服工单服务 — 用户反馈提交到服务端，客服在后台查看
/// 服务端自动附带玩家信息 + 近30天订单流水，无需走邮件
class SupportService {
  SupportService._();
  static final SupportService I = SupportService._();

  static const String _baseUrl =
      'https://app-server-production-39d1.up.railway.app';

  static String get _platform => kIsWeb
      ? 'web'
      : Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'other';

  /// 提交反馈工单；成功返回工单 ID，失败返回 null
  static Future<String?> submit(
    String token,
    String message, {
    String? category,
    String? contact,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/support/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          if (category != null) 'category': category,
          if (contact != null && contact.isNotEmpty) 'contact': contact,
          'platform': _platform,
        }),
      );
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}

/// 打开支付平台官方售后入口（Apple 报告问题 / Xsolla 帮助中心）
Future<void> openAfterSalesPage() async {
  // Apple 支付问题走 reportaproblem，其余（Xsolla 等）走 Xsolla 帮助中心
  final url = !kIsWeb && Platform.isIOS
      ? 'https://reportaproblem.apple.com'
      : 'https://help.xsolla.com';
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// 弹出"联系客服"反馈对话框；[category] 传 'payment' / 'game' / 其它
Future<void> showSupportDialog(
  BuildContext context, {
  required String token,
  String? category,
}) async {
  final msgCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(LocaleService.I.t('support.title')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: LocaleService.I.t('support.message_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contactCtrl,
              decoration: InputDecoration(
                hintText: LocaleService.I.t('support.contact_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(LocaleService.I.t('common.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(LocaleService.I.t('support.submit')),
        ),
      ],
    ),
  );
  if (submitted != true) return;

  final message = msgCtrl.text.trim();
  if (message.isEmpty) return;
  final id = await SupportService.submit(
    token,
    message,
    category: category,
    contact: contactCtrl.text.trim(),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(LocaleService.I.t(id != null ? 'support.sent' : 'support.fail')),
  ));
}
