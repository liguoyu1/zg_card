import 'package:shared_preferences/shared_preferences.dart';

/// 原生（iOS/Android）端设备ID存储：SharedPreferences 持久化。
Future<String?> readStoredDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getString('dev_id');
  return (v == null || v.length < 16) ? null : v;
}

Future<void> writeStoredDeviceId(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('dev_id', id);
}
