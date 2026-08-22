import 'device_info_io.dart'
    if (dart.library.js_interop) 'device_info_web.dart' as info;

/// 采集真实设备型号（Web 用 Client Hints；原生返回 null 由服务端解析 UA）。
/// 返回 null 表示不可得。内部已 try-catch，不会抛出。
Future<String?> readDeviceModel() => info.deviceModel();