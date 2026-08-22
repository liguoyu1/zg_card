import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('navigator')
external JSObject get _jsNavigator;

/// Web 端设备信息采集：优先用 User-Agent Client Hints 拿真实设备型号。
/// Chrome 89+ 的移动端 UA 不再携带具体型号（仅 "Android 14 ... Mobile"），
/// 需通过 navigator.userAgentData.getHighEntropyValues(['model']) 才能拿到
/// 如 "Xiaomi 14" / "iPhone15,2" 这类真实型号。Safari/Firefox 不支持时返回空，
/// 由服务端用 UA 解析兜底。
Future<String?> deviceModel() async {
  try {
    final uaData = _jsNavigator['userAgentData'] as JSObject?;
    if (uaData == null) return null; // 无 UA-CH（Safari/Firefox 等）
    final promise = uaData.callMethodVarArgs<JSPromise<JSObject>>(
      'getHighEntropyValues'.toJS,
      <JSAny?>[<JSAny>['model'.toJS].toJS],
    );
    final values = await promise.toDart;
    final model = values['model'] as JSString?;
    return model?.toDart.trim();
  } catch (_) {
    return null;
  }
}