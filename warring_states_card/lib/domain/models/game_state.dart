import 'package:equatable/equatable.dart';
import 'player.dart';

/// 游戏阶段
enum GamePhase { waiting, mulligan, playing, ended }

/// 游戏状态
class GameState extends Equatable { // 回合数
  
  const GameState({
    required this.player1,
    required this.player2,
    this.turn = 1,
    this.phase = GamePhase.waiting,
    required this.activePlayerId,
    this.winnerId,
    this.turnNumber = 0,
  });
  final Player player1;
  final Player player2;
  final int turn;
  final GamePhase phase;
  final String activePlayerId; // 当前行动玩家
  final String? winnerId; // 胜利者
  final int turnNumber;
  
  /// 获取当前行动玩家
  Player get activePlayer => 
    player1.id == activePlayerId ? player1 : player2;
  
  /// 获取对手
  Player get opponent => 
    player1.id == activePlayerId ? player2 : player1;
  
  /// 游戏是否结束
  bool get isEnded => phase == GamePhase.ended;
  
  /// 获取当前玩家
  Player getCurrentPlayer(String playerId) =>
    player1.id == playerId ? player1 : player2;
  
  /// 更新玩家状态
  GameState updatePlayer(Player player) {
    if (player.id == player1.id) {
      return copyWith(player1: player);
    }
    return copyWith(player2: player);
  }
  
  GameState copyWith({
    Player? player1,
    Player? player2,
    int? turn,
    GamePhase? phase,
    String? activePlayerId,
    String? winnerId,
    int? turnNumber,
  }) {
    return GameState(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      activePlayerId: activePlayerId ?? this.activePlayerId,
      winnerId: winnerId ?? this.winnerId,
      turnNumber: turnNumber ?? this.turnNumber,
    );
  }
  
  @override
  List<Object?> get props => [player1, player2, turn, phase, activePlayerId, winnerId, turnNumber];
}