import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// 登录注册页 — 邮箱+密码注册/登录 + 游客快捷登录
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
      setState(() => _error = '请填写邮箱和密码');
      return;
    }
    if (_isRegister && name.isEmpty) {
      setState(() => _error = '请填写昵称');
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
      Navigator.pop(context);
    }
  }

  Future<void> _guestLogin() async {
    final name = _guestNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入昵称');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).guestLogin(name);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('登录', style: TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.agedWood,
        foregroundColor: AppTheme.parchment,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          const Icon(Icons.person_outline, size: 64, color: AppTheme.goldAccent),
          const SizedBox(height: 8),
          const Text('战国卡牌', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.parchment)),
          const SizedBox(height: 24),

          // Tab: 注册 / 登录
          Row(children: [
            Expanded(child: _tabBtn('注册', _isRegister)),
            const SizedBox(width: 8),
            Expanded(child: _tabBtn('登录', !_isRegister)),
          ]),
          const SizedBox(height: 16),

          // 表单
          if (_isRegister) ...[
            _field(_emailCtrl, '邮箱', Icons.email, false),
            const SizedBox(height: 12),
            _field(_passwordCtrl, '密码 (至少6位)', Icons.lock, true),
            const SizedBox(height: 12),
            _field(_nameCtrl, '昵称', Icons.edit, false),
          ] else ...[
            _field(_emailCtrl, '邮箱', Icons.email, false),
            const SizedBox(height: 12),
            _field(_passwordCtrl, '密码', Icons.lock, true),
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
                  : Text(_isRegister ? '注册' : '登录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          const SizedBox(height: 24),
          const Row(children: [Expanded(child: Divider(color: AppTheme.borderLight)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('或', style: TextStyle(color: AppTheme.textMuted))), Expanded(child: Divider(color: AppTheme.borderLight))]),
          const SizedBox(height: 16),

          // 游客登录
          _field(_guestNameCtrl, '输入昵称快速体验', Icons.person, false),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: OutlinedButton(
              onPressed: _loading ? null : _guestLogin,
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.borderGold.withAlpha(120))),
              child: const Text('游客登录', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() { _isRegister = label == '注册'; _error = null; }),
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
