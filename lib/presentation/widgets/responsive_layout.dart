import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/achievement_screen.dart';
import '../screens/card_library_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';

/// 响应式外壳 — 4 Tab：主页/卡牌/进度/商店
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key, required this.child});
  final Widget child;
  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  static const _tabPaths = ['/', '/collection', '/progress/achievement', '/shop/shop'];
  static const _tabLabels = ['主页', '卡牌', '进度', '商店'];
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
    final path = GoRouterState.of(context).uri.path;
    if (_isSubRoute(path)) return widget.child;

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
          leading: const Padding(padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('戰', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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