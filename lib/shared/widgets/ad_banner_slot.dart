// 卡牌页内嵌横幅插槽 —— 条件导入：Web 渲染真实 Adsterra 横幅，原生端为空占位。
export 'ad_banner_slot_native.dart'
    if (dart.library.js_interop) 'ad_banner_slot_web.dart';
