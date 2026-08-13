import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 轻量 i18n 服务 — 字符串 Map 方案
/// 加载 assets/l10n/{locale}.json 并通过 t() 方法提供键值查找
class LocaleService {
  LocaleService._();
  static final LocaleService I = LocaleService._();

  String _localeCode = 'en';
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _enData;

  /// 语言变更通知（重建整个 Widget 树）
  final ValueNotifier<int> localeVersion = ValueNotifier(0);

  /// 当前使用的 locale code
  String get localeCode => _localeCode;

  /// 是否已初始化
  bool get isInitialized => _data != null;

  /// 初始化：加载指定语言的 JSON；缺失 key 一律回退英文（en）
  Future<void> init({String localeCode = 'en'}) async {
    _localeCode = localeCode;
    try {
      _enData ??= json.decode(
              await rootBundle.loadString('assets/l10n/en.json'))
          as Map<String, dynamic>;
    } catch (_) {}
    try {
      final jsonStr =
          await rootBundle.loadString('assets/l10n/$localeCode.json');
      _data = json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('LocaleService: 加载 $localeCode.json 失败 ($e)，回退 en');
      _data = _enData ?? {};
    }
    // 数据加载完成后通知 UI 刷新
    localeVersion.value++;
  }

  /// 通过 key 获取字符串，支持 {param} 插值
  /// 优先查找 exact key，再按父级 key 降级查找
  /// e.g. t('adventure.title') → _data['adventure']['title']
  String t(String key, {Map<String, String>? args}) {
    if (_data == null) return '⚠$key';

    // 尝试点号路径
    final parts = key.split('.');
    dynamic current = _data!;
    for (final p in parts) {
      if (current is Map<String, dynamic>) {
        current = current[p];
      } else {
        current = null;
        break;
      }
    }

    String result;
    if (current is String) {
      result = current;
    } else if (current == null) {
      // 尝试扁平 key；缺失回退英文（en），再缺失才显示 key
      result = _data![key] as String? ??
          _enData?[key] as String? ??
          '⚠$key';
    } else {
      result = _enData?[key] as String? ?? '⚠$key';
    }

    // 插值替换
    if (args != null && result.isNotEmpty && !result.startsWith('⚠')) {
      for (final e in args.entries) {
        final ph = '{${e.key}}';
        final v = e.value;
        final sb = StringBuffer();
        int i = 0;
        while (i < result.length) {
          if (i + ph.length <= result.length &&
              result.substring(i, i + ph.length) == ph) {
            sb.write(v);
            i += ph.length;
          } else {
            sb.write(result[i]);
            i++;
          }
        }
        result = sb.toString();
      }
    }

    return result;
  }
}
