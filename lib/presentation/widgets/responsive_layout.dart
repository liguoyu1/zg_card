import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/locale_service.dart';
import '../../shared/widgets/ad_banner_slot.dart';
import '../screens/achievement_screen.dart';
import '../screens/card_library_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';

/// 响应式外壳 — 4 Tab：主页/卡牌/进度/商店
///
/// 广告横幅的唯一挂载点：IndexedStack 会同时挂载全部 4 个 Tab，
/// 若各 Tab 内各自内嵌 AdBannerSlot，同一 Adsterra zone 会并发加载多份，
/// 互相抢占导致除首页外全部加载失败。因此把横幅收敛到外壳层，全局仅此一份，
/// 跨页面导航常驻不重建，加载一次后所有页面稳定显示。
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key, required this.child, this.initialPath = '/'});
  final Widget child;
  final String initialPath;
  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  static const _tabPaths = ['/', '/collection', '/progress/achievement', '/shop/shop'];
  List<String> get _tabLabels => [
    LocaleService.I.t('home.title'),
    LocaleService.I.t('card_library.title'),
    LocaleService.I.t('achievement.title'),
    LocaleService.I.t('shop.title_bar'),
  ];
  static const _tabIcons = [
    Icons.home_outlined, Icons.collections_bookmark_outlined,
    Icons.emoji_events_outlined, Icons.shopping_bag_outlined,
  ];
  static const _tabIconsActive = [
    Icons.home, Icons.collections_bookmark,
    Icons.emoji_events, Icons.shopping_bag,
  ];

  int _currentIndex = 0;

  bool _isSubRoute(String path) =>
      path != '/' && !_tabPaths.any((t) => path == t);

  /// 对局相关页面不展示广告横幅，避免干扰战斗。
  bool _isBattlePath(String path) => path.startsWith('/battle');

  int _indexForPath(String path) {
    if (path.startsWith('/collection')) return 1;
    if (path.startsWith('/progress')) return 2;
    if (path.startsWith('/shop')) return 3;
    return 0;
  }

  void _onNav(int i) {
    setState(() => _currentIndex = i);
    GoRouter.of(context).go(_tabPaths[i]);
  }

  @override
  Widget build(BuildContext context) {
    // ShellRoute 的 state.uri.path 才是当前子路由；GoRouterState.of(context)
    // 会因 IndexedStack 内各子屏 context 而上报根路径(/)。
    final path = widget.initialPath;
    if (_isSubRoute(path)) {
      // 子路由：页面本身 + 全局唯一横幅（对局除外）
      if (_isBattlePath(path)) return widget.child;
      return Column(children: [
        Expanded(child: widget.child),
        const AdBannerSlot(),
      ]);
    }

    _currentIndex = _indexForPath(path);
    final width = MediaQuery.sizeOf(context).width;

    final screens = <Widget>[
      const HomeScreen(),
      const CardLibraryScreen(),
      const AchievementScreen(),
      const ShopScreen(),
    ];

    Widget body;
    if (width >= 840) {
      body = Row(children: [
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNav,
          labelType: NavigationRailLabelType.all,
          destinations: List.generate(4, (i) => NavigationRailDestination(
            icon: Icon(_tabIcons[i]), selectedIcon: Icon(_tabIconsActive[i]), label: Text(_tabLabels[i]),
          )),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: IndexedStack(index: _currentIndex, children: screens),
        )),
      ]);
    } else {
      body = Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNav,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.amber.shade300,
          unselectedItemColor: Colors.grey,
          backgroundColor: const Color(0xFF1A1A2E),
          items: List.generate(4, (i) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[i]), activeIcon: Icon(_tabIconsActive[i]), label: _tabLabels[i],
          )),
        ),
      );
    }
    return Column(children: [
      Expanded(child: body),
      const AdBannerSlot(),
    ]);
  }
}