import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/hero.dart' as h;

/// 联机游戏状态
class OnlineGameState {
  final String myId;
  final String opponentId;
  final h.Hero myHero;
  final h.Hero opponentHero;

  OnlineGameState({
    required this.myId,
    required this.opponentId,
    required this.myHero,
    required this.opponentHero,
  });
}

/// 联机游戏 notifier — stub，恢复后补全
class OnlineGameNotifier extends StateNotifier<OnlineGameState?> {
  OnlineGameNotifier() : super(null);

  void startOnlineGame({
    required String myId,
    required String opponentId,
    required h.Hero myHero,
    required h.Hero opponentHero,
  }) {
    state = OnlineGameState(
      myId: myId,
      opponentId: opponentId,
      myHero: myHero,
      opponentHero: opponentHero,
    );
  }
}

final onlineGameProvider = StateNotifierProvider<OnlineGameNotifier, OnlineGameState?>(
  (ref) => OnlineGameNotifier(),
);
