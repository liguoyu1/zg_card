import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/auth_service.dart' show AuthService, AuthState;
import '../../domain/services/balance_sync_service.dart';

/// 认证状态 Provider — 全局登录状态管理
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState?>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState?> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(null);

  /// 应用启动时从本地恢复登录态；本地无会话则尝试 Xsolla 静默无感登录
  bool _loaded = false;

  Future<void> loadSession() async {
    if (_loaded) return;
    _loaded = true;
    state = await _service.loadSession();
    if (state == null) {
      // 浏览器已有 Xsolla 会话 → 静默合并登录
      final err = await _service.trySilentXsollaLogin();
      if (err == null && _service.state != null) {
        state = _service.state;
        _bindBalanceSync();
      }
    } else {
      _bindBalanceSync();
    }
  }

  bool get isLoggedIn => state != null;

  /// 邮箱注册
  Future<String?> register(String email, String password, String name) async {
    final err = await _service.register(email, password, name);
    if (err == null) { state = _service.state; _bindBalanceSync(); }
    return err;
  }

  /// 邮箱登录
  Future<String?> login(String email, String password) async {
    final err = await _service.login(email, password);
    if (err == null) { state = _service.state; _bindBalanceSync(); }
    return err;
  }

  /// 游客登录
  Future<String?> guestLogin(String name) async {
    final err = await _service.guestLogin(name);
    if (err == null) { state = _service.state; _bindBalanceSync(); }
    return err;
  }

  /// Xsolla 平台登录（服务端验证+邮箱合并）
  Future<String?> xsollaLogin(String accessToken) async {
    final err = await _service.xsollaLogin(accessToken);
    if (err == null) { state = _service.state; _bindBalanceSync(); }
    return err;
  }

  /// 登出
  Future<void> logout() async {
    await _service.logout();
    state = null;
    BalanceSyncService.clearSession();
  }

  void _bindBalanceSync() {
    final s = state;
    if (s != null) {
      BalanceSyncService.setSession(s.playerId, s.token, playerName: s.playerName);
      BalanceSyncService.afterLogin();
    }
  }

  /// 获取当前玩家ID
  String? get playerId => state?.playerId;

  /// 获取当前玩家昵称
  String? get playerName => state?.playerName;
}
