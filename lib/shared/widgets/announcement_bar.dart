import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/activity_service.dart';
import '../../l10n/locale_service.dart';
import 'ad_slot_scope.dart';

/// 主页底部系统公告：服务器配置（多条按序循环滚动，无则不显示）
/// 每次切回主页 tab 或切换语言时重新拉取，获取对应语言/生效周期内的公告。
class AnnouncementBar extends StatefulWidget {
  const AnnouncementBar({super.key});

  @override
  State<AnnouncementBar> createState() => _AnnouncementBarState();
}

class _AnnouncementBarState extends State<AnnouncementBar> {
  List<Announcement> _items = const [];
  bool _loaded = false;
  int _idx = 0;
  Timer? _timer;
  int? _lastActiveIndex;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _lastActiveIndex = _readActiveIndex();
    _lastLocale = LocaleService.I.localeCode;
    _load();
    // 语言切换后重新拉取对应语言公告
    LocaleService.I.localeVersion.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleService.I.localeVersion.removeListener(_onLocaleChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    final code = LocaleService.I.localeCode;
    if (code != _lastLocale) {
      _lastLocale = code;
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 主页 tab 变为激活时刷新（公告生效周期可能变化）；首次由 initState 拉取
    final idx = _readActiveIndex();
    if (_loaded && idx == 0 && _lastActiveIndex != 0) _load();
    _lastActiveIndex = idx;
  }

  /// 当前所在 tab（AdSlotScope 注入）；主页为 0
  int? _readActiveIndex() {
    final scope = context.dependOnInheritedWidgetOfExactType<AdSlotScope>();
    return scope?.activeIndex;
  }

  Future<void> _load() async {
    // 公告语言映射：zh/zh_TW 用中文公告，其余语言用英文公告（英文为兜底语言）
    final code = LocaleService.I.localeCode;
    final locale = (code == 'zh' || code == 'zh_TW') ? 'zh' : 'en';
    final items =
        await ActivityService.I.fetchAnnouncements(locale);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loaded = true;
      _idx = 0;
    });
    if (items.length > 1) {
      _timer?.cancel();
      // 多条公告每 4 秒循环推进展示
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _idx = (_idx + 1) % _items.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _items.isEmpty) return const SizedBox.shrink();
    final item = _items[_idx % _items.length];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withAlpha(14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.goldAccent.withAlpha(70)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0.5, 0), end: Offset.zero)
              .animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Row(
          key: ValueKey(item.id),
          children: [
            Icon(Icons.campaign_outlined,
                color: AppTheme.goldAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.title.isNotEmpty ? "${item.title}：" : ""}${item.content}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}