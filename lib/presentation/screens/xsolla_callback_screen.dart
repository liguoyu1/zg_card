// Xsolla OAuth 回调页（/auth/xsolla）。
// 用户通过 Xsolla Login 授权后携带 access token（# fragment）返回本页，
// 提取 token 后调用服务端验证+合并账号，完成登录后跳回首页。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/device_report_service.dart';
import '../../l10n/locale_service.dart';
import '../providers/auth_provider.dart';

class XsollaCallbackScreen extends ConsumerStatefulWidget {
  const XsollaCallbackScreen({super.key});
  @override
  ConsumerState<XsollaCallbackScreen> createState() => _XsollaCallbackScreenState();
}

class _XsollaCallbackScreenState extends ConsumerState<XsollaCallbackScreen> {
  bool _dispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleToken());
  }

  Future<void> _handleToken() async {
    if (_dispatched) return;
    _dispatched = true;
    // 两格式兼容：XLogin widget redirect 模式 → ?token=<JWT>；
    // implicit OAuth2 → #access_token=<token>
    String token = '';
    try {
      final query = Uri.base.queryParameters;
      if (query.containsKey('token')) token = query['token']!;
      if (token.isEmpty) {
        final hash = Uri.base.fragment;
        final parts = hash.split('&');
        for (final p in parts) {
          final kv = p.split('=');
          if (kv[0] == 'access_token') {
            token = Uri.decodeComponent(kv.length > 1 ? kv[1] : '');
            break;
          }
        }
      }
    } catch (_) {}

    if (token.isEmpty) {
      if (!mounted) return;
      _showError(LocaleService.I.t('auth.xsolla_no_token'));
      return;
    }

    final err = await ref.read(authProvider.notifier).xsollaLogin(token);
    if (!mounted) return;
    if (err != null) {
      _showError(err);
      return;
    }
    // Xsolla 登录成功：补报身份，服务端更新同 deviceId 记录
    final au = ref.read(authProvider);
    DeviceReportService.report(playerId: au?.playerId, playerName: au?.playerName);
    // 跳回首页（go_router 会替换 URL，同时清除 fragment 中的 token）
    if (mounted) context.go('/');
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocaleService.I.t('auth.xsolla_login_failed')),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) context.go('/');
            },
            child: Text(LocaleService.I.t('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.goldAccent),
            SizedBox(height: 16),
            Text('正在验证登录…', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}