import 'dart:math';

import 'device_id_store_io.dart'
    if (dart.library.js_interop) 'device_id_store_web.dart' as store;

/// 设备ID读取（Web:cookie / 原生:SharedPreferences）。
/// 返回 null 表示尚无持久设备ID，需调用方生成。
Future<String?> readStoredDeviceId() => store.readStoredDeviceId();

/// 设备ID写入。
Future<void> writeStoredDeviceId(String id) => store.writeStoredDeviceId(id);

/// 确保存在持久设备ID：已存则返回，否则生成并写入。
Future<String> ensureDeviceId() async {
  final existing = await readStoredDeviceId();
  if (existing != null && existing.length >= 16) return existing;
  final rnd = Random.secure();
  final hex = List.generate(32, (_) => rnd.nextInt(16).toRadixString(16)).join();
  final id = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  await writeStoredDeviceId(id);
  return id;
}
