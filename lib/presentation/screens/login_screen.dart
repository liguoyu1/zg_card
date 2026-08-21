import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/services/page_nav_io.dart'
    if (dart.library.js_interop) '../../domain/services/page_nav_web.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/auth_service.dart' show AuthService;
import '../../data/device_report_service.dart';
import '../../l10n/locale_service.dart';
import '../providers/auth_provider.dart';

/// 登录注册页 — 邮箱+密码注册/登录 + 游客快捷登录 + Xsolla 平台登录
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isRegister = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _guestNameCtrl = TextEditingController(text: '');
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _guestNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = LocaleService.I.t('auth.err_empty'));
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = LocaleService.I.t('auth.err_email'));
      return;
    }
    if (_isRegister && name.isEmpty) {
      setState(() => _error = LocaleService.I.t('auth.err_nickname'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    final notifier = ref.read(authProvider.notifier);
    final err = _isRegister
        ? await notifier.register(email, password, name)
        : await notifier.login(email, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      // 登录成功：以玩家身份补报，服务端将同 deviceId 的游客记录更新为玩家
      DeviceReportService.report(playerId: ref.read(authProvider)?.playerId);
      Navigator.pop(context);
    }
  }

  Future<void> _guestLogin() async {
    final name = _guestNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = LocaleService.I.t('auth.err_guest_name'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).guestLogin(name);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      // 游客登录：补报但保留游客标记（服务端将同 deviceId 的记录关联游客账号）
      DeviceReportService.report(playerId: ref.read(authProvider)?.playerId, isGuest: true);
      Navigator.pop(context);
    }
  }

  Future<void> _xsollaLogin() async {
    if (!kIsWeb || AuthService.kXsollaClientId.isEmpty) return;
    final origin = '${Uri.base.scheme}://${Uri.base.authority}';
    final redirectUri = '$origin/auth/xsolla';
    // Xsolla Login widget 页（readme 标准入口），登录完成后 redirect 回 login_url
    final url = 'https://login-widget.xsolla.com/latest/'
        '?projectId=${AuthService.kXsollaProjectId}'
        '&login_url=${Uri.encodeComponent(redirectUri)}'
        '&locale=zh_CN';
    try {
      // 同标签页跳转；Xsolla 授权后重定向回 /auth/xsolla 携带 token
      if (kIsWeb) {
        assignPage(url);
      } else {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      setState(() => _error = '无法打开 Xsolla 登录页面');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(LocaleService.I.t(_isRegister ? 'auth.title_register' : 'auth.title_login'), style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          const Icon(Icons.person_outline, size: 64, color: AppTheme.goldAccent),
          const SizedBox(height: 8),
          Text(LocaleService.I.t('auth.app_name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.parchment)),
          const SizedBox(height: 24),

          // Tab: 注册 / 登录
          Row(children: [
            Expanded(child: _tabBtn(LocaleService.I.t('auth.register'), _isRegister)),
            const SizedBox(width: 8),
            Expanded(child: _tabBtn(LocaleService.I.t('auth.login'), !_isRegister)),
          ]),
          const SizedBox(height: 16),

          // 表单
          if (_isRegister) ...[
            _field(_emailCtrl, LocaleService.I.t('auth.email'), Icons.email, false),
            const SizedBox(height: 12),
            _field(_passwordCtrl, LocaleService.I.t('auth.password_min'), Icons.lock, true),
            const SizedBox(height: 12),
            _field(_nameCtrl, LocaleService.I.t('auth.nickname'), Icons.edit, false),
          ] else ...[
            _field(_emailCtrl, LocaleService.I.t('auth.email'), Icons.email, false),
            const SizedBox(height: 12),
            _field(_passwordCtrl, LocaleService.I.t('auth.password'), Icons.lock, true),
          ],
          const SizedBox(height: 8),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(LocaleService.I.t(_isRegister ? 'auth.register' : 'auth.login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          const SizedBox(height: 24),
          Row(children: [const Expanded(child: Divider(color: AppTheme.borderLight)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(LocaleService.I.t('auth.or'), style: const TextStyle(color: AppTheme.textMuted))), const Expanded(child: Divider(color: AppTheme.borderLight))]),
          const SizedBox(height: 16),

          // Xsolla 平台登录（Web 构建配置了 XSOLLA_CLIENT_ID 时显示）
          if (kIsWeb && AuthService.kXsollaClientId.isNotEmpty) ...[
            SizedBox(
              width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _xsollaLogin,
                icon: const Icon(Icons.language, size: 18),
                label: Text(LocaleService.I.t('auth.xsolla_login'),
                    style: const TextStyle(color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.borderGold.withAlpha(120))),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 游客登录
          _field(_guestNameCtrl, LocaleService.I.t('auth.guest_name_hint'), Icons.person, false),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: OutlinedButton(
              onPressed: _loading ? null : _guestLogin,
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.borderGold.withAlpha(120))),
              child: Text(LocaleService.I.t('auth.guest_login'), style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() { _isRegister = label == LocaleService.I.t('auth.register'); _error = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? AppTheme.goldAccent : AppTheme.borderLight, width: active ? 2 : 1)),
        ),
        child: Center(child: Text(label, style: TextStyle(color: active ? AppTheme.goldAccent : AppTheme.textMuted, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 15))),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.parchment),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: AppTheme.textMuted),
        filled: true, fillColor: AppTheme.cardBack,
        prefixIcon: Icon(icon, color: AppTheme.goldAccent, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
