import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/auth_service.dart' show AuthService, AuthState;

/// 认证状态 Provider — 全局登录状态管理
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState?>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState?> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(null);

  /// 应用启动时从本地恢复登录态
  Future<void> loadSession() async {
    state = await _service.loadSession();
  }

  bool get isLoggedIn => state != null;

  /// 邮箱注册
  Future<String?> register(String email, String password, String name) async {
    final err = await _service.register(email, password, name);
    if (err == null) state = _service.state;
    return err;
  }

  /// 邮箱登录
  Future<String?> login(String email, String password) async {
    final err = await _service.login(email, password);
    if (err == null) state = _service.state;
    return err;
  }

  /// 游客登录
  Future<String?> guestLogin(String name) async {
    final err = await _service.guestLogin(name);
    if (err == null) state = _service.state;
    return err;
  }

  /// 登出
  Future<void> logout() async {
    await _service.logout();
    state = null;
  }

  /// 获取当前玩家ID
  String? get playerId => state?.playerId;

  /// 获取当前玩家昵称
  String? get playerName => state?.playerName;
}
