import 'device_id_store_io.dart'
    if (dart.library.js_interop) 'device_id_store_web.dart' as store;

/// 设备ID读取（Web:cookie / 原生:SharedPreferences）。
/// 返回 null 表示尚无持久设备ID，需调用方生成。
Future<String?> readStoredDeviceId() => store.readStoredDeviceId();

/// 设备ID写入。
Future<void> writeStoredDeviceId(String id) => store.writeStoredDeviceId(id);
