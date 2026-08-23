import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/locale_service.dart';
import '../../data/card_image_service.dart';
import '../../shared/widgets/ad_slot_scope.dart';
import '../../shared/widgets/queued_asset_image.dart';
import '../screens/achievement_screen.dart';
import '../screens/card_library_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';

/// 响应式外壳 — 4 Tab：主页/卡牌/进度/商店
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
    if (i == 1) _fillCardLibrary();
    GoRouter.of(context).go(_tabPaths[i]);
  }

  /// 卡牌页补齐：把尚未加载的卡牌按展示顺序全部加入全局预加载队列，
  /// 由后台 3 并发继续并行加载，直到全部加载完（不依赖下滑才触发）。
  void _fillCardLibrary() {
    for (final p in CardImageService.getAllCardPathsByDisplayOrder()) {
      AssetPreloadQueue.I.ensure(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ShellRoute 的 state.uri.path 才是当前子路由；GoRouterState.of(context)
    // 会因 IndexedStack 内各子屏 context 而上报根路径(/)。
    final path = widget.initialPath;
    if (_isSubRoute(path)) {
      return AdSlotScope(
        isSubRoute: true,
        activeIndex: _currentIndex,
        canShow: !_isBattlePath(path),
        child: widget.child,
      );
    }

    _currentIndex = _indexForPath(path);
    if (path.startsWith('/collection')) _fillCardLibrary();
    final width = MediaQuery.sizeOf(context).width;

    // 每个 Tab 注入自己的 AdSlotScope（仅影响广告何时加载，不改布局）。
    final screens = <Widget>[
      AdSlotScope(isSubRoute: false, activeIndex: _currentIndex, tabIndex: 0, canShow: true, child: const HomeScreen()),
      AdSlotScope(isSubRoute: false, activeIndex: _currentIndex, tabIndex: 1, canShow: true, child: const CardLibraryScreen()),
      AdSlotScope(isSubRoute: false, activeIndex: _currentIndex, tabIndex: 2, canShow: true, child: const AchievementScreen()),
      AdSlotScope(isSubRoute: false, activeIndex: _currentIndex, tabIndex: 3, canShow: true, child: const ShopScreen()),
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
    return body;
  }
}