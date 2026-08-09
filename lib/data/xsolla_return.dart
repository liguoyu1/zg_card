import 'xsolla_return_stub.dart'
    if (dart.library.js_interop) 'xsolla_return_web.dart' as impl;

/// 读取支付返回状态（仅 Web 有效；支付成功/取消等由 Xsolla 拼在 return_url 上）
String? consumeXsollaReturnStatus() => impl.consumeXsollaReturnStatus();
