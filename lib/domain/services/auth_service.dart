import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_config.dart';
import 'xsolla_silent_io.dart'
    if (dart.library.js_interop) 'xsolla_silent_web.dart';

/// 登录状态
class AuthState {
  final String token;
  final String playerId;
  final String playerName;
  final String? email;
  final String? avatar;

  const AuthState({
    required this.token,
    required this.playerId,
    required this.playerName,
    this.email,
    this.avatar,
  });
}

/// 认证服务 — 邮箱密码登录/注册 + 游客登录 + 持久化 + Xsolla 静默登录
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _playerIdKey = 'auth_player_id';
  static const String _playerNameKey = 'auth_player_name';
  static const String _avatarKey = 'auth_avatar';
  static const String _emailKey = 'auth_email';
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Xsolla Login 构建时注入（dart-define）；缺省则静默+按钮均隐藏
  static const String kXsollaClientId = String.fromEnvironment('XSOLLA_CLIENT_ID');
  static const String kXsollaProjectId = String.fromEnvironment('XSOLLA_PROJECT_ID');

  AuthState? _state;
  AuthState? get state => _state;

  /// 从 SharedPreferences 恢复会话
  Future<AuthState?> loadSession() async {
    if (_state != null) return _state;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final pid = prefs.getString(_playerIdKey);
    final name = prefs.getString(_playerNameKey);
    if (token != null && pid != null && name != null) {
      _state = AuthState(
        token: token,
        playerId: pid,
        playerName: name,
        email: prefs.getString(_emailKey),
        avatar: prefs.getString(_avatarKey),
      );
    }
    return _state;
  }

  bool get isLoggedIn => _state != null;

  /// 解析后端公共响应格式 — 兼容 {token, player} 和 {success, data: {token, player}}
  bool _parseAndSave(Map<String, dynamic> body) {
    // 先尝试 data.data 格式 ( {success, data: {token, player}} )
    final data = body['data'] ?? body;
    final token = data['token'] as String?;
    final player = data['player'];
    if (token == null || player == null) return false;
    final pid = player['id'] as String?;
    final pname = player['name'] as String?;
    if (pid == null || pname == null) return false;
    _state = AuthState(
      token: token,
      playerId: pid,
      playerName: pname,
      email: player['email'] as String?,
      avatar: player['avatar'] as String?,
    );
    return true;
  }

  Future<void> _persist() async {
    if (_state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _state!.token);
    await prefs.setString(_playerIdKey, _state!.playerId);
    await prefs.setString(_playerNameKey, _state!.playerName);
    if (_state!.email != null) {
      await prefs.setString(_emailKey, _state!.email!);
    } else {
      await prefs.remove(_emailKey);
    }
    if (_state!.avatar != null) {
      await prefs.setString(_avatarKey, _state!.avatar!);
    }
  }

  /// 邮箱注册
  Future<String?> register(String email, String password, String name) async {
    try {
      // 邀请人：URL ?ref= 优先，否则用本地持久化的邀请人（3 天有效期内）
      String? referrerId;
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        try {
          referrerId = Uri.base.queryParameters['ref'];
        } catch (_) {}
      }
      if (referrerId == null || referrerId.isEmpty) {
        final savedAt = prefs.getInt('invite_referrer_at') ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - savedAt <= 3 * 86400000) {
          referrerId = prefs.getString('invite_referrer_id');
        }
      }
      // 注册成功与否都清除本地邀请人，避免下次他人注册被错误绑定
      await prefs.remove('invite_referrer_id');
      await prefs.remove('invite_referrer_at');
      final uri = Uri.parse('$_baseUrl/api/auth/register');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'name': name,
            if (referrerId != null && referrerId.isNotEmpty)
              'referrerId': referrerId,
          }));
      if (resp.statusCode != 200) return '网络错误';
      final body = jsonDecode(resp.body);
      if (body['error'] != null) return body['error'] as String;
      if (!_parseAndSave(body)) return '解析响应失败';
      await _persist();
      return null;
    } catch (e) {
      debugPrint('AuthService register error: $e');
      return '网络连接失败';
    }
  }

  /// 邮箱登录
  Future<String?> login(String email, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}));
      if (resp.statusCode != 200) return '网络错误';
      final body = jsonDecode(resp.body);
      if (body['error'] != null) return body['error'] as String;
      if (!_parseAndSave(body)) return '解析响应失败';
      await _persist();
      return null;
    } catch (e) {
      debugPrint('AuthService login error: $e');
      return '网络连接失败';
    }
  }

  /// 游客登录
  Future<String?> guestLogin(String name) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/guest');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name}));
      if (resp.statusCode != 200) return '网络错误';
      final body = jsonDecode(resp.body);
      if (body['error'] != null) return body['error'] as String;
      if (!_parseAndSave(body)) return '解析响应失败';
      await _persist();
      return null;
    } catch (e) {
      debugPrint('AuthService guestLogin error: $e');
      return '网络连接失败';
    }
  }

  /// Xsolla 平台登录：客户端拿到 access token 后交给服务端验证+合并账号
  Future<String?> xsollaLogin(String accessToken) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/xsolla');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': accessToken}));
      if (resp.statusCode != 200) return '网络错误';
      final body = jsonDecode(resp.body);
      if (body['error'] != null) return body['error'] as String;
      if (!_parseAndSave(body)) return '解析响应失败';
      await _persist();
      return null;
    } catch (e) {
      debugPrint('AuthService xsollaLogin error: $e');
      return '网络连接失败';
    }
  }

  /// Xsolla 静默无感登录：浏览器已有 Xs 会话 → 直接取 JWT → 服务端合并
  Future<String?> trySilentXsollaLogin() async {
    if (_state != null) return null;
    if (kXsollaClientId.isEmpty || kXsollaProjectId.isEmpty) return null;
    String redirectUri = '';
    try {
      redirectUri = '${Uri.base.scheme}://${Uri.base.authority}/auth/xsolla';
    } catch (_) {}
    final jwt = await xsollaSilentJwt(
      projectId: kXsollaProjectId,
      redirectUri: redirectUri,
    );
    if (jwt == null) return null;
    debugPrint('AuthService: Xsolla 静默 JWT 获取成功，开始合并登录');
    return await xsollaLogin(jwt);
  }

  /// 登出
  Future<void> logout() async {
    _state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_playerIdKey);
    await prefs.remove(_playerNameKey);
    await prefs.remove(_avatarKey);
  }
}
