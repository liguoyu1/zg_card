import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'device_id_store.dart';

/// 设备信息上报（匿名设备ID, 屏幕, 语言, 时区）
/// 服务端从请求头读 User-Agent 解析设备类型/型号。
/// 启动时 fire-and-forget，不影响主流程。
class DeviceReportService {
  DeviceReportService._();
  static final DeviceReportService I = DeviceReportService._();

  static const String _baseUrl = ApiConfig.baseUrl;

  static String _uuid() {
    final rnd = Random.secure();
    final hex = List.generate(32, (_) => rnd.nextInt(16).toRadixString(16)).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// 上报（可多次调用。登录后带 playerId/playerName 补报，服务端更新同 deviceId 记录）
  static Future<void> report({String? playerId, String? playerName, bool? isGuest}) async {
    try {
      String? deviceId = await readStoredDeviceId();
      if (deviceId == null) { deviceId = _uuid(); await writeStoredDeviceId(deviceId); }

      final dipl = PlatformDispatcher.instance;
      final view = dipl.views.first;
      final dpr = view.devicePixelRatio;
      final w = (view.physicalSize.width / dpr).round();
      final h = (view.physicalSize.height / dpr).round();

      final body = {
        'deviceId': deviceId,
        'playerId': playerId ?? '',
        'playerName': playerName ?? '',
        'isGuest': isGuest ?? (playerId == null || playerId.isEmpty),
        'screen': '${w}x$h',
        'lang': dipl.locale.toLanguageTag(),
        'tz': DateTime.now().timeZoneName,
      };

      await http.post(
        Uri.parse('$_baseUrl/api/device-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {}
  }
}