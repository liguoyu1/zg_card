import '../widgets/theme_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      // 登录成功：补报身份，服务端更新同 deviceId 记录
      final au = ref.read(authProvider);
      DeviceReportService.report(playerId: au?.playerId, playerName: au?.playerName);
      _leaveLogin();
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
      // 游客登录：不补报身份（游客记录保持原样，账号/昵称无值仍按游客统计）
      _leaveLogin();
    }
  }

  /// 登录成功后离开登录页。
  /// 直接访问 /auth/login 时路由栈里没有上一页，pop 会把唯一页面弹掉
  /// （表现为画布消失、只剩 index.html 的 SEO 正文），所以先判断能否 pop。
  void _leaveLogin() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/');
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
    final isReg = _isRegister;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(LocaleService.I.t(isReg ? 'auth.title_register' : 'auth.title_login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(children: [
          const SizedBox(height: 12),
          // 印章徽记 + 描金标题
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFFFFE19A), Color(0xFFD9A441), Color(0xFF8A5A14)]),
              border: Border.all(color: const Color(0xFFFFF0C2), width: 2),
              boxShadow: [BoxShadow(color: AppTheme.goldAccent.withAlpha(110), blurRadius: 22)],
            ),
            alignment: Alignment.center,
            child: const Text('戰', style: TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w900, color: Color(0xFF5A1E0E))),
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (r) => AppTheme.goldGradient.createShader(r),
            child: Text(LocaleService.I.t('auth.app_name'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
          ),
          const SizedBox(height: 22),
          // 注册 / 登录 胶囊分段
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF14100D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(children: [
              _tabBtn(LocaleService.I.t('auth.register'), isReg),
              _tabBtn(LocaleService.I.t('auth.login'), !isReg),
            ]),
          ),
          const SizedBox(height: 18),
          // 表单面板
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              gradient: AppTheme.panelGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Column(children: [
              _field(_emailCtrl, LocaleService.I.t('auth.email'), Icons.mail_outline_rounded, false),
              const SizedBox(height: 12),
              _field(_passwordCtrl, LocaleService.I.t(isReg ? 'auth.password_min' : 'auth.password'), Icons.lock_outline_rounded, true),
              if (isReg) ...[
                const SizedBox(height: 12),
                _field(_nameCtrl, LocaleService.I.t('auth.nickname'), Icons.edit_outlined, false),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.cinnabar),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.cinnabar, fontSize: 13))),
                ]),
              ],
              const SizedBox(height: 16),
              WPrimaryButton(
                label: LocaleService.I.t(isReg ? 'auth.register' : 'auth.login'),
                icon: isReg ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                height: 50,
                onTap: _loading ? null : _submit,
                trailing: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : null,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider(color: AppTheme.borderLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(LocaleService.I.t('auth.or'),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1)),
            ),
            const Expanded(child: Divider(color: AppTheme.borderLight)),
          ]),
          const SizedBox(height: 16),
          // Xsolla（Web 构建配置了 XSOLLA_CLIENT_ID 时显示）
          if (kIsWeb && AuthService.kXsollaClientId.isNotEmpty) ...[
            _outline(Icons.language_rounded, LocaleService.I.t('auth.xsolla_login'), _loading ? null : _xsollaLogin),
            const SizedBox(height: 12),
          ],
          _field(_guestNameCtrl, LocaleService.I.t('auth.guest_name_hint'), Icons.person_outline_rounded, false),
          const SizedBox(height: 12),
          _outline(Icons.sports_esports_outlined, LocaleService.I.t('auth.guest_login'), _loading ? null : _guestLogin, primary: true),
        ]),
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _isRegister = label == LocaleService.I.t('auth.register'); _error = null; }),
        child: AnimatedContainer(
          duration: AppTheme.durMed,
          curve: AppTheme.curveOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: active ? AppTheme.goldGradient : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [if (active) BoxShadow(color: AppTheme.goldAccent.withAlpha(90), blurRadius: 10)],
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: active ? const Color(0xFF1A1206) : AppTheme.textSecondary,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14.5,
                )),
          ),
        ),
      ),
    );
  }

  /// 描金次级按钮（Xsolla / 游客）
  Widget _outline(IconData icon, String label, VoidCallback? onTap, {bool primary = false}) {
    final c = primary ? AppTheme.goldBright : AppTheme.textSecondary;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: c),
        label: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: primary ? AppTheme.goldAccent.withAlpha(26) : Colors.transparent,
          side: BorderSide(color: AppTheme.goldAccent.withAlpha(primary ? 150 : 90), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      cursorColor: AppTheme.goldBright,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        filled: true, fillColor: const Color(0xFF14100D),
        prefixIcon: Icon(icon, color: AppTheme.goldAccent, size: 19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.4)),
      ),
    );
  }
}
