import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 登录状态
class AuthState {
  final String token;
  final String playerId;
  final String playerName;
  final String? avatar;

  const AuthState({
    required this.token,
    required this.playerId,
    required this.playerName,
    this.avatar,
  });
}

/// 认证服务 — 邮箱密码登录/注册 + 游客登录 + 持久化
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _playerIdKey = 'auth_player_id';
  static const String _playerNameKey = 'auth_player_name';
  static const String _avatarKey = 'auth_avatar';
  static const String _emailKey = 'auth_email';
  static const String _baseUrl =
      'https://app-server-production-39d1.up.railway.app';

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
    if (_state!.avatar != null) {
      await prefs.setString(_avatarKey, _state!.avatar!);
    }
  }

  /// 邮箱注册
  Future<String?> register(String email, String password, String name) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/register');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'name': name}));
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
