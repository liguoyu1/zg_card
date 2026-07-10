import 'package:go_router/go_router.dart';

import '../domain/models/hero.dart' as hero;
import '../presentation/screens/achievement_screen.dart';
import '../presentation/screens/adventure_screen.dart';
import '../presentation/screens/battle_pass_screen.dart';
import '../presentation/screens/card_library_screen.dart';
import '../presentation/screens/deck_editor_screen.dart';
import '../presentation/screens/game_screen.dart';
import '../presentation/screens/game_screen_args.dart';
import '../presentation/screens/hero_select_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/leaderboard_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/online_game_screen.dart';
import '../presentation/screens/quest_screen.dart';
import '../presentation/screens/shop_screen.dart';
import '../presentation/screens/training_screen.dart';
import '../presentation/widgets/responsive_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/battle/hero-select', builder: (_, state) => HeroSelectScreen(isPkMode: state.uri.queryParameters['mode'] == 'pk')),
          GoRoute(path: '/battle/training', builder: (_, __) => const TrainingScreen()),
          GoRoute(path: '/collection', builder: (_, __) => const CardLibraryScreen()),
          GoRoute(path: '/collection/deck-editor', builder: (_, __) => const DeckEditorScreen()),
          GoRoute(path: '/progress/achievement', builder: (_, __) => const AchievementScreen()),
          GoRoute(path: '/progress/quest', builder: (_, __) => const QuestScreen()),
          GoRoute(path: '/progress/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/progress/battle-pass', builder: (_, __) => const BattlePassScreen()),
          GoRoute(path: '/shop/adventure', builder: (_, __) => const AdventureScreen()),
          GoRoute(path: '/shop/shop', builder: (_, __) => const ShopScreen()),
        ],
      ),
      // 对战页面在 ShellRoute 外，不显示底部导航栏
      GoRoute(
        path: '/battle/game',
        builder: (_, state) {
          final args = state.extra as GameScreenArgs;
          return GameScreen(
            playerId: args.playerId,
            playerHero: args.playerHero,
            difficulty: args.difficulty,
            missionContext: args.missionContext,
            runHp: args.runHp,
            opponentHero: args.opponentHero,
          );
        },
      ),
      GoRoute(
        path: '/battle/online-match',
        builder: (_, state) {
          final selectedHero = state.extra as hero.Hero;
          return MatchmakingScreen(selectedHero: selectedHero);
        },
      ),
      GoRoute(
        path: '/battle/online-game',
        builder: (_, state) {
          final args = state.extra as GameScreenArgs;
          return GameScreen(
            playerId: args.playerId,
            playerHero: args.playerHero,
            isOnline: args.isOnline,
          );
        },
      ),
      // 登录页面 — 全屏无底部导航
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    ],
  );
}